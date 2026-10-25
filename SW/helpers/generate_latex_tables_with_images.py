#!/usr/bin/env python3
import math
import re
from pathlib import Path

import pandas as pd

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

SUMMARY_CSV = PROJECT_ROOT / "out_images" / "summary.csv"
PDF_DIR = PROJECT_ROOT / "out_pdfs"
OUTPUT_TEX = PROJECT_ROOT / "out_images" / "results_per_application_with_images_longtable.tex"

IMAGES_PER_TABLE = 4
IMAGE_WIDTH = "2.0cm"

MODEL_DISPLAY_NAMES = {
    "viv_acc": "Exact",
    "lxa": "LxA",
    "mxa1": "MxA1",
    "mxa2": "MxA2",
    "ssm_m12": "SSM(12)",
    "ssm_m12c": "SSM(12c)",
    "ssm_m18": "SSM(18)",
    "ssm_m18c": "SSM(18c)",
    "lmul": "L-Mul",
}

MODEL_ORDER = [
    "viv_acc",
    "lxa",
    "mxa1",
    "mxa2",
    "ssm_m18c",
    "ssm_m18",
    "ssm_m12c",
    "ssm_m12",
    "lmul",
]

IMAGE_DISPLAY_NAMES = {
    "Adjuster": "Adjuster",
    "Balls": "Balls",
    "flowers": "Flowers",
    "Rec709": "Rec709",
    "StillLife": "Still Life",
    "forest_path": "Forest Path",
    "mpi_office": "MPI Office",
    "seymour_park": "Seymour Park",
}

APPLICATION_DISPLAY_NAMES = {
    "sharpen5": "5x5 Sharpening Filter",
    "laplacian3": "Laplacian Filter",
    "sharpen3": "Sharpening Filter",
    "sobel": "Sobel Edge Detection",
    "tone_map": "Tone Mapping",
    "sharpen5_repeat_5": "Repeated 5x5 Sharpening (5 Iterations)",
    "sharpen5_repeat_10": "Repeated 5x5 Sharpening (10 Iterations)",
    "unsharp_alpha_1.0": "Unsharp Mask (alpha = 1.0)",
    "unsharp_alpha_1.5": "Unsharp Mask (alpha = 1.5)",
    "sharpen5_diff_1_2": "5x5 Sharpening Difference (1, 2)",
    "sharpen5_diff_1_3": "5x5 Sharpening Difference (1, 3)",
}

APPLICATION_ORDER = [
    "sharpen5",
    "laplacian3",
    "sharpen3",
    "sobel",
    "tone_map",
    "sharpen5_repeat_5",
    "sharpen5_repeat_10",
    "unsharp_alpha_1.0",
    "unsharp_alpha_1.5",
    "sharpen5_diff_1_2",
    "sharpen5_diff_1_3",
]


