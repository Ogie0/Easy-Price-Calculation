"""Zeichnet die Artikelbilder (assets/articles) als SVG und rendert sie mit
Chromium zu PNG (längste Seite 384 px, transparent, auf den Inhalt
zugeschnitten). Halbrealistischer Stil: Verläufe, Licht, Schatten und
Oberflächenstruktur statt Konturen.

Aufruf: python3 tool/article_art/draw.py <ausgabeordner> [chromium] [name ...]
Ohne Namen werden alle Bilder gezeichnet. Danach die PNGs nach
assets/articles kopieren (pfand -> pfandrueckgabe, frei -> freier_betrag).
"""
import os
import random
import subprocess
import sys

OUT = sys.argv[1]
CHROME = sys.argv[2] if len(sys.argv) > 2 else (
    '/opt/pw-browsers/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell')
ONLY = set(sys.argv[3:])

# Gemeinsame Filter: weicher Schatten, Körnung (Brot, Fleisch, Panade),
# unregelmäßiger Rand (Panade) und weiche Glanzlichter.
COMMON = '''
<filter id="blur8" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter>
<filter id="blur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3"/></filter>
<filter id="blur1" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.2"/></filter>
<filter id="grain" x="0" y="0" width="100%" height="100%">
  <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="4" result="n"/>
  <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.25  0 0 0 0 0.12  0 0 0 0 0.03  1.1 0 0 0 -0.55" result="d"/>
  <feComposite in="d" in2="SourceAlpha" operator="in" result="d2"/>
  <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="d2"/></feMerge>
</filter>
<filter id="grainFine" x="0" y="0" width="100%" height="100%">
  <feTurbulence type="fractalNoise" baseFrequency="2.2" numOctaves="1" seed="9" result="n"/>
  <feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0.9 0 0 0 -0.5" result="d"/>
  <feComposite in="d" in2="SourceAlpha" operator="in" result="d2"/>
  <feMerge><feMergeNode in="SourceGraphic"/><feMergeNode in="d2"/></feMerge>
</filter>
<filter id="crumb" x="-10%" y="-10%" width="120%" height="120%">
  <feTurbulence type="fractalNoise" baseFrequency="0.06" numOctaves="2" seed="2" result="t"/>
  <feDisplacementMap in="SourceGraphic" in2="t" scale="16" xChannelSelector="R" yChannelSelector="G" result="r"/>
  <feTurbulence type="fractalNoise" baseFrequency="0.7" numOctaves="2" seed="5" result="n"/>
  <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.22  0 0 0 0 0.02  1.4 0 0 0 -0.6" result="d"/>
  <feComposite in="d" in2="r" operator="in" result="d2"/>
  <feMerge><feMergeNode in="r"/><feMergeNode in="d2"/></feMerge>
</filter>
'''


def svg(body, defs='', shadow=(256, 452, 170, 18)):
    cx, cy, rx, ry = shadow
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<defs>{COMMON}{defs}</defs>
<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#000" opacity=".28" filter="url(#blur8)"/>
{body}
</svg>'''


def shine(d, w=8, op=.7, blur='blur3'):
    """Weiches Glanzlicht."""
    return f'<path d="{d}" fill="none" stroke="#fff" stroke-width="{w}" stroke-linecap="round" opacity="{op}" filter="url(#{blur})"/>'


def glass_body(d, gid):
    """Klarglas: leicht getönt, Ränder dunkler."""
    return f'<path d="{d}" fill="url(#{gid})"/>'


GLASS = '''
<linearGradient id="glass" x1="0" x2="1">
  <stop offset="0" stop-color="#9fb8c0" stop-opacity=".6"/>
  <stop offset=".08" stop-color="#ffffff" stop-opacity=".25"/>
  <stop offset=".3" stop-color="#ffffff" stop-opacity=".04"/>
  <stop offset=".75" stop-color="#ffffff" stop-opacity=".04"/>
  <stop offset=".92" stop-color="#ffffff" stop-opacity=".2"/>
  <stop offset="1" stop-color="#8aa6b0" stop-opacity=".65"/>
</linearGradient>
<linearGradient id="glassEdge" x1="0" x2="1">
  <stop offset="0" stop-color="#7d97a0"/><stop offset=".5" stop-color="#cfe0e5"/><stop offset="1" stop-color="#7d97a0"/>
</linearGradient>
<radialGradient id="ice" cx=".35" cy=".3" r=".9">
  <stop offset="0" stop-color="#ffffff" stop-opacity=".95"/><stop offset=".6" stop-color="#e3f1f6" stop-opacity=".7"/>
  <stop offset="1" stop-color="#a9c6d0" stop-opacity=".75"/>
</radialGradient>
'''


def ice(x, y, s, r):
    return (f'<g transform="rotate({r} {x + s / 2} {y + s / 2})">'
            f'<rect x="{x}" y="{y}" width="{s}" height="{s}" rx="{s * .2}" fill="url(#ice)"/>'
            f'<path d="M{x + s * .2} {y + s * .25} L{x + s * .55} {y + s * .2}" stroke="#fff" stroke-width="4" '
            f'stroke-linecap="round" opacity=".9" filter="url(#blur1)"/></g>')


def drops(points):
    """Kondenstropfen."""
    out = []
    for x, y, r in points:
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{r * 1.25}" fill="#ffffff" opacity=".35"/>'
                   f'<ellipse cx="{x - r * .3}" cy="{y - r * .4}" rx="{r * .35}" ry="{r * .4}" fill="#fff" opacity=".9"/>')
    return ''.join(out)


def bubbles(points, color='#fff7d6', op=.8):
    return ''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}" opacity="{op}"/>' for x, y, r in points)


ART = {}

# ---------------------------------------------------------------- Speisen

ART['bratwurst'] = svg('''
<g filter="url(#grain)">
  <path d="M70 262 Q256 160 442 262 L440 300 L72 300 Z" fill="url(#bunBack)"/>
