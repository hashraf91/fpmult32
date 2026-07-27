#!/usr/bin/env python3
import argparse
import os
import subprocess
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

INPUT_DIR = PROJECT_ROOT / "out_images"
OUTPUT_DIR = PROJECT_ROOT / "out_pdfs"

DEFAULT_TARGET_WIDTH = 236


def build_gimp_pdf_command(input_path: Path, output_path: Path, target_width: int | None = DEFAULT_TARGET_WIDTH) -> str:
    in_str = str(input_path.resolve()).replace("\\", "/")
    out_str = str(output_path.resolve()).replace("\\", "/")

    if target_width is None:
        return (
            f'(let* ('
            f'    (image (car (gimp-file-load RUN-NONINTERACTIVE "{in_str}" "{in_str}"))) '
            f'    (drawable (car (gimp-image-flatten image)))'
            f') '
            f'  (file-pdf-save RUN-NONINTERACTIVE image drawable "{out_str}" "{out_str}" 0 0 0) '
            f'  (gimp-image-delete image)'
            f')'
        )

    return (
        f'(let* ('
        f'    (image (car (gimp-file-load RUN-NONINTERACTIVE "{in_str}" "{in_str}"))) '
        f'    (orig-w (car (gimp-image-width image))) '
        f'    (orig-h (car (gimp-image-height image))) '
        f'    (new-w {target_width}) '
        f'    (new-h (/ (* orig-h new-w) orig-w)) '
        f') '
        f'  (gimp-image-scale image new-w new-h) '
        f'  (let* ('
        f'      (drawable (car (gimp-image-flatten image)))'
        f'  ) '
        f'    (file-pdf-save RUN-NONINTERACTIVE image drawable "{out_str}" "{out_str}" 0 0 0)'
        f'  ) '
        f'  (gimp-image-delete image)'
        f')'
    )


def convert_one_image(img_path_str: str, output_dir_str: str, target_width: int | None):
    img_path = Path(img_path_str)
    output_dir = Path(output_dir_str)
    pdf_path = output_dir / f"{img_path.stem}.pdf"

    expr = build_gimp_pdf_command(img_path, pdf_path, target_width)
    cmd = [
        "gimp",
        "-i",
        "-b", expr,
        "-b", "(gimp-quit 0)",
    ]

    subprocess.run(cmd, check=True)
    return img_path.name, pdf_path.name


def main(max_workers: int = 16, target_width: int | None = DEFAULT_TARGET_WIDTH):
    os.environ.setdefault("OMP_NUM_THREADS", "1")
    os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
    os.environ.setdefault("MKL_NUM_THREADS", "1")
    os.environ.setdefault("NUMEXPR_NUM_THREADS", "1")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    image_files = sorted([
        p for p in INPUT_DIR.iterdir()
        if p.suffix.lower() in {".hdr", ".exr"}
    ])

    if not image_files:
        print(f"No .hdr/.exr files found in {INPUT_DIR}")
        return

    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(convert_one_image, str(img_path), str(OUTPUT_DIR), target_width): img_path
            for img_path in image_files
        }

        for future in as_completed(futures):
            img_path = futures[future]
            try:
                src_name, dst_name = future.result()
                print(f"Converted: {src_name} -> {dst_name}")
            except Exception as e:
                print(f"ERROR converting {img_path.name}: {e}")

    print(f"\nDone. PDFs saved in: {OUTPUT_DIR}")
    if target_width is None:
        print("Mode: full-size PDF conversion")
    else:
        print(f"Mode: scaled PDF conversion (target width = {target_width}px)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Convert .hdr/.exr images from SW/out_images to PDFs using GIMP."
    )
    parser.add_argument(
        "--max-workers",
        type=int,
        default=16,
        help="Number of parallel worker processes (default: 16)"
    )
    parser.add_argument(
        "--target-width",
        type=int,
        default=DEFAULT_TARGET_WIDTH,
        help=f"Target width in pixels for scaled PDF generation (default: {DEFAULT_TARGET_WIDTH})"
    )
    parser.add_argument(
        "--full-size",
        action="store_true",
        help="Disable scaling and generate full-size PDFs"
    )

    args = parser.parse_args()

    target_width = None if args.full_size else args.target_width
    main(max_workers=args.max_workers, target_width=target_width)