def latex_escape(text: str) -> str:
    replacements = {
        "\\": r"\textbackslash{}",
        "_": r"\_",
        "&": r"\&",
        "%": r"\%",
        "#": r"\#",
        "{": r"\{",
        "}": r"\}",
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text


def sanitize_label(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_")


def format_psnr_text(x) -> str:
    if pd.isna(x):
        return "--"
    try:
        x = float(x)
    except Exception:
        return "--"
    if math.isinf(x):
        return r"$\infty$"
    if math.isnan(x):
        return "--"
    return f"{x:.2f} dB"


def format_ssim_text(x) -> str:
    if pd.isna(x):
        return "--"
    try:
        x = float(x)
    except Exception:
        return "--"
    if math.isinf(x) or math.isnan(x):
        return "--"
    return f"{x:.4f}"


def pretty_image_name(image_stem: str) -> str:
    return IMAGE_DISPLAY_NAMES.get(image_stem, image_stem.replace("_", " "))


def pretty_application_name(application: str) -> str:
    return APPLICATION_DISPLAY_NAMES.get(application, application.replace("_", " "))


def chunk_list(items, chunk_size):
    return [items[i:i + chunk_size] for i in range(0, len(items), chunk_size)]


def find_model_pdf(image_stem: str, application: str, model: str) -> str | None:
    path = PDF_DIR / f"{image_stem}_{application}_{model}.pdf"
    if not path.exists():
        return None
    return str(path).replace("\\", "/")


def make_metric_image_cell(row_df: pd.DataFrame, image_stem: str, application: str, model: str) -> str:
    if row_df.empty:
        return "--"

    pdf = find_model_pdf(image_stem, application, model)
    if pdf is None:
        return "--"

    row = row_df.iloc[0]
    ssim = format_ssim_text(row["ssim"])
    psnr = format_psnr_text(row["psnr_db"])

    return (
        r"\makecell[c]{"
        + rf"\includegraphics[width={IMAGE_WIDTH}]{{{pdf}}} \\ "
        + rf"{{\scriptsize {ssim} \;|\; {psnr}}}"
        + r"}"
    )


def build_longtable_for_application_part(
    df_app: pd.DataFrame,
    application: str,
    image_group: list[str],
    part_idx: int,
    total_parts: int,
) -> str:
    app_title = pretty_application_name(application)

    if total_parts == 1:
        caption = f"{app_title}. Each cell shows SSIM | PSNR (dB)."
        label = f"tab:{sanitize_label(application)}_with_images"
    else:
        caption = f"{app_title} (Part {part_idx}). Each cell shows SSIM | PSNR (dB)."
        label = f"tab:{sanitize_label(application)}_with_images_part_{part_idx}"

    col_spec = r"|p{1.8cm}|" + "|".join([r"p{3.15cm}"] * len(image_group)) + "|"

    header = [r"\rowcolor{gray!30}\textbf{Model}"]
    for image_stem in image_group:
        header.append(r"\textbf{" + latex_escape(pretty_image_name(image_stem)) + r"}")
    header_line = " & ".join(header) + r" \\"

    lines = []
    lines.append(r"\renewcommand{\arraystretch}{1.08}")
    lines.append(r"\setlength{\tabcolsep}{4pt}")
    lines.append(r"\begin{longtable}{" + col_spec + "}")
    lines.append(r"\caption{" + latex_escape(caption) + r"}\label{" + label + r"} \\")
    lines.append(r"\hline")
    lines.append(header_line)
    lines.append(r"\hline")
    lines.append(r"\endfirsthead")

    lines.append(r"\hline")
    lines.append(header_line)
    lines.append(r"\hline")
    lines.append(r"\endhead")

    lines.append(r"\hline")
    lines.append(
        r"\multicolumn{" + str(len(image_group) + 1) + r"}{|r|}{\footnotesize Continued on next page} \\"
    )
    lines.append(r"\hline")
    lines.append(r"\endfoot")

    lines.append(r"\hline")
    lines.append(r"\endlastfoot")

    for model in MODEL_ORDER:
        row_cells = [latex_escape(MODEL_DISPLAY_NAMES[model])]

        for image_stem in image_group:
            row_df = df_app[
                (df_app["model"] == model) &
                (df_app["image_stem"] == image_stem)
            ]
            row_cells.append(make_metric_image_cell(row_df, image_stem, application, model))

        lines.append(" & ".join(row_cells) + r" \\")
        lines.append(r"\hline")

    lines.append(r"\end{longtable}")
    lines.append("")

    return "\n".join(lines)


def main():
    if not SUMMARY_CSV.exists():
        raise FileNotFoundError(f"Missing summary CSV: {SUMMARY_CSV}")
    if not PDF_DIR.exists():
        raise FileNotFoundError(f"Missing PDF directory: {PDF_DIR}")

    df = pd.read_csv(SUMMARY_CSV)

    if "error" in df.columns:
        df = df[(df["error"].isna()) | (df["error"] == "")].copy()

    df["image_stem"] = df["image"].apply(lambda x: Path(str(x)).stem)

    df = df[df["model"].isin(MODEL_ORDER)].copy()

    preferred_images = [
        "Adjuster",
        "Desk",
        "HDR",
        "Rec709",
        "StillLife",
        "forest_path",
        "mpi_office",
        "seymour_park",
    ]
    used_images = [img for img in preferred_images if img in set(df["image_stem"])]
    remaining_images = [img for img in df["image_stem"].unique() if img not in used_images]
    image_order = used_images + list(remaining_images)

    used_apps = [app for app in APPLICATION_ORDER if app in set(df["application"])]
    remaining_apps = [app for app in df["application"].unique() if app not in used_apps]
    app_order = used_apps + list(remaining_apps)

    blocks = []
    for application in app_order:
        df_app = df[df["application"] == application].copy()
        image_groups = chunk_list(image_order, IMAGES_PER_TABLE)

        for idx, image_group in enumerate(image_groups, start=1):
            blocks.append(
                build_longtable_for_application_part(
                    df_app=df_app,
                    application=application,
                    image_group=image_group,
                    part_idx=idx,
                    total_parts=len(image_groups),
                )
            )

    OUTPUT_TEX.write_text("\n\n".join(blocks), encoding="utf-8")
    print(f"Wrote LaTeX longtables to: {OUTPUT_TEX}")


if __name__ == "__main__":
    main()
