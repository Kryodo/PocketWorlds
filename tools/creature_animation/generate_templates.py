#!/usr/bin/env python3
"""Generate fixed-canvas Forest Drake walking templates and Qwen pose guides."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parents[1]
CONFIG_PATH = HERE / "forest_drake_walk_v1.json"


def load_config() -> dict:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def cubic_points(p0, p1, p2, p3, count: int = 28):
    points = []
    for index in range(count + 1):
        t = index / count
        u = 1.0 - t
        x = (u**3 * p0[0] + 3 * u**2 * t * p1[0]
             + 3 * u * t**2 * p2[0] + t**3 * p3[0])
        y = (u**3 * p0[1] + 3 * u**2 * t * p1[1]
             + 3 * u * t**2 * p2[1] + t**3 * p3[1])
        points.append((round(x), round(y)))
    return points


def draw_joint(draw: ImageDraw.ImageDraw, point, radius: float, scale: float):
    x, y = point
    r = radius * scale
    draw.ellipse((x*scale-r, y*scale-r, x*scale+r, y*scale+r), fill="#111111")


def leg_pose(phase: float, stride: float, lift: float):
    """Return paw offset for one leg: backward stance, lifted forward swing."""
    phase %= 1.0
    if phase < 0.64:
        t = phase / 0.64
        return (stride * 0.5 - stride * t, 0.0)
    t = (phase - 0.64) / 0.36
    return (-stride * 0.5 + stride * t, -lift * math.sin(math.pi * t))


def draw_pose(draw: ImageDraw.ImageDraw, frame_index: int, frame_count: int,
              scale: float = 1.0, line_width: int = 3):
    """Draw a simplified three-quarter quadruped construction guide."""
    def line(points, width=line_width):
        draw.line([(x*scale, y*scale) for x, y in points],
                  fill="#111111", width=max(1, round(width * scale)), joint="curve")

    cycle = frame_index / max(frame_count, 1)
    legs = [
        {"hip": (111, 139), "knee": (99, 160), "paw": (89, 188),
         "phase": 0.00, "stride": 13, "lift": 10},
        {"hip": (126, 136), "knee": (121, 157), "paw": (132, 181),
         "phase": 0.50, "stride": 11, "lift": 8},
        {"hip": (160, 140), "knee": (170, 160), "paw": (182, 188),
         "phase": 0.25, "stride": 14, "lift": 10},
        {"hip": (174, 137), "knee": (183, 156), "paw": (194, 179),
         "phase": 0.75, "stride": 11, "lift": 8},
    ]

    tail = cubic_points((168, 143), (190, 143), (208, 156), (219, 178), 24)
    line(tail, line_width + 1)

    draw.ellipse((82*scale, 105*scale, 178*scale, 164*scale),
                 outline="#111111", width=max(1, round(line_width * scale)))
    line([(103, 128), (129, 137), (156, 140)], line_width + 1)

    line([(109, 128), (97, 116), (87, 111)], line_width + 1)
    draw.ellipse((57*scale, 78*scale, 111*scale, 126*scale),
                 outline="#111111", width=max(1, round(line_width * scale)))
    line([(62, 111), (48, 119), (58, 125)], line_width)
    line([(82, 82), (77, 67)], max(2, line_width - 1))
    line([(96, 85), (101, 70)], max(2, line_width - 1))

    line([(132, 117), (144, 96), (166, 104), (175, 126), (157, 145)], line_width)
    line([(145, 105), (158, 125), (166, 104)], max(2, line_width - 1))

    for leg in legs:
        offset_x, offset_y = leg_pose(
            cycle + leg["phase"], leg["stride"], leg["lift"]
        )
        hip = leg["hip"]
        base_knee = leg["knee"]
        base_paw = leg["paw"]
        paw = (base_paw[0] + offset_x, base_paw[1] + offset_y)
        knee = (base_knee[0] + offset_x * 0.35,
                base_knee[1] + offset_y * 0.48)
        line([hip, knee, paw], line_width + 1)
        draw_joint(draw, knee, 3.0, scale)
        line([paw, (paw[0] + 7, paw[1] + 1),
              (paw[0] + 11, paw[1] - 1)], line_width)
        line([paw, (paw[0] + 5, paw[1] + 4)], max(2, line_width - 1))
        draw_joint(draw, paw, 2.2, scale)


def build_pose_guide(config: dict, output_dir: Path, frame_count: int):
    frame_w, frame_h = config["output_frame_px"]
    columns = config["output_sheet_columns"]
    rows = math.ceil(frame_count / columns)
    sheet = Image.new("RGB", (columns * frame_w, rows * frame_h), "#FFFFFF")

    poses_dir = output_dir / f"poses_{frame_count:02d}"
    poses_dir.mkdir(parents=True, exist_ok=True)

    for index in range(frame_count):
        cell = Image.new("RGB", (frame_w, frame_h), "#FFFFFF")
        draw_pose(ImageDraw.Draw(cell), index, frame_count, 1.0, 1)
        sheet.paste(cell, ((index % columns) * frame_w,
                           (index // columns) * frame_h))

        large = Image.new("RGB", (1024, 1024), "#FFFFFF")
        draw_pose(ImageDraw.Draw(large), index, frame_count, 4.0, 2)
        large.save(poses_dir / f"pose_{index:02d}.png")

    sheet_path = output_dir / f"ForestDrake_Walk_ControlGuide_{frame_count:02d}.png"
    sheet.save(sheet_path)
    return sheet_path, poses_dir


def build_alignment_overlays(config: dict, output_dir: Path):
    frame_w, frame_h = config["output_frame_px"]
    pivot_x, pivot_y = config["target_pivot_px"]

    overlay = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.ellipse((pivot_x - 56, pivot_y - 28,
                  pivot_x + 56, pivot_y + 28),
                 outline=(70, 210, 170, 220), width=2)
    draw.line((pivot_x - 17, pivot_y, pivot_x + 17, pivot_y),
              fill=(255, 70, 70, 255), width=2)
    draw.line((pivot_x, pivot_y - 17, pivot_x, pivot_y + 17),
              fill=(255, 70, 70, 255), width=2)
    draw.ellipse((pivot_x - 4, pivot_y - 4,
                  pivot_x + 4, pivot_y + 4),
                 outline=(255, 255, 255, 255), width=1)
    overlay.save(output_dir / "ForestDrake_FrameAlignmentOverlay_256.png")

    large = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    large.alpha_composite(overlay.resize((1024, 1024), Image.Resampling.NEAREST))
    large.save(output_dir / "ForestDrake_CanvasPivotOverlay_1024.png")


def build_master_pivot_reference(config: dict, output_dir: Path):
    reference_path = PROJECT_ROOT / config["source_reference"]
    if not reference_path.exists():
        print(f"[WARN] Master reference not found: {reference_path}")
        return

    image = Image.open(reference_path).convert("RGBA")
    if image.size != tuple(config["source_canvas_px"]):
        print(f"[WARN] Master image is {image.size}; expected {config['source_canvas_px']}.")
    pivot_x, pivot_y = config["source_ground_pivot_px"]
    preview = image.copy()
    draw = ImageDraw.Draw(preview, "RGBA")
    draw.ellipse((pivot_x - 224, pivot_y - 112,
                  pivot_x + 224, pivot_y + 112),
                 outline=(70, 220, 170, 220), width=4)
    draw.line((pivot_x - 32, pivot_y, pivot_x + 32, pivot_y),
              fill=(255, 64, 64, 255), width=4)
    draw.line((pivot_x, pivot_y - 32, pivot_x, pivot_y + 32),
              fill=(255, 64, 64, 255), width=4)
    draw.ellipse((pivot_x - 8, pivot_y - 8,
                  pivot_x + 8, pivot_y + 8),
                 outline=(255, 255, 255, 255), width=2)
    preview.save(output_dir / "ForestDrake_MasterPivot_Reference.png")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=HERE / "generated" / "forest_drake_walk_v1")
    parser.add_argument("--frames", type=int, default=None, choices=(8, 16))
    args = parser.parse_args()

    config = load_config()
    output_dir = args.out.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    counts = [args.frames] if args.frames else [8, 16]

    build_alignment_overlays(config, output_dir)
    build_master_pivot_reference(config, output_dir)
    for count in counts:
        sheet_path, poses_dir = build_pose_guide(config, output_dir, count)
        print(f"[OK] {sheet_path}")
        print(f"[OK] {poses_dir}")

    print(f"[OK] Templates written to: {output_dir}")
    print("Use ControlGuide_16 for a 4x4 sheet, or poses_16/pose_XX.png for separate generations.")


if __name__ == "__main__":
    main()
