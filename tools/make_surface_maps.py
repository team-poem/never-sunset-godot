"""Bake original, seamless color and OpenGL tangent-space normal maps.

Uses only Python's standard library. Run from any directory to regenerate
assets/surfaces; no downloaded images or runtime texture generation required.
"""

import math
from pathlib import Path
import random
import struct
import zlib


SIZE = 256
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "surfaces"


def write_png(path, pixels):
    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data)))

    rows = b"".join(b"\0" + bytes(pixels[y * SIZE * 3:(y + 1) * SIZE * 3])
                    for y in range(SIZE))
    path.write_bytes(b"\x89PNG\r\n\x1a\n"
                     + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))


def bake(name, seed):
    rng = random.Random(seed)
    heights = []
    for y in range(SIZE):
        v = math.tau * y / SIZE
        for x in range(SIZE):
            u = math.tau * x / SIZE
            speckle = rng.uniform(-1, 1)
            if name == "wood":
                grain = 12 * u + 1.8 * math.sin(v) + 0.5 * math.sin(3 * v + u)
                height = 0.5 + 0.18 * math.sin(grain) + 0.06 * math.sin(3 * grain)
                height += 0.025 * speckle
            elif name == "plaster":
                height = 0.5 + 0.08 * math.sin(7 * u + math.sin(5 * v))
                height += 0.06 * math.sin(11 * v + 3 * u) + 0.07 * speckle
            else:
                # Soft glazed ripples; grout is already modeled in the scene.
                height = 0.5 + 0.08 * math.sin(2 * u + math.sin(v))
                height += 0.06 * math.cos(3 * v + u) + 0.012 * speckle
            heights.append(height)

    def sample(x, y):
        return heights[(y % SIZE) * SIZE + x % SIZE]

    color, normal = [], []
    strength = {"plaster": 1.2, "wood": 1.4, "tile": 0.7}[name]
    for y in range(SIZE):
        for x in range(SIZE):
            # Neutral albedo preserves the scene's existing material tint.
            shade = round(255 * (0.76 + 0.22 * sample(x, y)))
            color.extend((shade, shade, shade))
            nx = (sample(x - 1, y) - sample(x + 1, y)) * strength
            ny = (sample(x, y + 1) - sample(x, y - 1)) * strength
            length = math.sqrt(nx * nx + ny * ny + 1)
            normal.extend(round(255 * (component / length * 0.5 + 0.5))
                          for component in (nx, ny, 1))
    write_png(OUTPUT / f"{name}_color.png", color)
    write_png(OUTPUT / f"{name}_normal.png", normal)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for surface, seed in [("plaster", 104), ("wood", 1504), ("tile", 1994)]:
        bake(surface, seed)
