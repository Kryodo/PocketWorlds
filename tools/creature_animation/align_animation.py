#!/usr/bin/env python3
"""Normalize Qwen creature frames to a fixed canvas and ground pivot."""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parents[1]
CONFIG_PATH = HERE / "forest_drake_walk_v1.json"


def load_config():
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def rgb_distance(a, b):
    return math.sqrt(sum((float(a[i]) - float(b[i])) ** 2 for i in range(3)))


def remove_uniform_matte(image: Image.Image, config: dict, key_color=None) -> Image.Image:
    """Remove a genuinely uniform corner matte; reject patchy backgrounds safely."""
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    if alpha.getextrema() != (255, 255):
        return image

    pixels = image.load()
    w, h = image.size
    inset = max(2, min(w, h) // 128)
    samples = [
        pixels[inset, inset][:3],
        pixels[w - inset - 1, inset][:3],
        pixels[inset, h - inset - 1][:3],
        pixels[w - inset - 1, h - inset - 1][:3],
    ]

    if key_color:
        key = tuple(int(key_color.lstrip("#")[i:i+2], 16) for i in (0, 2, 4))
    else:
        spread = max(rgb_distance(a, b) for a in samples for b in samples)
        max_spread = config["chroma_key"]["max_corner_spread"]
        if spread > max_spread:
            raise ValueError(
                f"Non-uniform background detected (corner spread {spread:.1f} > {max_spread}). "
                "Extract alpha in ComfyUI with the PixelPro matte/decontaminate nodes, "
                "then run this tool on the transparent PNG; or pass --key-color explicitly."
            )
        key = tuple(round(sum(sample[c] for sample in samples) / len(samples))
                    for c in range(3))

    hard = float(config["chroma_key"]["hard_distance"])
    soft = float(config["chroma_key"]["soft_distance"])
    rgba = np.asarray(image, dtype=np.uint8).copy()
    rgb = rgba[:, :, :3].astype(np.float32)
    key_array = np.asarray(key, dtype=np.float32)
    distance = np.sqrt(np.sum((rgb - key_array) ** 2, axis=2))

    alpha_values = np.clip((distance - hard) / max(soft - hard, 1.0), 0.0, 1.0)
    rgba[:, :, 3] = np.rint(alpha_values * 255.0).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def load_rgba(path: Path, config: dict, key_color=None):
    image = Image.open(path).convert("RGBA")
    return remove_uniform_matte(image, config, key_color)


def crop_sheet_frames(image: Image.Image, columns: int, rows: int):
    w, h = image.size
    if w % columns or h % rows:
        raise ValueError(
            f"Sheet dimensions {w}x{h} are not divisible by the requested {columns}x{rows} layout."
        )
    cell_w, cell_h = w // columns, h // rows
    if cell_w != cell_h:
        raise ValueError(f"Expected square frame cells; got {cell_w}x{cell_h}.")
    return [
        image.crop((col * cell_w, row * cell_h,
                    (col + 1) * cell_w, (row + 1) * cell_h))
        for row in range(rows) for col in range(columns)
    ]


def load_offset_overrides(path: Path | None):
    overrides = {}
    if path is None or not path.exists():
        return overrides
    with path.open("r", newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            index = int(row["frame"])
            overrides[index] = (
                int(float(row.get("manual_dx", 0) or 0)),
                int(float(row.get("manual_dy", 0) or 0)),
            )
    return overrides


def resize_to_cell(frame: Image.Image, frame_size: int):
    if frame.width != frame.height:
        raise ValueError(f"Frame must be square; got {frame.size}.")
    if frame.size != (frame_size, frame_size):
        frame = frame.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
    return frame


def translated_mask(mask: np.ndarray, dx: int, dy: int) -> np.ndarray:
    height, width = mask.shape
    result = np.zeros_like(mask, dtype=bool)
    src_x0 = max(0, -dx)
    src_x1 = min(width, width - dx)
    src_y0 = max(0, -dy)
    src_y1 = min(height, height - dy)
    dst_x0, dst_x1 = src_x0 + dx, src_x1 + dx
    dst_y0, dst_y1 = src_y0 + dy, src_y1 + dy
    if src_x1 > src_x0 and src_y1 > src_y0:
        result[dst_y0:dst_y1, dst_x0:dst_x1] = mask[src_y0:src_y1, src_x0:src_x1]
    return result


def registration_score(reference_mask: np.ndarray, candidate_mask: np.ndarray,
                       roi: tuple[int, int, int, int], dx: int, dy: int) -> float:
    shifted = translated_mask(candidate_mask, dx, dy)
    x1, y1, x2, y2 = roi
    ref = reference_mask[y1:y2, x1:x2]
    cur = shifted[y1:y2, x1:x2]
    intersection = int(np.logical_and(ref, cur).sum())
    denominator = int(ref.sum() + cur.sum())
    if denominator == 0:
        return 0.0
    return (2.0 * intersection) / denominator


def find_body_alignment(reference: Image.Image, frame: Image.Image,
                        config: dict, enabled: bool = True):
    if not enabled:
        return 0, 0, 1.0

    threshold = int(config["registration_alpha_threshold"])
    ref_mask = np.asarray(reference.getchannel("A"), dtype=np.uint8) >= threshold
    cur_mask = np.asarray(frame.getchannel("A"), dtype=np.uint8) >= threshold
    roi = tuple(int(value) for value in config["body_registration_roi_px"])
    radius = int(config["registration_search_radius_px"])

    best = (0, 0, -1.0)
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            score = registration_score(ref_mask, cur_mask, roi, dx, dy)
            if score > best[2]:
                best = (dx, dy, score)
    return best


def shift_image(image: Image.Image, dx: int, dy: int):
    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    output.alpha_composite(image, (dx, dy))
    return output


def create_preview(frames, config, output_path: Path, columns: int):
    frame_size = config["output_frame_px"][0]
    rows = math.ceil(len(frames) / columns)
    pad = 14
    label_h = 24
    canvas = Image.new(
        "RGB",
        (columns * (frame_size + pad) + pad,
         rows * (frame_size + label_h + pad) + pad),
        "#26332d"
    )
    draw = ImageDraw.Draw(canvas)

    pivot_x, pivot_y = config["target_pivot_px"]
    shadow_offset = config["source_contact_shadow_offset_px"]
    source_w = config["source_canvas_px"][0]
    scale = frame_size / source_w
    shadow_x = pivot_x + shadow_offset[0] * scale
    shadow_y = pivot_y + shadow_offset[1] * scale
    for index, frame in enumerate(frames):
        col, row = index % columns, index // columns
        x = pad + col * (frame_size + pad)
        y = pad + row * (frame_size + label_h + pad)
        checker = Image.new("RGB", frame.size, "#7e897f")
        checker_draw = ImageDraw.Draw(checker)
        for cy in range(0, frame_size, 16):
            for cx in range(0, frame_size, 16):
                if (cx // 16 + cy // 16) % 2:
                    checker_draw.rectangle((cx, cy, cx+15, cy+15), fill="#68766c")
        checker.paste(frame.convert("RGB"), (0, 0), frame.getchannel("A"))
        canvas.paste(checker, (x, y))

        px, py = x + pivot_x, y + pivot_y
        sx, sy = x + shadow_x, y + shadow_y
        draw.ellipse((sx-56, sy-28, sx+56, sy+28), outline="#43d2ac", width=2)
        draw.line((px-10, py, px+10, py), fill="#ff5858", width=2)
        draw.line((px, py-10, px, py+10), fill="#ff5858", width=2)
        draw.text((x+4, y+frame_size+4), f"FRAME {index:02d}", fill="#f1ead9")

    canvas.save(output_path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--sheet", type=Path, help="Qwen sprite sheet (for example 1024x1024, 4x4).")
    source.add_argument("--frames-dir", type=Path, help="Folder of individual PNG frames.")
    parser.add_argument("--layout", default="4x4", help="Sheet columns x rows. Default: 4x4.")
    parser.add_argument("--out", type=Path, required=True, help="Output folder.")
    parser.add_argument("--reference", type=Path, default=None, help="Override the approved master reference PNG.")
    parser.add_argument("--key-color", default=None, help="Explicit matte color, e.g. #D632E8.")
    parser.add_argument("--offsets", type=Path, default=None, help="Optional CSV with manual_dx/manual_dy corrections.")
    parser.add_argument("--no-auto-register", action="store_true", help="Keep input canvas positions; do not body-register.")
    args = parser.parse_args()

    config = load_config()
    frame_size = int(config["output_frame_px"][0])
    output_dir = args.out.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.sheet:
        try:
            columns, rows = (int(part) for part in args.layout.lower().split("x", 1))
        except Exception as exc:
            raise SystemExit("--layout must look like 4x4 or 2x2.") from exc
        sheet = load_rgba(args.sheet, config, args.key_color)
        raw_frames = crop_sheet_frames(sheet, columns, rows)
    else:
        frame_paths = sorted(
            p for p in args.frames_dir.iterdir()
            if p.is_file() and p.suffix.lower() in (".png", ".webp")
        )
        if not frame_paths:
            raise SystemExit(f"No PNG/WebP frames found in {args.frames_dir}.")
        raw_frames = [load_rgba(path, config, args.key_color) for path in frame_paths]
        columns = min(config["output_sheet_columns"], len(raw_frames))

    reference_path = args.reference or (PROJECT_ROOT / config["source_reference"])
    if not reference_path.exists():
        raise SystemExit(f"Master reference not found: {reference_path}")
    reference = load_rgba(reference_path, config, args.key_color)
    reference = resize_to_cell(reference, frame_size)

    target_pivot_x, target_pivot_y = config["target_pivot_px"]
    overrides = load_offset_overrides(args.offsets)
    aligned_frames = []
    reports = []

    for index, raw in enumerate(raw_frames):
        frame = resize_to_cell(raw, frame_size)
        dx, dy, score = find_body_alignment(
            reference, frame, config, enabled=not args.no_auto_register
        )
        manual_dx, manual_dy = overrides.get(index, (0, 0))
        final_dx, final_dy = dx + manual_dx, dy + manual_dy
        aligned = shift_image(frame, final_dx, final_dy)
        aligned_frames.append(aligned)
        reports.append({
            "frame": index,
            "auto_dx": dx,
            "auto_dy": dy,
            "manual_dx": manual_dx,
            "manual_dy": manual_dy,
            "final_dx": final_dx,
            "final_dy": final_dy,
            "body_registration_dice": round(score, 4),
            "registration_warning": score < 0.42,
        })
        if score < 0.42:
            print(f"[WARN] Frame {index:02d}: weak body registration (Dice {score:.3f}); inspect preview.")

    frames_dir = output_dir / "frames"
    frames_dir.mkdir(exist_ok=True)
    for index, frame in enumerate(aligned_frames):
        frame.save(frames_dir / f"frame_{index:02d}.png")

    sheet_columns = int(config["output_sheet_columns"])
    sheet_rows = math.ceil(len(aligned_frames) / sheet_columns)
    assembled = Image.new(
        "RGBA",
        (sheet_columns * frame_size, sheet_rows * frame_size),
        (0, 0, 0, 0)
    )
    for index, frame in enumerate(aligned_frames):
        assembled.alpha_composite(
            frame,
            ((index % sheet_columns) * frame_size,
             (index // sheet_columns) * frame_size)
        )
    sheet_name = f"ForestDrake_Walk_{len(aligned_frames):02d}_Aligned.png"
    assembled.save(output_dir / sheet_name)

    create_preview(
        aligned_frames, config,
        output_dir / "alignment_preview.png",
        sheet_columns
    )

    offsets_path = output_dir / "alignment_offsets.csv"
    with offsets_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["frame", "auto_dx", "auto_dy", "manual_dx",
                        "manual_dy", "final_dx", "final_dy",
                        "body_registration_dice", "registration_warning"]
        )
        writer.writeheader()
        writer.writerows(reports)

    report = {
        "workflow_version": 1,
        "frame_count": len(aligned_frames),
        "output_frame_px": frame_size,
        "target_pivot_px": [target_pivot_x, target_pivot_y],
        "registration_roi_px": config["body_registration_roi_px"],
        "automatic_registration_enabled": not args.no_auto_register,
        "source": str(args.sheet or args.frames_dir),
        "outputs": [sheet_name, "alignment_preview.png", "alignment_offsets.csv", "frames/"],
        "frames": reports
    }
    (output_dir / "alignment_report.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )
    print(f"[OK] Aligned {len(aligned_frames)} frames into {output_dir}")
    print(f"[OK] Preview: {output_dir / 'alignment_preview.png'}")
    print(f"[OK] Report: {output_dir / 'alignment_report.json'}")
    print("[NOTE] Review low Dice scores and the preview before importing the sheet into Godot.")


if __name__ == "__main__":
    main()
