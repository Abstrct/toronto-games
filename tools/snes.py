"""SNES graphics helpers: palettes, 2bpp/4bpp tiles, de-duplicated tilemaps,
sprite sheets. Images are PIL RGBA; alpha 0 means transparent (colour 0)."""
import os
from PIL import Image

BUILD = os.path.join(os.path.dirname(__file__), '..', 'build')


def out(path, data):
    full = os.path.join(BUILD, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'wb') as f:
        f.write(bytes(data))
    return len(data)


def hexrgb(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def snap(c):
    """Round an RGB colour to what the SNES can show (5 bits per channel)."""
    return tuple((v >> 3) << 3 for v in c[:3])


def bgr555(c):
    r, g, b = (v >> 3 for v in c[:3])
    return r | (g << 5) | (b << 10)


def pal_bytes(colours, count=None):
    cols = list(colours)
    if count:
        cols += [(0, 0, 0)] * (count - len(cols))
    data = bytearray()
    for c in cols:
        w = bgr555(c)
        data += bytes((w & 0xFF, w >> 8))
    return data


def tile_bytes(pix, bpp):
    """pix: 64 colour indices, row major -> SNES planar tile."""
    data = bytearray(8 * bpp)
    for y in range(8):
        for x in range(8):
            v = pix[y * 8 + x]
            bit = 7 - x
            for p in range(bpp):
                if v & (1 << p):
                    off = (p // 2) * 16 + y * 2 + (p & 1)
                    data[off] |= 1 << bit
    return bytes(data)


def _flip(pix, h, v):
    out_ = [0] * 64
    for y in range(8):
        for x in range(8):
            sx = 7 - x if h else x
            sy = 7 - y if v else y
            out_[y * 8 + x] = pix[sy * 8 + sx]
    return tuple(out_)


class TileSet:
    """Accumulates unique tiles (flip-aware) for one BG character area."""

    def __init__(self, bpp=4, base=0, reserve_blank=True):
        self.bpp = bpp
        self.base = base
        self.tiles = []
        self.index = {}
        if reserve_blank:
            self.add(tuple([0] * 64))

    def add(self, pix, allow_flip=True):
        pix = tuple(pix)
        if pix in self.index:
            return self.index[pix], False, False
        if allow_flip:
            for h, v in ((True, False), (False, True), (True, True)):
                f = _flip(pix, h, v)
                if f in self.index:
                    return self.index[f], h, v
        i = len(self.tiles)
        self.tiles.append(pix)
        self.index[pix] = i
        return i, False, False

    def data(self):
        return b''.join(tile_bytes(t, self.bpp) for t in self.tiles)

    def __len__(self):
        return len(self.tiles)


def rgba_pixels(img):
    img = img.convert('RGBA')
    return img, img.load()


def tile_colours(px, tx, ty):
    cols = set()
    for y in range(8):
        for x in range(8):
            c = px[tx * 8 + x, ty * 8 + y]
            if c[3] >= 128:
                cols.add(snap(c))
    return cols


def build_palettes(img, max_pals, fixed=None):
    """Greedy palette packing: each 8x8 tile's colours must fit one palette of
    15 colours. Returns list of palettes (lists of RGB, index 0 = transparent)."""
    img, px = rgba_pixels(img)
    w, h = img.size
    sets = []
    for ty in range(h // 8):
        for tx in range(w // 8):
            s = frozenset(tile_colours(px, tx, ty))
            if s:
                sets.append(s)
    # biggest sets first
    uniq = sorted(set(sets), key=lambda s: -len(s))
    pals = [set(p) for p in (fixed or [])]
    for s in uniq:
        if any(s <= p for p in pals):
            continue
        best = None
        for p in pals:
            u = p | s
            if len(u) <= 15 and (best is None or len(u) < len(best | s)):
                best = p
        if best is not None:
            best |= s
        else:
            if len(s) > 15:
                raise ValueError('tile with %d colours' % len(s))
            pals.append(set(s))
    if len(pals) > max_pals:
        raise ValueError('need %d palettes, have %d' % (len(pals), max_pals))
    result = []
    for p in pals:
        cols = sorted(p, key=lambda c: (c[0] * 3 + c[1] * 6 + c[2]))
        result.append([(0, 0, 0)] + cols)
    return result


def convert_bg(img, palettes, pal_first, tileset, priority=False, allow_flip=True):
    """Convert an RGBA image to tilemap words using per-tile palette choice.
    Returns 2D list [ty][tx] of 16-bit map entries."""
    img, px = rgba_pixels(img)
    w, h = img.size
    lookup = [{c: i for i, c in enumerate(p) if i > 0} for p in palettes]
    rows = []
    for ty in range(h // 8):
        row = []
        for tx in range(w // 8):
            cols = tile_colours(px, tx, ty)
            pi = None
            for i, lk in enumerate(lookup):
                if all(c in lk for c in cols):
                    pi = i
                    break
            if pi is None:
                raise ValueError('tile %d,%d colours %s fit no palette' % (tx, ty, cols))
            lk = lookup[pi]
            pix = []
            for y in range(8):
                for x in range(8):
                    c = px[tx * 8 + x, ty * 8 + y]
                    pix.append(lk[snap(c)] if c[3] >= 128 else 0)
            if not any(pix):
                idx, hf, vf = 0, False, False
            else:
                idx, hf, vf = tileset.add(pix, allow_flip)
            idx += tileset.base
            word = (idx & 0x3FF) | (((pal_first + pi) & 7) << 10)
            if priority:
                word |= 0x2000
            if hf:
                word |= 0x4000
            if vf:
                word |= 0x8000
            row.append(word)
        rows.append(row)
    return rows


def map_bytes(rows, screens_w=None):
    """Lay a [ty][tx] map out as SNES 32x32 screens (left-right, then down)."""
    h = len(rows)
    w = len(rows[0])
    sw = max(1, (w + 31) // 32)
    sh = max(1, (h + 31) // 32)
    if screens_w:
        sw = screens_w
    words = [0] * (sw * sh * 1024)
    for y in range(h):
        for x in range(w):
            scr = (y // 32) * sw + (x // 32)
            words[scr * 1024 + (y % 32) * 32 + (x % 32)] = rows[y][x]
    data = bytearray()
    for wd in words:
        data += bytes((wd & 0xFF, wd >> 8))
    return data


def raw_map_bytes(rows):
    """Row-major map, no screen split (for streaming rows/columns)."""
    data = bytearray()
    for row in rows:
        for wd in row:
            data += bytes((wd & 0xFF, wd >> 8))
    return data


def sheet_tiles(img, palette):
    """Sprite sheet (width 128) -> 4bpp tiles in VRAM order, one palette."""
    img, px = rgba_pixels(img)
    w, h = img.size
    assert w == 128, 'sprite sheets are 16 tiles wide'
    lk = {c: i for i, c in enumerate(palette) if i > 0}
    data = bytearray()
    for ty in range(h // 8):
        for tx in range(16):
            pix = []
            for y in range(8):
                for x in range(8):
                    c = px[tx * 8 + x, ty * 8 + y]
                    if c[3] < 128:
                        pix.append(0)
                    else:
                        s = snap(c)
                        if s not in lk:
                            raise ValueError('sprite colour %s not in palette (tile %d,%d)' % (s, tx, ty))
                        pix.append(lk[s])
            data += tile_bytes(pix, 4)
    return data


def sheet_tiles_multi(img, palettes):
    """Sprite sheet where each 8x8 tile may use any of several palettes
    (the metasprite picks the palette); colour index chosen per tile."""
    img, px = rgba_pixels(img)
    w, h = img.size
    assert w == 128
    lks = [{c: i for i, c in enumerate(p) if i > 0} for p in palettes]
    data = bytearray()
    for ty in range(h // 8):
        for tx in range(16):
            cols = tile_colours(px, tx, ty)
            lk = next((l for l in lks if all(c in l for c in cols)), None)
            if lk is None:
                raise ValueError('sprite tile %d,%d colours %s fit no palette' % (tx, ty, cols))
            pix = []
            for y in range(8):
                for x in range(8):
                    c = px[tx * 8 + x, ty * 8 + y]
                    pix.append(lk[snap(c)] if c[3] >= 128 else 0)
            data += tile_bytes(pix, 4)
    return data


def sprite_from_rows(rows, colours):
    """ASCII art -> RGBA image. colours maps chars to RGB; '.' is transparent."""
    h = len(rows)
    w = max(len(r) for r in rows)
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in colours:
                c = colours[ch]
                px[x, y] = tuple(c[:3]) + (255,)
    return img


def preview(img_rows_or_img, path, scale=3):
    full = os.path.join(BUILD, 'preview', path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    img = img_rows_or_img
    img.resize((img.width * scale, img.height * scale), Image.NEAREST).save(full)


def hdma_gradient(stops, name, height=224, step=2):
    """Mode-3 HDMA table writing CGRAM colour 0 every `step` lines.
    stops: [(y, '#rrggbb'), ...] ascending."""
    data = bytearray()
    y = 0
    while y < height:
        a, b = stops[0], stops[-1]
        for i in range(len(stops) - 1):
            if stops[i][0] <= y < stops[i + 1][0]:
                a, b = stops[i], stops[i + 1]
                break
        else:
            a = b = stops[-1] if y >= stops[-1][0] else stops[0]
        t = 0.0 if a is b else max(0.0, min(1.0, (y - a[0]) / max(1, b[0] - a[0])))
        ca, cb = hexrgb(a[1]), hexrgb(b[1])
        col = tuple(int(ca[k] + (cb[k] - ca[k]) * t) for k in range(3))
        w = bgr555(col)
        data += bytes((step, 0, 0, w & 0xFF, w >> 8))
        y += step
    data.append(0)
    out(name, data)
    return data