</g>
<rect x="44" y="232" width="424" height="84" rx="42" fill="url(#wurst)"/>
<g stroke="#4a1a08" stroke-width="10" stroke-linecap="round" opacity=".55" filter="url(#blur3)">
  <path d="M118 250 l26 46 M188 248 l26 48 M258 248 l26 48 M328 248 l26 48 M392 250 l22 40"/>
</g>
''' + shine('M88 254 Q256 242 424 254', 9, .55) + '''
<path d="M78 268 q20 -22 40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0" fill="none"
  stroke="#9b7400" stroke-width="15" stroke-linecap="round" opacity=".45" filter="url(#blur1)" transform="translate(0 3)"/>
<path d="M78 268 q20 -22 40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0" fill="none"
  stroke="url(#senf)" stroke-width="12" stroke-linecap="round"/>
<g filter="url(#grain)">
  <path d="M60 298 Q256 410 452 298 Q464 340 432 362 Q256 452 80 362 Q48 340 60 298 Z" fill="url(#bunFront)"/>
</g>
''' + shine('M104 350 Q256 412 408 350', 10, .3, 'blur8'), defs='''
<linearGradient id="wurst" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#7a2c12"/><stop offset=".3" stop-color="#b85a2c"/><stop offset=".55" stop-color="#a24a22"/>
  <stop offset="1" stop-color="#5b1f0c"/>
</linearGradient>
<linearGradient id="bunBack" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b8692a"/><stop offset="1" stop-color="#e9b16c"/></linearGradient>
<linearGradient id="bunFront" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#f6d9a6"/><stop offset=".35" stop-color="#e9a95a"/><stop offset=".8" stop-color="#c7782f"/><stop offset="1" stop-color="#9c5520"/>
</linearGradient>
<linearGradient id="senf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe45a"/><stop offset="1" stop-color="#e2b400"/></linearGradient>
''')

def _curry_slice(x, y):
    """Wurstscheibe von schräg oben: Haut als Rand, gebräunte Schnittfläche."""
    return (f'<ellipse cx="{x}" cy="{y + 10}" rx="38" ry="21" fill="#4e1d0b"/>'
            f'<ellipse cx="{x}" cy="{y + 5}" rx="38" ry="21" fill="url(#cwSkin)"/>'
            f'<ellipse cx="{x}" cy="{y}" rx="34" ry="18" fill="url(#cwCut)"/>')


def _curry_rows():
    """Scheiben in versetzten Reihen, passend in die Schale (hinten schmaler),
    leicht unregelmäßig."""
    rnd = random.Random(3)
    rows = []
    for i, y in enumerate((204, 238, 272)):
        half = 142 + (y - 170) * 68 / 130 - 42    # halbe Innenbreite minus Rand
        n = int(2 * half // 70) + 1
        x0 = 256 - (n - 1) * 35 + (10 if i % 2 else -10)
        rows.append([(round(x0 + k * 70 + rnd.uniform(-5, 5)), round(y + rnd.uniform(-3, 3))) for k in range(n)])
    return rows


def _curry_sauce_cap(i, x, y):
    rnd = random.Random(100 + i)
    dx, dy = rnd.uniform(-5, 5), rnd.uniform(-10, -5)
    rx, ry = rnd.uniform(23, 31), rnd.uniform(10, 13)
    return (f'<ellipse cx="{x + dx:.1f}" cy="{y + dy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="url(#cwSauce)"/>'
            f'<ellipse cx="{x + dx + 8:.1f}" cy="{y + dy + ry - 1:.1f}" rx="5" ry="4" fill="#b8221a"/>'
            + shine(f'M{x + dx - rx * .55:.1f} {y + dy - ry * .35:.1f} Q{x + dx:.1f} {y + dy - ry * .8:.1f} '
                    f'{x + dx + rx * .4:.1f} {y + dy - ry * .5:.1f}', 3, .55, 'blur1'))


def _curry_powder():
    rnd = random.Random(7)
    dots = []
    for _ in range(170):
        x = rnd.uniform(124, 392)
        y = rnd.uniform(194, 286)
        r = rnd.uniform(1.4, 3.0)
        c = rnd.choice(['#e3a126', '#d98418', '#c9661a', '#f0bd3c', '#b8561a'])
        dots.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{c}"/>')
    haze = ''.join(f'<ellipse cx="{rnd.uniform(140, 370):.0f}" cy="{rnd.uniform(200, 280):.0f}" rx="26" ry="10" '
                   f'fill="#e39a2a" opacity=".22"/>' for _ in range(10))
    return f'<g filter="url(#blur3)">{haze}</g><g opacity=".95">' + ''.join(dots) + '</g>'


_CW_ROWS = _curry_rows()
_CW_SLICES = [p for row in _CW_ROWS for p in row]

ART['currywurst'] = svg(
    # Schale: Rand und Innenraum (hinten).
    '''
<path d="M126 170 L386 170 Q400 170 406 182 L466 292 Q472 304 458 304 L54 304 Q40 304 46 292 L106 182 Q112 170 126 170 Z" fill="#d9d4c7"/>
<path d="M130 178 L382 178 L446 296 L66 296 Z" fill="url(#cwInnen)"/>
<path d="M142 190 C200 182 320 182 372 190 C400 200 428 250 436 292 L76 292 C84 250 112 200 142 190 Z" fill="url(#cwBett)"/>
'''
    # Wurstscheiben, von hinten nach vorn.
    + ''.join(_curry_slice(x, y) for x, y in _CW_SLICES)
    # Pommesgabel aus rotem Kunststoff, steckt in einer Scheibe.
    + '''
