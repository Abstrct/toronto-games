"""Indexed sprite sheets (16 tiles wide) with named objects that become
metasprite tables for oam_meta.

    sh = Sheet(128)
    d = sh.draw()               # ImageDraw on a 'P' image; fill = colour index
    sh.obj('car', 0, 32, 32, 48)
    open(...).write(sh.tiles()); sh.meta_inc('bike') -> asm text
Each object is cut into 16x16 pieces (8x8 at ragged edges), empty pieces
skipped. Piece tiles are stored relative to MS_<NAME>_BASE."""
from PIL import Image, ImageDraw
from snes import tile_bytes


class Sheet:
    def __init__(self, height):
        assert height % 8 == 0
        self.img = Image.new('P', (128, height), 0)
        self.objects = []

    def draw(self):
        return ImageDraw.Draw(self.img)

    def px(self, x, y, c):
        self.img.putpixel((x, y), c)

    def ascii(self, x, y, rows, cmap):
        for yy, r in enumerate(rows):
            for xx, ch in enumerate(r):
                if ch in cmap:
                    self.img.putpixel((x + xx, y + yy), cmap[ch])

    def outline(self, x, y, w, h, col=1):
        """1px outline (colour col) around the non-zero pixels of a region."""
        src = self.img.crop((x, y, x + w, y + h))
        p = src.load()
        for yy in range(h):
            for xx in range(w):
                if p[xx, yy] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        sx, sy = xx + dx, yy + dy
                        if 0 <= sx < w and 0 <= sy < h and p[sx, sy] not in (0, col):
                            self.img.putpixel((x + xx, y + yy), col)
                            break

    def mirror(self, sx, sy, w, h, dx, dy):
        """Copy a region horizontally mirrored."""
        reg = self.img.crop((sx, sy, sx + w, sy + h)).transpose(Image.FLIP_LEFT_RIGHT)
        self.img.paste(reg, (dx, dy))

    def copy(self, sx, sy, w, h, dx, dy):
        reg = self.img.crop((sx, sy, sx + w, sy + h))
        self.img.paste(reg, (dx, dy))

    def obj(self, name, x, y, w, h, ax=None, ay=None):
        assert x % 8 == 0 and y % 8 == 0 and w % 8 == 0 and h % 8 == 0, name
        self.objects.append((name, x, y, w, h, w // 2 if ax is None else ax, h // 2 if ay is None else ay))

    def tiles(self):
        w, h = self.img.size
        p = self.img.load()
        data = bytearray()
        for ty in range(h // 8):
            for tx in range(16):
                pix = [p[tx * 8 + x, ty * 8 + y] & 15 for y in range(8) for x in range(8)]
                data += tile_bytes(pix, 4)
        return bytes(data)

    def _empty(self, x, y, w, h):
        p = self.img.load()
        return all(p[x + i, y + j] == 0 for j in range(h) for i in range(w))

    def meta_inc(self):
        lines = []
        for (name, x, y, w, h, ax, ay) in self.objects:
            base = (y // 8) * 16 + x // 8
            pieces = []
            for py in range(0, h, 16):
                for px_ in range(0, w, 16):
                    if px_ + 16 <= w and py + 16 <= h:
                        if not self._empty(x + px_, y + py, 16, 16):
                            pieces.append((px_, py, 1))
                    else:
                        for sy in range(py, min(py + 16, h), 8):
                            for sx in range(px_, min(px_ + 16, w), 8):
                                if not self._empty(x + sx, y + sy, 8, 8):
                                    pieces.append((sx, sy, 0))
            lines.append('MS_%s_BASE = %d' % (name.upper(), base))
            lines.append('ms_%s:' % name)
            for (px_, py, size) in pieces:
                t = ((y + py) // 8) * 16 + (x + px_) // 8 - base
                assert 0 <= t < 256
                dx = (px_ - ax) & 0xFF
                dy = (py - ay) & 0xFF
                lines.append('    .byte $%02X, $%02X, $%02X, $00, %d' % (dx, dy, t, size))
            lines.append('    .byte $80')
        return '\n'.join(lines) + '\n'

    def preview(self, palette, path, scale=4):
        from snes import preview as pv
        img = self.img.copy()
        flat = []
        for c in palette:
            flat += list(c)
        flat += [0] * (768 - len(flat))
        img.putpalette(flat)
        pv(img.convert('RGB'), path, scale)


def render(sheet, region, palette, flipv=False, fliph=False):
    """RGBA image of a sheet region in a palette (list of RGB or hex)."""
    from snes import hexrgb
    x, y, w, h = region
    src = sheet.img.crop((x, y, x + w, y + h))
    pal = [hexrgb(c) if isinstance(c, str) else c for c in palette]
    out_ = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    sp = src.load()
    op = out_.load()
    for yy in range(h):
        for xx in range(w):
            v = sp[xx, yy]
            if v:
                op[xx, yy] = tuple(pal[v][:3]) + (255,)
    if flipv:
        out_ = out_.transpose(Image.FLIP_TOP_BOTTOM)
    if fliph:
        out_ = out_.transpose(Image.FLIP_LEFT_RIGHT)
    return out_
