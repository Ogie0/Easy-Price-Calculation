"""Zeichnet die Artikelbilder (assets/articles) als SVG und rendert sie mit
Chromium zu PNG (384 x 384, transparent, auf den Inhalt zugeschnitten).

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
INK = '#3b2a20'
SW = 10  # Konturstärke


def svg(body, defs=''):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<defs>{defs}</defs>
<ellipse cx="256" cy="452" rx="170" ry="20" fill="#000" opacity=".13"/>
<g stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round" stroke-linecap="round">{body}</g>
</svg>'''


def hl(d, w=10, op=.55):
    """Glanzlicht ohne Kontur."""
    return f'<path d="{d}" fill="none" stroke="#fff" stroke-width="{w}" opacity="{op}"/>'


ART = {}

ART['bratwurst'] = svg(f'''
<path d="M78 268 Q256 168 434 268 L434 300 L78 300 Z" fill="#d9964a"/>
<rect x="46" y="238" width="420" height="78" rx="39" fill="#b4532b"/>
<g stroke="#7d3317" stroke-width="7"><path d="M120 258 l26 38 M190 256 l26 40 M260 256 l26 40 M330 256 l26 40 M394 258 l22 34"/></g>
{hl('M92 256 Q256 248 420 256', 9)}
<path d="M80 270 q20 -22 40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0 t40 0" fill="none" stroke="#f2c418" stroke-width="12"/>
<path d="M66 300 Q256 410 446 300 Q456 338 428 358 Q256 446 84 358 Q56 338 66 300 Z" fill="#efb565"/>
{hl('M110 352 Q256 410 400 352', 9, .35)}
''')

ART['currywurst'] = svg(f'''
<path d="M318 300 L366 150" stroke="#e7c27b" stroke-width="18"/>
<path d="M352 146 l-8 -34 M366 150 l0 -36 M380 154 l8 -34" stroke="#e7c27b" stroke-width="10"/>
<path d="M84 292 L428 292 L398 410 L114 410 Z" fill="#fbfbf7"/>
<path d="M95 330 L417 330" stroke="#d63a2b" stroke-width="14"/>
<g fill="#b4532b">
<ellipse cx="150" cy="280" rx="40" ry="26"/><ellipse cx="226" cy="268" rx="40" ry="26"/>
<ellipse cx="302" cy="270" rx="40" ry="26"/><ellipse cx="370" cy="282" rx="38" ry="25"/>
<ellipse cx="190" cy="300" rx="40" ry="24"/><ellipse cx="268" cy="298" rx="40" ry="24"/><ellipse cx="340" cy="300" rx="38" ry="24"/>
</g>
<path d="M118 262 Q150 238 190 258 Q230 236 268 254 Q310 236 350 256 Q384 246 398 272 Q380 300 340 292 Q300 312 262 294 Q222 312 190 292 Q150 304 118 262 Z" fill="#c9311f"/>
<g fill="#f0b21c" stroke="none">
<circle cx="160" cy="262" r="5"/><circle cx="200" cy="270" r="4"/><circle cx="244" cy="258" r="5"/><circle cx="282" cy="270" r="4"/>
<circle cx="318" cy="258" r="5"/><circle cx="356" cy="272" r="4"/><circle cx="226" cy="282" r="4"/><circle cx="300" cy="284" r="4"/>
</g>
''')

ART['krakauer'] = svg(f'''
<path d="M60 300 C90 170 340 130 456 220 L432 290 C340 220 160 236 140 330 Z" fill="#9b3a28"/>
<g fill="#e7b7a3" stroke="none">
<circle cx="120" cy="268" r="6"/><circle cx="160" cy="236" r="5"/><circle cx="214" cy="214" r="6"/><circle cx="270" cy="204" r="5"/>
<circle cx="326" cy="206" r="6"/><circle cx="380" cy="220" r="5"/><circle cx="420" cy="242" r="5"/><circle cx="104" cy="306" r="5"/>
<circle cx="190" cy="244" r="4"/><circle cx="300" cy="226" r="4"/><circle cx="360" cy="244" r="4"/>
</g>
{hl('M96 262 C150 196 300 170 410 206', 9, .35)}
<ellipse cx="100" cy="316" rx="38" ry="42" fill="#d6857a" transform="rotate(18 100 316)"/>
<g fill="#f8e4dc" stroke="none"><circle cx="92" cy="300" r="7"/><circle cx="112" cy="324" r="6"/><circle cx="88" cy="334" r="5"/><circle cx="114" cy="296" r="4"/></g>
<g>
<ellipse cx="250" cy="380" rx="56" ry="40" fill="#9b3a28"/>
<ellipse cx="256" cy="376" rx="44" ry="30" fill="#d6857a" stroke="none"/>
<g fill="#f8e4dc" stroke="none"><circle cx="240" cy="368" r="7"/><circle cx="268" cy="384" r="6"/><circle cx="262" cy="362" r="4"/><circle cx="238" cy="388" r="4"/></g>
<ellipse cx="380" cy="384" rx="56" ry="40" fill="#9b3a28"/>
<ellipse cx="386" cy="380" rx="44" ry="30" fill="#d6857a" stroke="none"/>
<g fill="#f8e4dc" stroke="none"><circle cx="372" cy="372" r="7"/><circle cx="398" cy="388" r="6"/><circle cx="394" cy="366" r="4"/><circle cx="368" cy="392" r="4"/></g>
</g>
''')

ART['steak'] = svg(f'''
<path d="M86 260 C84 176 210 140 306 160 C402 180 448 238 428 308 C408 382 302 408 214 392 C130 378 88 336 86 260 Z" fill="#e9cfae"/>
<path d="M112 262 C112 196 214 172 298 186 C380 200 414 244 400 300 C384 356 298 378 222 366 C150 354 112 318 112 262 Z" fill="#8f4a2a" stroke="none"/>
<g stroke="#4b2414" stroke-width="13" opacity=".85">
<path d="M150 228 L230 310 M196 196 L300 300 M256 186 L360 290 M318 196 L392 270 M140 300 L176 336"/>
</g>
{hl('M150 214 C200 186 280 182 340 198', 8, .3)}
<path d="M280 196 C320 176 350 176 370 192" fill="none" stroke="#3f8f3a" stroke-width="9"/>
<g fill="#4fa046" stroke="none"><ellipse cx="300" cy="180" rx="13" ry="5" transform="rotate(-30 300 180)"/><ellipse cx="324" cy="174" rx="13" ry="5" transform="rotate(20 324 174)"/><ellipse cx="346" cy="178" rx="13" ry="5" transform="rotate(-25 346 178)"/><ellipse cx="312" cy="196" rx="13" ry="5" transform="rotate(30 312 196)"/><ellipse cx="336" cy="194" rx="13" ry="5" transform="rotate(-20 336 194)"/></g>
''')

ART['pommes'] = svg(f'''
<g fill="#f6c84c">
<rect x="170" y="110" width="30" height="190" rx="6" transform="rotate(-14 185 205)"/>
<rect x="212" y="88" width="30" height="210" rx="6" transform="rotate(-5 227 193)"/>
<rect x="254" y="80" width="30" height="220" rx="6" transform="rotate(4 269 190)"/>
<rect x="296" y="96" width="30" height="204" rx="6" transform="rotate(12 311 198)"/>
<rect x="236" y="120" width="30" height="180" rx="6" transform="rotate(-1 251 210)"/>
<rect x="190" y="138" width="30" height="170" rx="6" transform="rotate(8 205 223)"/>
<rect x="276" y="140" width="30" height="170" rx="6" transform="rotate(-9 291 225)"/>
</g>
<path d="M138 236 Q256 270 374 236 L340 440 L172 440 Z" fill="#d8312c"/>
<path d="M150 252 Q256 284 362 252" fill="none" stroke="#fff" stroke-width="8" opacity=".55"/>
<path d="M162 360 Q256 330 350 360" fill="none" stroke="#fff" stroke-width="16" opacity=".9"/>
''')

ART['nuggets'] = svg(f'''
<path d="M300 330 Q360 320 420 330 L408 400 Q360 416 312 400 Z" fill="#fff"/>
<ellipse cx="360" cy="330" rx="60" ry="16" fill="#d8312c"/>
<g fill="#e3a24a">
<path d="M96 300 C90 250 150 230 186 250 C222 268 222 320 190 340 C150 360 100 340 96 300 Z"/>
<path d="M190 230 C200 180 270 170 296 200 C322 232 300 276 262 282 C224 288 182 268 190 230 Z"/>
<path d="M160 380 C150 336 210 320 246 334 C286 350 288 396 252 412 C214 428 168 416 160 380 Z"/>
<path d="M230 330 C236 296 290 290 312 312 C334 336 316 372 284 376 C252 380 226 360 230 330 Z"/>
</g>
<g fill="#b8752a" stroke="none">
<circle cx="130" cy="280" r="5"/><circle cx="160" cy="300" r="4"/><circle cx="146" cy="324" r="5"/><circle cx="184" cy="290" r="4"/>
<circle cx="230" cy="214" r="5"/><circle cx="262" cy="230" r="4"/><circle cx="244" cy="256" r="5"/><circle cx="276" cy="206" r="4"/>
<circle cx="200" cy="368" r="5"/><circle cx="226" cy="390" r="4"/><circle cx="246" cy="364" r="4"/>
<circle cx="268" cy="324" r="5"/><circle cx="292" cy="346" r="4"/>
</g>
''')

ART['wasser'] = svg(f'''
<path d="M216 70 L296 70 L296 112 Q340 140 340 196 L340 410 Q340 440 310 440 L202 440 Q172 440 172 410 L172 196 Q172 140 216 112 Z" fill="#d7eefb"/>
<path d="M178 230 L334 230 L334 408 Q334 432 308 432 L204 432 Q178 432 178 408 Z" fill="#7fc6ef" stroke="none"/>
<rect x="206" y="42" width="100" height="40" rx="8" fill="#1f6fb2"/>
<rect x="172" y="276" width="168" height="74" fill="#ffffff"/>
<path d="M256 288 C246 304 238 314 238 324 a18 18 0 0 0 36 0 C274 314 266 304 256 288 Z" fill="#2c8fd6"/>
{hl('M200 160 Q194 196 196 260 M198 370 L198 410', 10, .7)}
<g fill="#fff" stroke="none" opacity=".8"><circle cx="300" cy="380" r="6"/><circle cx="284" cy="404" r="4"/><circle cx="310" cy="250" r="5"/></g>
''')

ART['softdrink'] = svg(f'''
<path d="M300 70 L330 70 L292 210" fill="none" stroke="#e23b3b" stroke-width="14"/>
<path d="M300 70 L330 70 L292 210" fill="none" stroke="{INK}" stroke-width="0"/>
<path d="M150 150 L362 150 L334 440 L178 440 Z" fill="#eef7fb"/>
<path d="M160 200 L352 200 L332 432 L180 432 Z" fill="#6b2f17" stroke="none"/>
<path d="M162 200 L350 200" stroke="#c9875a" stroke-width="10"/>
<g fill="#e9f6fd" opacity=".95"><rect x="190" y="214" width="56" height="50" rx="10" transform="rotate(-12 218 239)"/><rect x="262" y="226" width="56" height="50" rx="10" transform="rotate(10 290 251)"/></g>
<g fill="#d79c73" stroke="none" opacity=".9"><circle cx="210" cy="330" r="6"/><circle cx="236" cy="370" r="5"/><circle cx="290" cy="320" r="6"/><circle cx="300" cy="380" r="4"/><circle cx="262" cy="300" r="4"/></g>
{hl('M176 170 L196 420', 10, .6)}
''')

ART['longdrink'] = svg(f'''
<defs><linearGradient id="sun" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffb52e"/><stop offset=".6" stop-color="#ff7a1f"/><stop offset="1" stop-color="#d9262c"/></linearGradient></defs>
<path d="M300 60 L270 260" stroke="#3aa655" stroke-width="14"/>
<path d="M178 110 L334 110 L320 440 L192 440 Z" fill="#fdf2e6"/>
<path d="M184 160 L328 160 L318 432 L194 432 Z" fill="url(#sun)" stroke="none"/>
<g fill="#fff6ea" opacity=".9"><rect x="200" y="174" width="50" height="46" rx="9" transform="rotate(-10 225 197)"/><rect x="262" y="210" width="50" height="46" rx="9" transform="rotate(12 287 233)"/><rect x="214" y="250" width="50" height="46" rx="9" transform="rotate(4 239 273)"/></g>
<circle cx="190" cy="110" r="46" fill="#9bd24a"/>
<circle cx="190" cy="110" r="32" fill="#c8ee86" stroke="none"/>
<path d="M190 82 L190 138 M162 110 L218 110 M170 90 L210 130 M170 130 L210 90" stroke="#9bd24a" stroke-width="4"/>
{hl('M200 180 L210 420', 9, .5)}
''')

ART['bier'] = svg(f'''
<defs><linearGradient id="beer" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffc93a"/><stop offset="1" stop-color="#e48b00"/></linearGradient></defs>
<path d="M340 200 L392 200 Q430 200 430 244 L430 330 Q430 372 392 372 L340 372" fill="none" stroke="{INK}" stroke-width="40"/>
<path d="M340 200 L392 200 Q430 200 430 244 L430 330 Q430 372 392 372 L340 372" fill="none" stroke="#f3f0e6" stroke-width="22"/>
<path d="M120 170 L352 170 L344 420 Q342 442 318 442 L154 442 Q130 442 128 420 Z" fill="url(#beer)"/>
<g fill="#fff3c4" stroke="none" opacity=".85"><circle cx="190" cy="300" r="7"/><circle cx="214" cy="356" r="5"/><circle cx="276" cy="330" r="6"/><circle cx="300" cy="390" r="4"/><circle cx="240" cy="260" r="4"/></g>
<path d="M112 186 C92 150 120 112 158 122 C170 88 222 82 240 110 C262 80 316 86 326 120 C366 112 388 152 362 186 C340 206 136 210 112 186 Z" fill="#fffdf6"/>
<path d="M160 176 L160 420 M216 182 L216 424 M272 182 L272 424" stroke="#fff" stroke-width="8" opacity=".35"/>
<circle cx="108" cy="150" r="42" fill="#ffe14d"/>
<circle cx="108" cy="150" r="28" fill="#fff4a8" stroke="none"/>
<path d="M108 124 L108 176 M82 150 L134 150 M90 132 L126 168 M90 168 L126 132" stroke="#ffe14d" stroke-width="4"/>
''')

ART['sekt'] = svg(f'''
<g transform="rotate(-10 190 300)">
<path d="M160 80 L240 80 Q246 210 214 250 Q200 262 186 250 Q154 210 160 80 Z" fill="#fff8e4"/>
<path d="M163 130 L237 130 Q238 210 212 240 Q200 250 188 240 Q162 210 163 130 Z" fill="#f6d35b" stroke="none"/>
<path d="M200 256 L200 400" stroke-width="12"/><ellipse cx="200" cy="410" rx="48" ry="12" fill="#fff8e4"/>
<g fill="#fffbe9" stroke="none"><circle cx="190" cy="200" r="5"/><circle cx="210" cy="170" r="4"/><circle cx="198" cy="150" r="3"/></g>
</g>
<g transform="rotate(10 322 300)">
<path d="M272 80 L352 80 Q358 210 326 250 Q312 262 298 250 Q266 210 272 80 Z" fill="#fff8e4"/>
<path d="M275 130 L349 130 Q350 210 324 240 Q312 250 300 240 Q274 210 275 130 Z" fill="#f6d35b" stroke="none"/>
<path d="M312 256 L312 400" stroke-width="12"/><ellipse cx="312" cy="410" rx="48" ry="12" fill="#fff8e4"/>
<g fill="#fffbe9" stroke="none"><circle cx="304" cy="196" r="5"/><circle cx="322" cy="168" r="4"/><circle cx="312" cy="150" r="3"/></g>
</g>
<path d="M256 52 L256 22 M226 62 L208 38 M286 62 L304 38" stroke="#f0b21c" stroke-width="10"/>
''')

ART['shot'] = svg(f'''
<path d="M170 210 L342 210 L322 430 Q320 444 304 444 L208 444 Q192 444 190 430 Z" fill="#fdf6ec"/>
<path d="M178 268 L334 268 L320 410 L192 410 Z" fill="#d9822b" stroke="none"/>
<path d="M178 268 L334 268" stroke="#f3b067" stroke-width="10"/>
<path d="M194 410 L318 410 L316 436 L196 436 Z" fill="#efe4d6" stroke="none" opacity=".9"/>
{hl('M196 232 L210 400', 10, .6)}
<path d="M300 200 L392 140 A70 70 0 0 1 352 236 Z" fill="#9bd24a"/>
<path d="M314 204 L384 158 A52 52 0 0 1 350 222 Z" fill="#c8ee86" stroke="none"/>
''')

ART['pfand'] = svg(f'''
<path d="M176 150 L336 150 L314 420 L198 420 Z" fill="#e5f3fb"/>
<path d="M170 150 L342 150" stroke-width="14"/>
{hl('M196 176 L212 396', 10, .7)}
<g fill="none" stroke="#2e9d57" stroke-width="22">
<path d="M120 300 A140 140 0 0 1 300 136"/>
<path d="M392 230 A140 140 0 0 1 212 394"/>
</g>
<g fill="#2e9d57" stroke="none">
<path d="M282 104 L336 140 L280 170 Z"/>
<path d="M230 360 L176 396 L232 426 Z"/>
</g>
''')

ART['frei'] = svg(f'''
<g transform="rotate(-8 230 230)">
<rect x="70" y="140" width="320" height="170" rx="16" fill="#7cc3a0"/>
<rect x="92" y="160" width="276" height="130" rx="10" fill="none" stroke="#4e9b77" stroke-width="6"/>
<circle cx="230" cy="225" r="46" fill="#e9f7ef" stroke="#4e9b77" stroke-width="6"/>
<text x="230" y="250" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-weight="bold" font-size="70" fill="#2b7a55" stroke="none">€</text>
</g>
<g>
<ellipse cx="350" cy="420" rx="86" ry="26" fill="#d99a1e"/>
<rect x="264" y="378" width="172" height="42" fill="#f4c03a" stroke="none"/>
<path d="M264 378 L264 420 M436 378 L436 420" />
<ellipse cx="350" cy="378" rx="86" ry="26" fill="#ffd75a"/>
<ellipse cx="350" cy="340" rx="86" ry="26" fill="#f4c03a"/>
<rect x="264" y="300" width="172" height="40" fill="#f4c03a" stroke="none"/>
<path d="M264 300 L264 340 M436 300 L436 340"/>
<ellipse cx="350" cy="300" rx="86" ry="26" fill="#ffd75a"/>
<text x="350" y="314" text-anchor="middle" font-family="DejaVu Sans, Arial, sans-serif" font-weight="bold" font-size="40" fill="#b77f10" stroke="none">€</text>
</g>
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
from PIL import Image
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