<g>
  <path d="M330 234 L384 112" stroke="url(#cwGabel)" stroke-width="14" stroke-linecap="round"/>
  <path d="M384 112 L390 98" stroke="#b8160f" stroke-width="19" stroke-linecap="round"/>
  <path d="M334 224 L380 118" stroke="#fff" stroke-width="3.5" opacity=".55" filter="url(#blur1)"/>
</g>
'''
    # Curryketchup: liegt in den Zwischenräumen und überzieht jede Scheibe
    # zum Teil; vorn bleibt ein Rand der Schnittfläche frei.
    + ''.join(_curry_sauce_cap(i, x, y) for i, (x, y) in enumerate(_CW_SLICES))
    + _curry_powder()
    # Vorderwand der Schale verdeckt den unteren Rand der vorderen Scheiben.
    + '''
<path d="M46 292 Q40 304 54 304 L458 304 Q472 304 466 292 L474 300 L444 372 Q440 380 430 380 L82 380 Q72 380 68 372 L38 300 Z" fill="url(#cwWand)"/>
<path d="M40 300 L472 300" stroke="#f7f5ef" stroke-width="7" stroke-linecap="round"/>
<path d="M54 326 L458 326" stroke="#c8352a" stroke-width="10"/>
<path d="M60 340 L452 340" stroke="#c8352a" stroke-width="3"/>
''' + shine('M64 314 L88 372', 12, .35, 'blur8'), shadow=(256, 394, 196, 14), defs='''
<linearGradient id="cwInnen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#bdb7a8"/><stop offset="1" stop-color="#e6e2d8"/></linearGradient>
<linearGradient id="cwWand" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset=".6" stop-color="#f1efe8"/><stop offset="1" stop-color="#d6d2c6"/></linearGradient>
<radialGradient id="cwSkin" cx=".5" cy=".35" r=".8"><stop offset="0" stop-color="#a5532a"/><stop offset="1" stop-color="#5e230d"/></radialGradient>
<radialGradient id="cwCut" cx=".45" cy=".4" r=".75"><stop offset="0" stop-color="#d4946a"/><stop offset=".7" stop-color="#b66e44"/><stop offset="1" stop-color="#8a4424"/></radialGradient>
<linearGradient id="cwBett" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8e150d"/><stop offset="1" stop-color="#b01f15"/></linearGradient>
<radialGradient id="cwSauce" cx=".45" cy=".4" r=".7"><stop offset="0" stop-color="#d63c26"/><stop offset=".7" stop-color="#b8221a"/><stop offset="1" stop-color="#a01b12"/></radialGradient>
<linearGradient id="cwGabel" x1="0" x2="1"><stop offset="0" stop-color="#f0463a"/><stop offset="1" stop-color="#a8140e"/></linearGradient>
''')

ART['krakauer'] = svg('''
<g filter="url(#grain)">
  <path d="M60 300 C90 170 340 130 456 220 L432 292 C340 222 160 238 140 332 Z" fill="url(#kraka)"/>
</g>
<g fill="#f2c9b8" opacity=".75" filter="url(#blur1)">
  <circle cx="120" cy="268" r="5"/><circle cx="160" cy="236" r="4"/><circle cx="214" cy="214" r="5"/><circle cx="270" cy="204" r="4"/>
  <circle cx="326" cy="206" r="5"/><circle cx="380" cy="222" r="4"/><circle cx="420" cy="246" r="4"/><circle cx="104" cy="306" r="4"/>
  <circle cx="190" cy="246" r="3"/><circle cx="300" cy="228" r="3"/><circle cx="360" cy="246" r="3"/><circle cx="240" cy="226" r="3"/>
</g>
''' + shine('M96 258 C150 192 300 166 410 202', 10, .45) + '''
<ellipse cx="100" cy="316" rx="38" ry="42" fill="#7a2a16" transform="rotate(18 100 316)"/>
<ellipse cx="102" cy="314" rx="31" ry="35" fill="url(#marbled)" transform="rotate(18 100 316)"/>
''' + ''.join(f'''
<ellipse cx="{x}" cy="{y + 6}" rx="58" ry="40" fill="#6e2512"/>
<ellipse cx="{x}" cy="{y}" rx="58" ry="40" fill="url(#kraka)"/>
<ellipse cx="{x + 4}" cy="{y - 3}" rx="47" ry="31" fill="url(#marbled)"/>
<g fill="#fbe6dc" opacity=".9" filter="url(#blur1)">
  <circle cx="{x - 14}" cy="{y - 10}" r="7"/><circle cx="{x + 16}" cy="{y + 6}" r="6"/><circle cx="{x + 10}" cy="{y - 16}" r="4"/>
  <circle cx="{x - 16}" cy="{y + 10}" r="4"/><circle cx="{x + 26}" cy="{y - 6}" r="3"/></g>''' for x, y in [(250, 378), (382, 384)]),
    defs='''
