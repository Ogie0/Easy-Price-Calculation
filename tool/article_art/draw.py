"""Zeichnet die Artikelbilder (assets/articles) als SVG und rendert sie mit
Chromium zu PNG (längste Seite 384 px, transparent, auf den Inhalt
zugeschnitten). Halbrealistischer Stil: Verläufe, Licht, Schatten und
Oberflächenstruktur statt Konturen.

Aufruf: python3 tool/article_art/draw.py <ausgabeordner> [chromium]
Danach die PNGs nach assets/articles kopieren (pfand -> pfandrueckgabe,
frei -> freier_betrag).
"""
import os
import subprocess
import sys

OUT = sys.argv[1]
CHROME = sys.argv[2] if len(sys.argv) > 2 else (
    '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell')

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

ART['currywurst'] = svg('''
<path d="M322 300 L372 140" stroke="#c9a061" stroke-width="16" stroke-linecap="round"/>
<path d="M358 136 l-8 -32 M372 140 l0 -34 M386 144 l8 -32" stroke="#c9a061" stroke-width="9" stroke-linecap="round"/>
<path d="M322 300 L372 140" stroke="#fff" stroke-width="4" opacity=".4" filter="url(#blur1)"/>
<path d="M78 290 L434 290 L404 414 L108 414 Z" fill="url(#schale)"/>
<path d="M78 290 L434 290 L430 304 L82 304 Z" fill="#e9e9e2"/>
<path d="M92 334 L420 334" stroke="#c8352a" stroke-width="12"/>
<g>
''' + ''.join(f'''<ellipse cx="{x}" cy="{y}" rx="40" ry="25" fill="url(#skin)"/>
<ellipse cx="{x}" cy="{y - 4}" rx="30" ry="16" fill="url(#cut)"/>''' for x, y in
              [(150, 280), (226, 268), (302, 270), (370, 282), (190, 300), (268, 298), (340, 300)]) + '''
</g>
<path d="M116 262 Q150 236 190 256 Q230 232 268 252 Q310 232 350 254 Q386 242 400 272 Q382 302 340 294 Q300 314 262 296 Q222 314 188 294 Q148 306 116 262 Z" fill="url(#sauce)"/>
''' + shine('M150 254 Q170 246 190 256', 6, .8, 'blur1') + shine('M262 248 Q282 240 300 246', 6, .8, 'blur1') + shine('M344 258 Q362 252 380 262', 5, .7, 'blur1') + '''
<g fill="#e6a51d" filter="url(#blur1)">
  <circle cx="160" cy="264" r="4"/><circle cx="200" cy="272" r="3.5"/><circle cx="244" cy="258" r="4"/><circle cx="282" cy="272" r="3"/>
  <circle cx="318" cy="258" r="4"/><circle cx="356" cy="274" r="3"/><circle cx="226" cy="284" r="3"/><circle cx="300" cy="284" r="3.5"/>
  <circle cx="176" cy="282" r="3"/><circle cx="336" cy="282" r="3"/><circle cx="264" cy="266" r="3"/>
</g>
''', defs='''
<linearGradient id="schale" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#d9d9d0"/></linearGradient>
<radialGradient id="skin" cx=".5" cy=".4" r=".7"><stop offset="0" stop-color="#b8602f"/><stop offset="1" stop-color="#6e2810"/></radialGradient>
<radialGradient id="cut" cx=".45" cy=".4" r=".7"><stop offset="0" stop-color="#e3a98a"/><stop offset="1" stop-color="#b8714f"/></radialGradient>
<linearGradient id="sauce" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e2452a"/><stop offset=".6" stop-color="#b8231a"/><stop offset="1" stop-color="#8a150f"/></linearGradient>
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

ART['steak'] = svg('''
<rect x="40" y="250" width="432" height="180" rx="24" fill="url(#brett)" filter="url(#grain)"/>
<g stroke="#8a5a2c" stroke-width="3" opacity=".35" fill="none">
  <path d="M60 290 Q256 280 452 296 M56 330 Q256 322 456 336 M60 372 Q256 362 452 378 M66 408 Q256 400 446 412"/>
</g>
<path d="M40 404 L472 404 L472 406 Q472 430 448 430 L64 430 Q40 430 40 406 Z" fill="#7a4a20" opacity=".6"/>
<path d="M92 252 C90 170 214 132 310 152 C408 172 452 232 432 304 C412 380 304 404 216 388 C132 374 94 330 92 252 Z"
  fill="#3a1a0e" opacity=".55" filter="url(#blur8)" transform="translate(6 14)"/>
<path d="M92 252 C90 170 214 132 310 152 C408 172 452 232 432 304 C412 380 304 404 216 388 C132 374 94 330 92 252 Z" fill="url(#fett)"/>
<g filter="url(#grain)">
  <path d="M116 254 C116 188 216 164 300 178 C384 192 418 238 404 296 C388 352 302 374 224 362 C152 350 116 314 116 254 Z" fill="url(#fleisch)"/>
</g>
<g stroke="#2b0f05" stroke-width="16" stroke-linecap="round" opacity=".75" filter="url(#blur3)">
  <path d="M154 222 L236 304 M200 190 L306 296 M262 180 L366 284 M324 190 L396 262 M144 296 L180 332"/>
</g>
''' + shine('M150 208 C200 182 280 176 340 190', 10, .35, 'blur8') + '''
<path d="M282 190 C322 170 352 170 372 186" fill="none" stroke="#2f6b2a" stroke-width="5" stroke-linecap="round"/>
<g fill="#4c8f3e">
  <ellipse cx="300" cy="176" rx="14" ry="4.5" transform="rotate(-30 300 176)"/><ellipse cx="324" cy="170" rx="14" ry="4.5" transform="rotate(20 324 170)"/>
  <ellipse cx="346" cy="174" rx="14" ry="4.5" transform="rotate(-25 346 174)"/><ellipse cx="312" cy="190" rx="14" ry="4.5" transform="rotate(30 312 190)"/>
  <ellipse cx="336" cy="190" rx="14" ry="4.5" transform="rotate(-20 336 190)"/><ellipse cx="360" cy="186" rx="12" ry="4" transform="rotate(25 360 186)"/>
</g>
<g fill="#f3efe4"><circle cx="190" cy="330" r="3"/><circle cx="262" cy="346" r="2.5"/><circle cx="350" cy="320" r="3"/><circle cx="220" cy="240" r="2.5"/></g>
''', shadow=(256, 440, 220, 14), defs='''
<linearGradient id="brett" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d8a868"/><stop offset="1" stop-color="#b07c40"/></linearGradient>
<radialGradient id="fett" cx=".45" cy=".35" r=".8"><stop offset="0" stop-color="#f6e4c4"/><stop offset="1" stop-color="#cf9e64"/></radialGradient>
<radialGradient id="fleisch" cx=".45" cy=".35" r=".8"><stop offset="0" stop-color="#a65a33"/><stop offset=".6" stop-color="#7c3b1d"/><stop offset="1" stop-color="#4f210d"/></radialGradient>
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
for name, content in ART.items():
    src = os.path.join(tmp, name + '.svg')
    with open(src, 'w') as f:
        f.write(content)
    dst = os.path.join(OUT, name + '.png')
    subprocess.run([CHROME, '--headless', '--no-sandbox', '--disable-gpu', '--hide-scrollbars',
                    '--default-background-color=00000000', '--window-size=512,512',
                    '--force-device-scale-factor=1', f'--screenshot={dst}', 'file://' + src],
                   check=True, capture_output=True)

from PIL import Image  # noqa: E402

for name in ART:
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
print('ok', len(ART))
