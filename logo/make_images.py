"""HMG5 logos as images (python logo/make_images.py, after make_logos.py).

Renders the SVGs with Microsoft Edge (headless) and writes:
  logo/hmg5.ico, logo/hmg5-ide.ico          16-256 px (16-32 from the *-small marks)
  logo/png/*.png                            the logos at a few sizes
  SOURCE/IDE_SourceCode/Resource/HMG-UNICODE_icon.ico, HMG-ANSI_icon.ico   the IDE's icon
  SOURCE/IDE_SourceCode/Resource/HMG-UNICODE.bmp, HMG-ANSI.bmp             the IDE's splash

The splash window makes pure white transparent (CreateScreenSplash), so the white
inside the logo is drawn as (254,254,254).
"""
import os, subprocess, tempfile, shutil
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RES = os.path.join(ROOT, 'SOURCE', 'IDE_SourceCode', 'Resource')
EDGE = next(p for p in [r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
                        r'C:\Program Files\Microsoft\Edge\Application\msedge.exe'] if os.path.exists(p))
TMP = tempfile.mkdtemp(prefix='hmg5logo')


def render(svg, w, h, bg=None, extra=''):
    """svg file -> RGBA image w x h (transparent background unless bg)"""
    html = os.path.join(TMP, 'r.html')
    out = os.path.join(TMP, 'r.png')
    with open(html, 'w', encoding='utf-8') as f:
        f.write('<!doctype html><html><head><style>html,body{margin:0;padding:0;overflow:hidden;background:%s}'
                'img{display:block}</style></head><body>%s<img src="file:///%s" width="%d" height="%d"></body></html>'
                % (bg or 'transparent', extra, os.path.join(HERE, svg).replace('\\', '/'), w, h))
    if os.path.exists(out):
        os.remove(out)
    subprocess.run([EDGE, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
                    '--force-device-scale-factor=1', '--default-background-color=00000000',
                    '--user-data-dir=' + os.path.join(TMP, 'edge'), '--screenshot=' + out,
                    '--window-size=%d,%d' % (w, h), 'file:///' + html.replace('\\', '/')],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
    return Image.open(out).convert('RGBA').crop((0, 0, w, h))


def ico(big, small, path):
    sizes = [16, 20, 24, 32, 40, 48, 64, 128, 256]
    imgs = []
    for s in sizes:
        src = small if s <= 32 else big
        imgs.append(render(src, s * 4, s * 4).resize((s, s), Image.LANCZOS) if s < 64 else render(src, s, s))
    imgs[-1].save(path, format='ICO', sizes=[(s, s) for s in sizes], append_images=imgs[:-1])   # each size its own frame
    print(path)


def splash(variant, path):
    """the IDE logo on a light card, 480 x 168 (shown 1:1 by CreateScreenSplash)"""
    W, H = 480, 168
    k = 2                       # rendered at 3x, then reduced
    from xml.dom import minidom
    d = minidom.parse(os.path.join(HERE, 'hmg5-ide-logo.svg')).documentElement
    lw, lh = int(d.getAttribute('width')), int(d.getAttribute('height'))
    th = int(116 * k)            # logo height on the card
    tw = int(lw * th / lh)
    logo = render('hmg5-ide-logo.svg', tw, th)
    card = Image.new('RGBA', (W * k, H * k), (255, 255, 255, 255))
    mask = Image.new('L', card.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, W * k - 1, H * k - 1), radius=18 * k, fill=255)
    face = Image.new('RGBA', card.size, (248, 250, 255, 255))
    ImageDraw.Draw(face).rounded_rectangle((k, k, W * k - 1 - k, H * k - 1 - k), radius=17 * k,
                                           outline=(214, 222, 240, 255), width=2 * k)
    face.alpha_composite(logo, ((W * k - tw) // 2, 16 * k))
    dr = ImageDraw.Draw(face)
    try:
        from PIL import ImageFont
        font = ImageFont.truetype('segoeui.ttf', 15 * k)
    except OSError:
        font = None
    label = variant + '  \u00b7  64-bit'
    tw2 = dr.textlength(label, font=font)
    dr.text(((W * k - tw2) / 2, (H - 32) * k), label, fill=(91, 103, 133, 255), font=font)
    card.paste(face, (0, 0), mask)
    img = card.convert('RGB').resize((W, H), Image.LANCZOS)
    # pure white is the splash window's transparent colour: only outside the card
    px = img.load()
    m = mask.resize((W, H), Image.LANCZOS).load()
    for y in range(H):
        for x in range(W):
            if m[x, y] >= 250 and px[x, y] == (255, 255, 255):
                px[x, y] = (254, 254, 254)
            elif m[x, y] < 250:
                px[x, y] = (255, 255, 255) if m[x, y] < 128 else px[x, y]
    img.save(path, format='BMP')
    print(path)


if __name__ == '__main__':
    os.makedirs(os.path.join(HERE, 'png'), exist_ok=True)
    for svg, h in [('hmg5-mark.svg', 512), ('hmg5-ide-mark.svg', 512), ('hmg5-mark-small.svg', 64),
                   ('hmg5-ide-mark-small.svg', 64), ('hmg5-logo.svg', 320), ('hmg5-ide-logo.svg', 320),
                   ('hmg5-logo-dark.svg', 320), ('hmg5-ide-logo-dark.svg', 320)]:
        from xml.dom import minidom
        d = minidom.parse(os.path.join(HERE, svg)).documentElement
        w = int(int(d.getAttribute('width')) * h / int(d.getAttribute('height')))
        out = os.path.join(HERE, 'png', svg.replace('.svg', '.png'))
        render(svg, w, h).save(out)
        print(out)
    ico('hmg5-mark.svg', 'hmg5-mark-small.svg', os.path.join(HERE, 'hmg5.ico'))
    ico('hmg5-ide-mark.svg', 'hmg5-ide-mark-small.svg', os.path.join(HERE, 'hmg5-ide.ico'))
    for name in ('HMG-UNICODE_icon.ico', 'HMG-ANSI_icon.ico'):
        shutil.copyfile(os.path.join(HERE, 'hmg5-ide.ico'), os.path.join(RES, name))
        print(os.path.join(RES, name))
    splash('Unicode', os.path.join(RES, 'HMG-UNICODE.bmp'))
    splash('ANSI', os.path.join(RES, 'HMG-ANSI.bmp'))
    shutil.rmtree(TMP, ignore_errors=True)