<linearGradient id="kraka" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b8462e"/><stop offset=".5" stop-color="#8e2f1c"/><stop offset="1" stop-color="#5a1a0c"/></linearGradient>
<radialGradient id="marbled" cx=".45" cy=".4" r=".75"><stop offset="0" stop-color="#e79a8c"/><stop offset=".7" stop-color="#c76a5c"/><stop offset="1" stop-color="#a24c3f"/></radialGradient>
''')

STEAK_TOP = ('M92 246 C88 194 146 156 222 154 C290 152 322 172 360 172 C410 172 440 204 432 248 '
             'C424 292 378 312 312 316 C252 320 220 334 166 328 C114 322 96 292 92 246 Z')
# Fleisch: wie STEAK_TOP, nur die Oberkante tiefer, sodass oben ein Fettrand
# bleibt.
STEAK_MEAT = ('M96 250 C94 202 148 168 222 166 C289 164 321 183 359 183 C405 183 430 210 430 248 '
              'C424 292 378 312 312 316 C252 320 220 334 166 328 C114 322 98 292 98 252 Z')

ART['steak'] = svg('''
<path d="M78 252 L438 252 Q452 252 456 264 L494 378 Q498 392 484 392 L28 392 Q14 392 18 378 L58 264 Q62 252 78 252 Z" fill="url(#stBrett)" filter="url(#grain)"/>
<path d="M18 380 L494 380 L494 396 Q494 414 476 414 L36 414 Q18 414 18 396 Z" fill="url(#stKante)"/>
<g stroke="#8a5a2c" stroke-width="3" opacity=".3" fill="none">
  <path d="M70 280 Q256 272 444 282 M56 318 Q256 308 458 320 M42 356 Q256 346 472 358"/>
</g>
<g transform="translate(-31 -18) scale(1.12)">
<path d="''' + STEAK_TOP + '''" fill="#2a0f06" opacity=".55" filter="url(#blur8)" transform="translate(8 30)"/>
<path d="''' + STEAK_TOP + '''" fill="url(#stSeite)" transform="translate(0 20)"/>
<path d="''' + STEAK_TOP + '''" fill="url(#stFett)"/>
<g filter="url(#grain)"><path d="''' + STEAK_MEAT + '''" fill="url(#stFleisch)"/></g>
<clipPath id="stClip"><path d="''' + STEAK_TOP + '''"/></clipPath>
<g clip-path="url(#stClip)" stroke="#220a03" stroke-width="12" stroke-linecap="round" opacity=".8" filter="url(#blur3)">
  <path d="M110 218 L230 338 M170 182 L300 312 M240 172 L372 304 M316 176 L430 290"/>
  <path d="M116 306 L230 192 M196 322 L326 192 M282 318 L404 196"/>
</g>
''' + shine('M150 218 C200 196 270 192 330 202', 9, .3, 'blur8') + shine('M356 216 C384 216 404 230 410 246', 6, .35, 'blur3') + shine('M124 192 C160 168 210 160 250 160', 4, .45, 'blur1') + '''
<g fill="#160602" opacity=".7"><circle cx="168" cy="248" r="2.6"/><circle cx="214" cy="286" r="2.2"/><circle cx="262" cy="218" r="2.4"/>
  <circle cx="318" cy="270" r="2.6"/><circle cx="366" cy="240" r="2.2"/><circle cx="140" cy="280" r="2"/><circle cx="290" cy="298" r="2"/></g>
<g fill="#fbf7ee" opacity=".9"><rect x="196" y="234" width="4" height="4" transform="rotate(20 198 236)"/><rect x="250" y="266" width="4" height="4"/>
  <rect x="338" y="220" width="4" height="4" transform="rotate(40 340 222)"/><rect x="154" y="300" width="3.5" height="3.5"/></g>
<g>
  <path d="M250 190 C288 164 334 160 372 174" fill="none" stroke="#4a5d2a" stroke-width="5" stroke-linecap="round"/>
''' + ''.join(f'<ellipse cx="{252 + i * 11.5}" cy="{188 - i * 2.2 + (6 if i % 2 else -6)}" rx="11" ry="2.8" fill="#3f6b2e" '
              f'transform="rotate({-40 if i % 2 else 30} {252 + i * 11.5} {188 - i * 2.2})"/>' for i in range(11)) + '''
</g>
</g>
''', shadow=(256, 418, 236, 14), defs='''
<linearGradient id="stBrett" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#cf9b5c"/><stop offset="1" stop-color="#e0b274"/></linearGradient>
<linearGradient id="stKante" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#a86f36"/><stop offset="1" stop-color="#7a4a20"/></linearGradient>
<linearGradient id="stSeite" x1="0" y1="0" x2="0" y2="1"><stop offset=".6" stop-color="#5a240e"/><stop offset="1" stop-color="#2e1006"/></linearGradient>
<linearGradient id="stFett" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e9c48a"/><stop offset=".18" stop-color="#c9924e"/><stop offset=".4" stop-color="#8a5220"/></linearGradient>
<radialGradient id="stFleisch" cx=".45" cy=".4" r=".75"><stop offset="0" stop-color="#9c5226"/><stop offset=".55" stop-color="#7a3818"/><stop offset="1" stop-color="#4a1c0a"/></radialGradient>
''')

FRY = '''<g transform="rotate({r} {cx} {cy})"><rect x="{x}" y="{y}" width="30" height="{h}" rx="5" fill="url(#fry)"/>
<rect x="{x}" y="{y}" width="30" height="16" rx="5" fill="#c9832a" opacity=".55"/>
<rect x="{xs}" y="{ys}" width="6" height="{hs}" rx="3" fill="#fff6c8" opacity=".55"/></g>'''


def fry(x, y, h, r):
    return FRY.format(r=r, cx=x + 15, cy=y + h / 2, x=x, y=y, h=h, xs=x + 6, ys=y + 20, hs=h - 40)


ART['pommes'] = svg(
    fry(170, 110, 190, -14) + fry(212, 88, 210, -5) + fry(254, 80, 220, 4) + fry(296, 96, 204, 12)
    + fry(236, 120, 180, -1) + fry(190, 138, 170, 8) + fry(276, 140, 170, -9) + '''
