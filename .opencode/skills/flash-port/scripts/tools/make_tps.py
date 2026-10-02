"""Rewrites the individual sprite settings (pivot points) of a TexturePacker .tps project for a src/ folder.
usage: make_tps.py <template.tps> <src dir> <pivots.json> <out.tps> [game package]
(the template tpl.tps next to this file writes the sheets as GAME-{n}.json: GAME is replaced by the package)
Sprites are grouped like the packer does (one group per animation folder / single png) and share the pivot of their group."""
import os, re, sys, json
from PIL import Image

TPL, SRC, PIVOTS, OUT = sys.argv[1:5]
GAME = sys.argv[5] if len(sys.argv) > 5 else os.path.basename(OUT)[:-4]
pivots = json.load(open(PIVOTS))


def natural_key(s):
    return [int(t) if t.isdigit() else t for t in re.split(r'(\d+)', s)]


groups = {}
for root, _, files in os.walk(SRC):
    for f in files:
        if f.lower().endswith('.png'):
            name = os.path.relpath(os.path.join(root, f), SRC).replace('\\', '/')
            group = name.rsplit('/', 1)[0] if '/' in name else name[:-4]
            groups.setdefault(group, []).append(name)


def fmt(v):
    return ('%.6f' % v).rstrip('0').rstrip('.') if v != int(v) else str(int(v))


out = []
for group in sorted(groups, key=natural_key):
    names = sorted(groups[group], key=natural_key)
    w, h = Image.open(os.path.join(SRC, names[0])).size
    px, py = pivots.get(group, [0, 0])
    for n in names:
        out.append('            <key type="filename">src/%s</key>' % n)
    rect = '%d,%d,%d,%d' % (round(w / 4), round(h / 4), round(w / 2), round(h / 2))
    out += ['            <struct type="IndividualSpriteSettings">',
            '                <key>pivotPoint</key>',
            '                <point_f>%s,%s</point_f>' % (fmt(px), fmt(py)),
            '                <key>spriteScale</key>',
            '                <double>1</double>',
            '                <key>scale9Enabled</key>',
            '                <false/>',
            '                <key>scale9Borders</key>',
            '                <rect>%s</rect>' % rect,
            '                <key>scale9Paddings</key>',
            '                <rect>%s</rect>' % rect,
            '                <key>scale9FromFile</key>',
            '                <false/>',
            '            </struct>']

tps = open(TPL, encoding='utf-8').read()
start = tps.index('<map type="IndividualSpriteSettingsMap">')
start = tps.index('\n', start) + 1
end = tps.index('        </map>', start)
tps = tps[:start] + '\n'.join(out) + '\n' + tps[end:]
tps = tps.replace('GAME-{n}.json', GAME + '-{n}.json')
open(OUT, 'w', encoding='utf-8', newline='\n').write(tps)
print('%d groups, %d sprites' % (len(groups), sum(len(v) for v in groups.values())))
