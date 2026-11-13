"""HMG5 logos: writes the SVG files of this folder (python logo/make_logos.py).

The letters are drawn as paths (rounded strokes), so the logos look the same
everywhere, with no font to install. Only the taglines use a system font.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))

NAVY = '#0E1A3A'
GRAD = [('0', '#14D8A5'), ('0.5', '#1E9BFF'), ('1', '#5A4DFF')]

# Glyphs on a 120-unit cap height, as stroke paths: (path, advance width)
GLYPHS = {
    'H': ('M0,0 V120 M72,0 V120 M0,60 H72', 72),
    'M': ('M0,120 V0 L46,74 L92,0 V120', 92),
    'G': ('M98,22 C88,8 74,0 58,0 C26,0 0,26 0,60 C0,94 26,120 58,120 C88,120 108,98 108,66 H66', 108),
    '5': ('M76,2 H20 L13,54 C24,47 36,45 46,45 C67,45 82,61 82,82 C82,104 66,120 43,120 C27,120 14,113 5,101', 82),
    'I': ('M0,0 V120', 0),
    'D': ('M0,0 V120 H28 C68,120 92,96 92,60 C92,24 68,0 28,0 Z', 92),
    'E': ('M72,0 H0 V120 H72 M0,60 H58', 72),
}
GAP = 50


def grad(gid, x1='0', y1='0', x2='1', y2='1'):
    stops = ''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in GRAD)
    return f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{stops}</linearGradient>'


def word(text, x, y, scale, stroke, color, gap=GAP):
    """the letters of text from (x, y) (top left), cap height 120*scale -> (svg, width)"""
    out, cx = [], 0
    for ch in text:
        p, w = GLYPHS[ch]
        out.append(f'<path transform="translate({x + cx * scale:.1f},{y:.1f}) scale({scale})" d="{p}" '
                   f'fill="none" stroke="{color}" stroke-width="{stroke / scale:.2f}" '
                   f'stroke-linecap="round" stroke-linejoin="round"/>')
        cx += w + gap
    return ''.join(out), (cx - gap) * scale


def tile(gid, inner):
    """the rounded gradient tile with an app window on it, 512 x 512"""
    return (
        f'<rect width="512" height="512" rx="116" fill="url(#{gid})"/>'
        '<path d="M116,0 H396 A116,116 0 0 1 512,116 V200 C380,250 160,240 0,190 V116 A116,116 0 0 1 116,0 Z" fill="#fff" opacity="0.10"/>'
        '<rect x="92" y="108" width="328" height="296" rx="44" fill="#fff" fill-opacity="0.12" stroke="#fff" stroke-width="20"/>'
        '<path d="M92,178 H420" stroke="#fff" stroke-width="20"/>'
        '<circle cx="140" cy="143" r="11" fill="#fff"/><circle cx="176" cy="143" r="11" fill="#fff" opacity="0.75"/>'
        '<circle cx="212" cy="143" r="11" fill="#fff" opacity="0.5"/>'
        + inner)


def five_in_window():
    g, _ = word('5', 0, 0, 1.45, 34, '#fff')
    # the 5 is 82 x 120 units: centred in the window's body (92..420, 178..404)
    return f'<g transform="translate({256 - 82 * 1.45 / 2:.1f},{291 - 120 * 1.45 / 2:.1f})">{g}</g>'


def code_in_window():
    g, _ = word('5', 0, 0, 1.05, 30, '#fff')
    chev = ('<path d="M178,236 L132,291 L178,346 M334,236 L380,291 L334,346" fill="none" stroke="#fff" '
            'stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>')
    return chev + f'<g transform="translate({256 - 82 * 1.05 / 2:.1f},{291 - 120 * 1.05 / 2:.1f})">{g}</g>'


def small_inner(ide):
    """for 16-32 px icons: no window frame, bigger strokes"""
    if ide:
        g, _ = word('5', 0, 0, 1.6, 44, '#fff')
        chev = ('<path d="M150,180 L84,256 L150,332 M362,180 L428,256 L362,332" fill="none" stroke="#fff" '
                'stroke-width="44" stroke-linecap="round" stroke-linejoin="round"/>')
        return chev + f'<g transform="translate({256 - 82 * 1.6 / 2:.1f},{256 - 120 * 1.6 / 2:.1f})">{g}</g>'
    g, _ = word('5', 0, 0, 2.3, 56, '#fff')
    return f'<g transform="translate({256 - 82 * 2.3 / 2:.1f},{256 - 120 * 2.3 / 2:.1f})">{g}</g>'


def mark_small(ide=False):
    gid = 'hmg5g'
    return svg(512, 512, f'<defs>{grad(gid)}</defs><rect width="512" height="512" rx="116" fill="url(#{gid})"/>' + small_inner(ide),
               'HMG5 IDE' if ide else 'HMG5')


def svg(w, h, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'role="img" aria-label="{title}"><title>{title}</title>{body}</svg>\n')


def mark(ide=False):
    gid = 'hmg5g'
    return svg(512, 512, f'<defs>{grad(gid)}</defs>' + tile(gid, code_in_window() if ide else five_in_window()),
               'HMG5 IDE' if ide else 'HMG5')


def lockup(ide=False, dark=False):
    gid = 'hmg5g'
    ink = '#FFFFFF' if dark else NAVY
    sub = '#A9B4D0' if dark else '#5B6785'
    s = 0.5  # the mark at 256 px
    body = f'<defs>{grad(gid)}{grad("hmg5w", "0", "0", "1", "0")}</defs>'
    body += f'<g transform="translate(32,32) scale({s})">' + tile(gid, code_in_window() if ide else five_in_window()) + '</g>'
    x0, cap, y0 = 336, 1.25, 70
    hmg, w = word('HMG', x0, y0, cap, 26, ink)
    body += hmg
    x5 = x0 + w + GAP * cap
    five, w5 = word('5', x5, y0, cap, 26, 'url(#hmg5w)')
    body += five
    right = x5 + w5
    if ide:
        px = right + 44
        ide_g, wi = word('IDE', px + 34, y0 + 30, 0.75, 17, '#fff', gap=46)
        body += (f'<rect x="{px:.1f}" y="{y0 + 6:.1f}" width="{wi + 68:.1f}" height="138" rx="34" fill="url(#hmg5w)"/>' + ide_g)
        right = px + wi + 68
    tag = 'Forms designer, code editor and builder for HMG5' if ide else 'xBase GUI for Windows · 64-bit · Harbour'
    body += (f'<text x="{x0 - 4}" y="{y0 + 150 + 62}" font-family="Segoe UI, Inter, Helvetica, Arial, sans-serif" '
             f'font-size="34" letter-spacing="0.5" fill="{sub}">{tag}</text>')
    tagw = len(tag) * 34 * 0.5   # about, for Segoe UI at 34 px
    width = int(max(right, x0 + tagw) + 40)
    return svg(width, 320, body, ('HMG5 IDE' if ide else 'HMG5'))


FILES = {
    'hmg5-mark.svg': mark(),
    'hmg5-ide-mark.svg': mark(ide=True),
    'hmg5-mark-small.svg': mark_small(),
    'hmg5-ide-mark-small.svg': mark_small(ide=True),
    'hmg5-logo.svg': lockup(),
    'hmg5-logo-dark.svg': lockup(dark=True),
    'hmg5-ide-logo.svg': lockup(ide=True),
    'hmg5-ide-logo-dark.svg': lockup(ide=True, dark=True),
}

if __name__ == '__main__':
    for name, text in FILES.items():
        with open(os.path.join(HERE, name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        print(name)