<path d="M136 236 Q256 272 376 236 L342 442 L170 442 Z" fill="url(#tuete)"/>
<path d="M136 236 Q256 272 376 236 L372 258 Q256 292 140 258 Z" fill="#a51c1c" opacity=".6"/>
<path d="M164 360 Q256 330 348 360" fill="none" stroke="#fff" stroke-width="16" opacity=".9"/>
''' + shine('M160 270 L182 430', 12, .35, 'blur8') + shine('M346 270 L334 430', 10, .2, 'blur8'), defs='''
<linearGradient id="fry" x1="0" x2="1"><stop offset="0" stop-color="#e8a83a"/><stop offset=".45" stop-color="#ffd967"/><stop offset="1" stop-color="#d9932c"/></linearGradient>
<linearGradient id="tuete" x1="0" x2="1"><stop offset="0" stop-color="#a81b1b"/><stop offset=".35" stop-color="#e2392f"/><stop offset=".7" stop-color="#d22a24"/><stop offset="1" stop-color="#8f1515"/></linearGradient>
''')

NUGGET = '''<path d="{d}" fill="url(#nug)" filter="url(#crumb)"/>'''
ART['nuggets'] = svg('''
<path d="M300 328 Q360 318 420 328 L408 404 Q360 422 312 404 Z" fill="url(#napf)"/>
<ellipse cx="360" cy="328" rx="60" ry="17" fill="#f2f2ec"/>
<ellipse cx="360" cy="330" rx="52" ry="12" fill="url(#ketchup)"/>
''' + shine('M330 326 Q350 322 366 324', 5, .8, 'blur1') + ''.join(NUGGET.format(d=d) for d in [
    'M96 300 C90 250 150 230 186 250 C222 268 222 320 190 340 C150 360 100 340 96 300 Z',
    'M190 230 C200 180 270 170 296 200 C322 232 300 276 262 282 C224 288 182 268 190 230 Z',
    'M160 380 C150 336 210 320 246 334 C286 350 288 396 252 412 C214 428 168 416 160 380 Z',
    'M230 330 C236 296 290 290 312 312 C334 336 316 372 284 376 C252 380 226 360 230 330 Z']) + '''
''' + shine('M120 270 C140 256 160 254 176 262', 7, .45) + shine('M214 208 C232 192 256 190 272 198', 7, .45)
    + shine('M182 352 C200 340 220 340 236 346', 7, .4) + shine('M250 314 C264 304 282 304 296 310', 6, .4), defs='''
<radialGradient id="nug" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#f4c56d"/><stop offset=".6" stop-color="#d9932f"/><stop offset="1" stop-color="#a8641a"/></radialGradient>
<linearGradient id="napf" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#cfcfc6"/><stop offset=".4" stop-color="#ffffff"/><stop offset="1" stop-color="#bdbdb4"/></linearGradient>
<radialGradient id="ketchup" cx=".4" cy=".3" r=".9"><stop offset="0" stop-color="#e5412d"/><stop offset="1" stop-color="#8f140c"/></radialGradient>
''')

# ---------------------------------------------------------------- Getränke

ART['wasser'] = svg('''
<path d="M216 70 L296 70 L296 112 Q342 140 342 196 L342 412 Q342 442 312 442 L200 442 Q170 442 170 412 L170 196 Q170 140 216 112 Z" fill="url(#pet)"/>
<path d="M176 226 L336 226 L336 410 Q336 436 310 436 L202 436 Q176 436 176 410 Z" fill="url(#water)"/>
<path d="M176 226 L336 226" stroke="#e8f7ff" stroke-width="5" opacity=".9"/>
<g stroke="#ffffff" stroke-width="3" opacity=".35" fill="none">
  <path d="M172 180 Q256 196 340 180 M172 380 Q256 396 340 380 M172 404 Q256 420 340 404"/>
</g>
<rect x="170" y="272" width="172" height="78" fill="url(#label)"/>
<path d="M170 272 L342 272 M170 350 L342 350" stroke="#1b5f9a" stroke-width="3" opacity=".5"/>
<path d="M256 284 C244 302 236 312 236 324 a20 20 0 0 0 40 0 C276 312 268 302 256 284 Z" fill="url(#drop)"/>
<rect x="204" y="38" width="104" height="44" rx="8" fill="url(#cap)"/>
<g stroke="#0f4a80" stroke-width="3" opacity=".6">
  <path d="M216 42 V78 M228 42 V78 M240 42 V78 M252 42 V78 M264 42 V78 M276 42 V78 M288 42 V78 M300 42 V78"/>
</g>
''' + shine('M196 150 Q188 200 190 262', 10, .85) + shine('M192 364 L192 418', 8, .7) + shine('M322 160 Q328 200 326 260', 5, .4)
    + bubbles([(300, 386, 5), (286, 404, 3.5), (312, 246, 4), (210, 400, 3), (230, 250, 3)], '#ffffff', .7), defs='''
<linearGradient id="pet" x1="0" x2="1"><stop offset="0" stop-color="#9fc6dc"/><stop offset=".2" stop-color="#eaf6fc"/>
  <stop offset=".6" stop-color="#d4ecf7"/><stop offset="1" stop-color="#8db7cf"/></linearGradient>
<linearGradient id="water" x1="0" x2="1"><stop offset="0" stop-color="#4fa5d8"/><stop offset=".3" stop-color="#8fd0f2"/>
  <stop offset=".7" stop-color="#6dbbe8"/><stop offset="1" stop-color="#3b8cc2"/></linearGradient>
<linearGradient id="label" x1="0" x2="1"><stop offset="0" stop-color="#d9e6ee"/><stop offset=".3" stop-color="#ffffff"/>
  <stop offset=".8" stop-color="#f2f6f8"/><stop offset="1" stop-color="#c8d6de"/></linearGradient>
