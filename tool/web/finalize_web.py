"""Bereitet build/web für die Veröffentlichung vor: entfernt Debug-Dateien
und trägt Version und Dateiliste in den Offline-Speicher (sw.js) ein.

Aufruf: python3 tool/web/finalize_web.py build/web <version>
"""
import json
import os
import sys

root, version = sys.argv[1], sys.argv[2]

# Debug-Symbole und Varianten, die dieser Build (dart2js + CanvasKit) nicht
# nutzt, gar nicht erst veröffentlichen.
SKIP_PREFIXES = ('canvaskit/skwasm', 'canvaskit/wimp', 'canvaskit/webparagraph')
for dirpath, _, files in os.walk(root):
    for name in files:
        rel = os.path.relpath(os.path.join(dirpath, name), root).replace(os.sep, '/')
        if (rel.endswith('.symbols') or rel.startswith(SKIP_PREFIXES)
                or rel in ('flutter_service_worker.js', '.last_build_id')):
            os.remove(os.path.join(dirpath, name))

precache = []
for dirpath, _, files in os.walk(root):
    for name in sorted(files):
        rel = os.path.relpath(os.path.join(dirpath, name), root).replace(os.sep, '/')
        # Die Chromium-Variante von CanvasKit braucht Safari (iPhone) nicht;
        # andere Browser laden sie bei Bedarf einmal nach.
        if rel in ('sw.js', '.nojekyll') or rel.startswith('canvaskit/chromium/'):
            continue
        precache.append(rel)
precache.sort()

sw_path = os.path.join(root, 'sw.js')
with open(sw_path, encoding='utf-8') as f:
    sw = f.read()
assert '__VERSION__' in sw and '__PRECACHE__' in sw, 'sw.js-Vorlage fehlt'
sw = sw.replace('__VERSION__', version).replace('__PRECACHE__', json.dumps(precache, indent=2))
with open(sw_path, 'w', encoding='utf-8') as f:
    f.write(sw)

# GitHub Pages soll die Dateien unverändert ausliefern.
open(os.path.join(root, '.nojekyll'), 'w').close()

size = sum(os.path.getsize(os.path.join(root, p)) for p in precache)
print(f'{len(precache)} Dateien, {size / 1e6:.1f} MB im Offline-Speicher, Version {version}')
