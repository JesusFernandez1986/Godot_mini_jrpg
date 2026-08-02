#!/usr/bin/env python3
"""Repack the legacy seven-row party sheet into a strict eight-direction atlas.

The source artwork contains connected sprites that cross its nominal 128 px grid.
This tool extracts each connected opaque figure, keeps its pixels unchanged, and
centres it in a non-overlapping 160 px directional row. The missing southeast
row is derived by mirroring southwest.
"""

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "party_animation_atlas.png"
OUTPUT = ROOT / "assets" / "party_animation_atlas_v2.png"
BLOCK_WIDTH = 384
ROW_HEIGHT = 160
CHARACTER_COLUMNS = (3, 2, 2, 2)
SOURCE_TO_DESTINATION_ROWS = (0, 1, 2, 3, 5, 6, 4)


def connected_components(alpha: np.ndarray) -> tuple[np.ndarray, list[dict]]:
    opaque = alpha > 5
    height, width = opaque.shape
    labels = np.zeros((height, width), dtype=np.int16)
    components: list[dict] = []
    component_id = 0
    for y in range(height):
        for x in range(width):
            if not opaque[y, x] or labels[y, x] != 0:
                continue
            component_id += 1
            labels[y, x] = component_id
            queue = deque([(y, x)])
            min_x = max_x = x
            min_y = max_y = y
            size = 0
            while queue:
                current_y, current_x = queue.pop()
                size += 1
                min_x = min(min_x, current_x)
                max_x = max(max_x, current_x)
                min_y = min(min_y, current_y)
                max_y = max(max_y, current_y)
                for offset_y, offset_x in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    next_y = current_y + offset_y
                    next_x = current_x + offset_x
                    if 0 <= next_y < height and 0 <= next_x < width and opaque[next_y, next_x] and labels[next_y, next_x] == 0:
                        labels[next_y, next_x] = component_id
                        queue.append((next_y, next_x))
            if size > 500:
                components.append({"label": component_id, "size": size, "box": (min_x, min_y, max_x + 1, max_y + 1), "center_y": (min_y + max_y) / 2.0})
    return labels, components


def group_rows(components: list[dict]) -> list[list[dict]]:
    rows: list[list[dict]] = []
    for component in sorted(components, key=lambda item: item["center_y"]):
        if not rows:
            rows.append([component])
            continue
        row_center = sum(item["center_y"] for item in rows[-1]) / len(rows[-1])
        if abs(component["center_y"] - row_center) < 60:
            rows[-1].append(component)
        else:
            rows.append([component])
    return rows


def isolated_crop(source: np.ndarray, labels: np.ndarray, component: dict) -> Image.Image:
    left, top, right, bottom = component["box"]
    pixels = source[top:bottom, left:right].copy()
    selected = labels[top:bottom, left:right] == component["label"]
    pixels[:, :, 3] = np.where(selected, pixels[:, :, 3], 0)
    return Image.fromarray(pixels, "RGBA")


def paste_row(output: Image.Image, source: np.ndarray, labels: np.ndarray, components: list[dict], destination_row: int, mirror: bool = False) -> None:
    for character_index, columns in enumerate(CHARACTER_COLUMNS):
        block_left = character_index * BLOCK_WIDTH
        block_right = block_left + BLOCK_WIDTH
        character_components = sorted(
            [component for component in components if block_left <= (component["box"][0] + component["box"][2]) / 2.0 < block_right],
            key=lambda item: item["box"][0],
        )
        if len(character_components) != columns:
            raise RuntimeError(f"Expected {columns} frames for character {character_index}, found {len(character_components)}")
        cell_width = BLOCK_WIDTH // columns
        for frame_index, component in enumerate(character_components):
            sprite = isolated_crop(source, labels, component)
            if mirror:
                sprite = sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            if sprite.width > cell_width - 2 or sprite.height > ROW_HEIGHT - 2:
                raise RuntimeError(f"Sprite does not fit destination cell: character={character_index} frame={frame_index} size={sprite.size}")
            destination_x = block_left + frame_index * cell_width + (cell_width - sprite.width) // 2
            destination_y = destination_row * ROW_HEIGHT + ROW_HEIGHT - sprite.height - 2
            output.alpha_composite(sprite, (destination_x, destination_y))


def main() -> None:
    source_image = Image.open(SOURCE).convert("RGBA")
    source = np.asarray(source_image)
    labels, components = connected_components(source[:, :, 3])
    rows = group_rows(components)
    if len(rows) != 7 or any(len(row) != 9 for row in rows):
        raise RuntimeError(f"Unexpected source layout: row sizes={[len(row) for row in rows]}")
    output = Image.new("RGBA", (source_image.width, ROW_HEIGHT * 8), (0, 0, 0, 0))
    for source_row, destination_row in enumerate(SOURCE_TO_DESTINATION_ROWS):
        paste_row(output, source, labels, rows[source_row], destination_row)
    paste_row(output, source, labels, rows[1], 7, mirror=True)
    output.save(OUTPUT)
    print(f"Repacked {len(components)} sprites into {OUTPUT} ({output.width}x{output.height})")


if __name__ == "__main__":
    main()