<radialGradient id="drop" cx=".4" cy=".6" r=".8"><stop offset="0" stop-color="#7cc4f0"/><stop offset="1" stop-color="#1767a8"/></radialGradient>
<linearGradient id="cap" x1="0" x2="1"><stop offset="0" stop-color="#0f4f8a"/><stop offset=".4" stop-color="#3b8ad0"/><stop offset="1" stop-color="#0d4072"/></linearGradient>
''')

ART['softdrink'] = svg('''
<path d="M300 66 L330 66 L292 220" fill="none" stroke="url(#strohhalm)" stroke-width="14" stroke-linecap="round"/>
<path d="M164 206 L348 206 L332 432 L180 432 Z" fill="url(#cola)"/>
<path d="M164 206 L348 206 L346 222 L166 222 Z" fill="#c78a5a" opacity=".8"/>
''' + ice(190, 214, 58, -12) + ice(264, 228, 56, 10) + ice(222, 262, 50, 4)
    + bubbles([(210, 330, 4), (236, 370, 3.5), (290, 320, 4), (300, 384, 3), (262, 300, 3), (250, 400, 2.5), (310, 350, 2.5)], '#e7b48f', .75) + '''
<path d="M146 148 L366 148 L336 442 L176 442 Z" fill="url(#glass)"/>
<path d="M146 148 L366 148" stroke="url(#glassEdge)" stroke-width="5"/>
<path d="M176 432 L336 432 L334 446 L178 446 Z" fill="#cfe0e5" opacity=".9"/>
''' + shine('M170 170 L192 420', 12, .7) + shine('M340 170 L326 400', 6, .35)
    + drops([(200, 250, 4), (322, 300, 5), (214, 360, 3.5), (310, 410, 4), (330, 236, 3)]), defs=GLASS + '''
<linearGradient id="cola" x1="0" x2="1"><stop offset="0" stop-color="#2a0f05"/><stop offset=".35" stop-color="#6b2b12"/>
  <stop offset=".7" stop-color="#4a1c0a"/><stop offset="1" stop-color="#1f0a03"/></linearGradient>
<linearGradient id="strohhalm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff5a4a"/><stop offset="1" stop-color="#c41f1f"/></linearGradient>
''')

ART['longdrink'] = svg('''
<path d="M300 58 L272 270" stroke="#2f9a4c" stroke-width="13" stroke-linecap="round"/>
<path d="M186 158 L326 158 L316 432 L196 432 Z" fill="url(#sunrise)"/>
''' + ice(196, 168, 52, -10) + ice(258, 204, 52, 12) + ice(210, 246, 50, 4) + '''
<path d="M176 108 L336 108 L322 442 L190 442 Z" fill="url(#glass)"/>
<path d="M176 108 L336 108" stroke="url(#glassEdge)" stroke-width="5"/>
<path d="M190 432 L322 432 L320 446 L192 446 Z" fill="#cfe0e5" opacity=".9"/>
<circle cx="188" cy="112" r="48" fill="url(#limeSkin)"/>
<circle cx="188" cy="112" r="40" fill="#eaf6c6"/>
<circle cx="188" cy="112" r="35" fill="url(#limeFlesh)"/>
<g stroke="#eaf6c6" stroke-width="3">
  <path d="M188 77 L188 147 M153 112 L223 112 M163 87 L213 137 M163 137 L213 87"/>
</g>
''' + shine('M198 140 L210 420', 10, .6) + shine('M318 150 L308 410', 5, .3)
    + drops([(206, 330, 4), (302, 290, 4.5), (300, 404, 3.5), (214, 410, 3)]), defs=GLASS + '''
<linearGradient id="sunrise" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffc23a"/><stop offset=".55" stop-color="#ff7a1f"/>
  <stop offset=".85" stop-color="#e2352a"/><stop offset="1" stop-color="#b81d24"/></linearGradient>
<radialGradient id="limeSkin" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#9ad04a"/><stop offset="1" stop-color="#4f8f1d"/></radialGradient>
<radialGradient id="limeFlesh" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#e3f59d"/><stop offset="1" stop-color="#a7d44b"/></radialGradient>
''')

ART['bier'] = svg('''
<path d="M342 196 L392 196 Q436 196 436 244 L436 330 Q436 378 392 378 L342 378" fill="none" stroke="url(#henkel)" stroke-width="30" stroke-linecap="round"/>
<path d="M126 172 L350 172 L342 422 Q340 444 316 444 L160 444 Q136 444 134 422 Z" fill="url(#beer)"/>
''' + bubbles([(176, 300, 3), (178, 340, 2.5), (180, 380, 3), (300, 260, 3), (302, 300, 2.5), (304, 350, 3),
               (240, 240, 2.5), (244, 300, 3), (246, 360, 2.5), (210, 410, 2), (270, 400, 2.5)], '#fff1b8', .85) + '''
<path d="M116 172 L360 172 L350 432 Q348 452 322 452 L154 452 Q128 452 126 432 Z" fill="url(#glass)"/>
<g stroke="#ffffff" stroke-width="7" opacity=".3">
  <path d="M168 196 L172 428 M222 198 L224 432 M276 198 L276 432 M320 196 L316 428"/>
</g>
<path d="M126 434 L350 434 L348 452 L128 452 Z" fill="#e5c26a" opacity=".55"/>
<g>
  <path d="M110 190 C88 150 118 108 160 120 C172 84 228 78 246 108 C268 76 324 82 334 118 C376 108 398 152 370 190
           C346 212 134 214 110 190 Z" fill="url(#schaum)"/>
  <g fill="#ffffff" opacity=".9" filter="url(#blur1)">
    <circle cx="160" cy="140" r="10"/><circle cx="228" cy="116" r="12"/><circle cx="300" cy="126" r="10"/><circle cx="346" cy="152" r="8"/>
  </g>
  <g fill="#e8dcc0" opacity=".7">
    <circle cx="140" cy="178" r="5"/><circle cx="200" cy="168" r="4"/><circle cx="262" cy="176" r="5"/><circle cx="322" cy="170" r="4"/><circle cx="350" cy="186" r="3"/>
  </g>
</g>
''' + shine('M142 210 L150 420', 12, .55) + shine('M338 214 L330 410', 6, .3)
    + drops([(160, 260, 4), (318, 300, 5), (180, 360, 3.5), (300, 400, 4), (226, 410, 3), (330, 240, 3)]) + '''
<circle cx="112" cy="168" r="44" fill="url(#zitroneSchale)"/>
<circle cx="112" cy="168" r="37" fill="#fff8d6"/>
<circle cx="112" cy="168" r="32" fill="url(#zitrone)"/>
<g stroke="#fff8d6" stroke-width="3"><path d="M112 136 L112 200 M80 168 L144 168 M89 145 L135 191 M89 191 L135 145"/></g>
''', defs=GLASS + '''
<linearGradient id="beer" x1="0" x2="1"><stop offset="0" stop-color="#a85800"/><stop offset=".25" stop-color="#e8960a"/>
  <stop offset=".55" stop-color="#f9b425"/><stop offset=".8" stop-color="#e08a06"/><stop offset="1" stop-color="#9c5000"/></linearGradient>
<linearGradient id="henkel" x1="0" x2="1"><stop offset="0" stop-color="#c9dbe1"/><stop offset=".5" stop-color="#ffffff"/><stop offset="1" stop-color="#9fb8c0"/></linearGradient>
<radialGradient id="schaum" cx=".45" cy=".3" r=".9"><stop offset="0" stop-color="#ffffff"/><stop offset=".7" stop-color="#fbf4e2"/><stop offset="1" stop-color="#e2d3ad"/></radialGradient>
<radialGradient id="zitroneSchale" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#ffe76a"/><stop offset="1" stop-color="#e0b400"/></radialGradient>
<radialGradient id="zitrone" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#fff6b0"/><stop offset="1" stop-color="#f2d33c"/></radialGradient>
''')


def flute(cx, rot):
    return f'''<g transform="rotate({rot} {cx} 300)">
<path d="M{cx - 38} 92 L{cx + 38} 92 Q{cx + 44} 214 {cx + 14} 252 Q{cx} 264 {cx - 14} 252 Q{cx - 44} 214 {cx - 38} 92 Z" fill="url(#glass)"/>
<path d="M{cx - 35} 138 L{cx + 35} 138 Q{cx + 37} 214 {cx + 12} 244 Q{cx} 254 {cx - 12} 244 Q{cx - 37} 214 {cx - 35} 138 Z" fill="url(#sekt)"/>
<path d="M{cx - 35} 138 L{cx + 35} 138" stroke="#fff6cf" stroke-width="4"/>
{bubbles([(cx - 8, 220, 3.5), (cx + 6, 196, 3), (cx - 4, 172, 2.5), (cx + 10, 160, 2), (cx - 12, 150, 2), (cx + 2, 236, 2.5)], '#fffbe6', .95)}
<path d="M{cx - 38} 92 L{cx + 38} 92" stroke="url(#glassEdge)" stroke-width="4"/>
<path d="M{cx - 4} 256 L{cx - 4} 404 L{cx + 4} 404 L{cx + 4} 256 Z" fill="url(#glassEdge)"/>
<ellipse cx="{cx}" cy="410" rx="50" ry="12" fill="url(#glass)"/>
<ellipse cx="{cx}" cy="408" rx="50" ry="10" fill="none" stroke="#9fb8c0" stroke-width="2"/>
{shine(f'M{cx - 26} 110 Q{cx - 30} 180 {cx - 16} 230', 7, .8)}
</g>'''


ART['sekt'] = svg(flute(194, -10) + flute(318, 10) + '''
<g stroke="#f2c230" stroke-width="7" stroke-linecap="round" filter="url(#blur1)">
  <path d="M256 54 L256 22 M224 64 L206 38 M288 64 L306 38"/>
</g>
''', defs=GLASS + '''
<linearGradient id="sekt" x1="0" x2="1"><stop offset="0" stop-color="#d9a93a"/><stop offset=".4" stop-color="#f8de7a"/>
  <stop offset="1" stop-color="#d7a530"/></linearGradient>
''')

ART['shot'] = svg('''
<path d="M180 268 L332 268 L320 404 L192 404 Z" fill="url(#korn)"/>
<path d="M180 268 L332 268" stroke="#f6c07a" stroke-width="6"/>
<path d="M168 206 L344 206 L324 434 Q322 448 306 448 L206 448 Q190 448 188 434 Z" fill="url(#glass)"/>
<path d="M190 404 L322 404 L320 446 L192 446 Z" fill="url(#boden)"/>
<path d="M168 206 L344 206" stroke="url(#glassEdge)" stroke-width="5"/>
''' + shine('M192 226 L206 396', 11, .75) + shine('M326 230 L314 390', 5, .35) + '''
<path d="M298 200 L394 138 A72 72 0 0 1 352 240 Z" fill="url(#limeSkin)"/>
<path d="M310 202 L388 152 A58 58 0 0 1 352 228 Z" fill="url(#limeFlesh)"/>
<path d="M310 202 L372 182 M310 202 L360 214" stroke="#eaf6c6" stroke-width="3"/>
''', defs=GLASS + '''
<linearGradient id="korn" x1="0" x2="1"><stop offset="0" stop-color="#a24e0e"/><stop offset=".4" stop-color="#e3922f"/>
  <stop offset="1" stop-color="#9a470b"/></linearGradient>
<linearGradient id="boden" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e6f0f2" stop-opacity=".9"/><stop offset="1" stop-color="#9fb8c0"/></linearGradient>
<radialGradient id="limeSkin" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#9ad04a"/><stop offset="1" stop-color="#4f8f1d"/></radialGradient>
<radialGradient id="limeFlesh" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#e3f59d"/><stop offset="1" stop-color="#a7d44b"/></radialGradient>
''')

# ---------------------------------------------------------- Sonderkacheln

ART['pfand'] = svg('''
<path d="M172 146 L340 146 L316 424 L196 424 Z" fill="url(#becher)"/>
<g stroke="#ffffff" stroke-width="4" opacity=".5" fill="none">
  <path d="M176 196 L336 196 M182 260 L330 260 M188 330 L324 330"/>
</g>
<path d="M166 146 L346 146" stroke="#b9cdd4" stroke-width="12" stroke-linecap="round"/>
''' + shine('M192 170 L210 400', 12, .75) + '''
<g fill="none" stroke-width="24" stroke-linecap="round">
  <path d="M118 300 A142 142 0 0 1 296 136" stroke="url(#pfeil)"/>
  <path d="M394 228 A142 142 0 0 1 216 392" stroke="url(#pfeil)"/>
</g>
<path d="M276 100 L338 138 L274 172 Z" fill="#2c9450"/>
<path d="M236 356 L174 394 L238 428 Z" fill="#2c9450"/>
''', defs='''
<linearGradient id="becher" x1="0" x2="1"><stop offset="0" stop-color="#a9c3cc" stop-opacity=".85"/><stop offset=".25" stop-color="#f4fbfd"/>
  <stop offset=".7" stop-color="#e3f1f5"/><stop offset="1" stop-color="#93b1bb" stop-opacity=".9"/></linearGradient>
<linearGradient id="pfeil" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5cc27c"/><stop offset="1" stop-color="#1f7a3e"/></linearGradient>
''')


def coin(cx, cy):
    return f'''<ellipse cx="{cx}" cy="{cy + 16}" rx="86" ry="26" fill="#a87410"/>
<rect x="{cx - 86}" y="{cy}" width="172" height="16" fill="url(#rand)"/>
<ellipse cx="{cx}" cy="{cy}" rx="86" ry="26" fill="url(#muenze)"/>
<ellipse cx="{cx}" cy="{cy}" rx="66" ry="18" fill="none" stroke="#c9900f" stroke-width="3" opacity=".7"/>'''


ART['frei'] = svg('''
<g transform="rotate(-8 230 230)">
  <rect x="64" y="136" width="332" height="176" rx="12" fill="#2f6b4c" opacity=".35" filter="url(#blur8)" transform="translate(6 10)"/>
  <rect x="64" y="136" width="332" height="176" rx="12" fill="url(#schein)"/>
  <rect x="84" y="154" width="292" height="140" rx="8" fill="none" stroke="#3f8a64" stroke-width="3" opacity=".7"/>
  <g stroke="#5aa883" stroke-width="2" opacity=".5" fill="none">
    <path d="M90 180 Q160 160 230 180 T370 180 M90 270 Q160 250 230 270 T370 270"/>
  </g>
  <circle cx="230" cy="224" r="46" fill="url(#siegel)"/>
  <text x="230" y="248" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-weight="bold" font-size="66" fill="#246b47">€</text>
  <path d="M74 146 L386 146" stroke="#ffffff" stroke-width="5" opacity=".35" filter="url(#blur1)"/>
</g>
''' + coin(350, 384) + coin(350, 346) + coin(350, 308) + '''
<text x="350" y="322" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-weight="bold" font-size="38" fill="#a86f08">€</text>
''' + shine('M290 300 Q330 290 370 294', 6, .7, 'blur1'), defs='''
<linearGradient id="schein" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#a6dcbf"/><stop offset=".5" stop-color="#7cc4a0"/><stop offset="1" stop-color="#5aa883"/></linearGradient>
<radialGradient id="siegel" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#f3fbf6"/><stop offset="1" stop-color="#c7e6d5"/></radialGradient>
<radialGradient id="muenze" cx=".4" cy=".35" r=".85"><stop offset="0" stop-color="#fff0a8"/><stop offset=".5" stop-color="#f4c23a"/><stop offset="1" stop-color="#c88f10"/></radialGradient>
<linearGradient id="rand" x1="0" x2="1"><stop offset="0" stop-color="#b37d0e"/><stop offset=".4" stop-color="#f1c54a"/><stop offset="1" stop-color="#a06e0a"/></linearGradient>
''')

os.makedirs(OUT, exist_ok=True)
tmp = os.path.join(OUT, '_svg')
os.makedirs(tmp, exist_ok=True)
NAMES = [n for n in ART if not ONLY or n in ONLY]
for name in NAMES:
    content = ART[name]
    src = os.path.join(tmp, name + '.svg')
    with open(src, 'w') as f:
        f.write(content)
    dst = os.path.join(OUT, name + '.png')
    subprocess.run([CHROME, '--headless', '--no-sandbox', '--disable-gpu', '--hide-scrollbars',
                    '--default-background-color=00000000', '--window-size=512,512',
                    '--force-device-scale-factor=1', f'--screenshot={dst}', 'file://' + src],
                   check=True, capture_output=True)

from PIL import Image  # noqa: E402

for name in NAMES:
    path = os.path.join(OUT, name + '.png')
    im = Image.open(path).convert('RGBA')
    l, t, r, b = im.getchannel('A').point(lambda a: 255 if a > 8 else 0).getbbox()
    # Natürliches Seitenverhältnis mit etwas Rand, längste Seite 384 px.
    m = int(max(r - l, b - t) * 0.03)
    w, h = r - l + 2 * m, b - t + 2 * m
    canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    canvas.paste(im.crop((l, t, r, b)), (m, m))
    scale = 384 / max(w, h)
    canvas.resize((round(w * scale), round(h * scale)), Image.LANCZOS).save(path, optimize=True)
print('ok', len(NAMES))
