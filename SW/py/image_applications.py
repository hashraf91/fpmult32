import csv
import math
import os
import warnings
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

import cv2
import imageio.v2 as imageio
import matplotlib.pyplot as plt
import numpy as np
from numpy.lib.stride_tricks import sliding_window_view

import fpmult_py

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
TEST_IMAGES_DIR = PROJECT_ROOT / "test_images"
TEST_IMAGES_CANONICAL_DIR = PROJECT_ROOT / "test_images_canonical"
OUT_IMAGES_DIR = PROJECT_ROOT / "out_images"

ALL_MODELS = [
    "viv_acc",
    "mxa1",
    "mxa2",
    "lxa",
    "lmul",
    "ssm_m12",
    "ssm_m12c",
    "ssm_m18",
    "ssm_m18c",
]

REFERENCE_MODEL = "viv_acc"

GROUP1_APPLICATIONS = [
    "gaussian5",
    "laplacian3",
    "sharpen3",
    "sobel",
    "tone_map",
]

GROUP2_APPLICATIONS = [
    "gaussian5_repeat_5",
    "gaussian5_repeat_10",
    "unsharp_alpha_1.0",
    "unsharp_alpha_1.5",
    "dog_1_2",
    "dog_1_3",
]

ALL_APPLICATIONS = GROUP1_APPLICATIONS + GROUP2_APPLICATIONS

FLOAT32_MAX = np.finfo(np.float32).max


def configure_numpy_warnings(policy: str = "ignore"):
    np.seterr(all=policy)


def sanitize_image(img: np.ndarray, nan_value: float = 0.0,
                   posinf_value: float = 1.0, neginf_value: float = 0.0) -> np.ndarray:
    img = np.asarray(img, dtype=np.float32)
    return np.nan_to_num(img, nan=nan_value, posinf=posinf_value, neginf=neginf_value)


def safe_divide(numerator: np.ndarray, denominator: np.ndarray,
                fill_value: float = 0.0, eps: float = 1e-30) -> np.ndarray:
    numerator = np.asarray(numerator, dtype=np.float32)
    denominator = np.asarray(denominator, dtype=np.float32)
    denominator_safe = np.where(np.abs(denominator) < eps, eps, denominator).astype(np.float32)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore", under="ignore"):
        out = numerator / denominator_safe
    return sanitize_image(out, nan_value=fill_value, posinf_value=fill_value, neginf_value=fill_value)


def safe_square_sum_sqrt(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    a = np.asarray(a, dtype=np.float32)
    b = np.asarray(b, dtype=np.float32)
    scale = np.maximum(np.abs(a), np.abs(b)).astype(np.float32)
    scale_safe = np.where(scale == 0, 1.0, scale).astype(np.float32)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore", under="ignore"):
        a_scaled = a / scale_safe
        b_scaled = b / scale_safe
        mag = scale_safe * np.sqrt(a_scaled * a_scaled + b_scaled * b_scaled, dtype=np.float32)
    mag = np.where(scale == 0, 0.0, mag).astype(np.float32)
    return sanitize_image(mag, nan_value=0.0, posinf_value=np.sqrt(FLOAT32_MAX), neginf_value=0.0)


def tonemap_simple(img: np.ndarray) -> np.ndarray:
    img = sanitize_image(img, nan_value=0.0, posinf_value=1.0, neginf_value=0.0)
    img = np.maximum(img, 0.0)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore", under="ignore"):
        img = img / (1.0 + img)
    return np.clip(sanitize_image(img, nan_value=0.0, posinf_value=1.0, neginf_value=0.0), 0.0, 1.0)


def normalize_unit(img: np.ndarray) -> np.ndarray:
    img = sanitize_image(img, nan_value=0.0, posinf_value=1.0, neginf_value=0.0)
    max_val = np.max(img)
    if not np.isfinite(max_val) or max_val <= 0:
        return np.zeros_like(img, dtype=np.float32)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore", under="ignore"):
        img = img / max_val
    return np.clip(sanitize_image(img, nan_value=0.0, posinf_value=1.0, neginf_value=0.0), 0.0, 1.0)


def load_image_any(path: str) -> np.ndarray:
    path_obj = Path(path)
    suffix = path_obj.suffix.lower()
    if suffix not in {".hdr", ".exr"}:
        raise ValueError(f"Unsupported input format: {suffix}")
    img = cv2.imread(str(path_obj), cv2.IMREAD_ANYDEPTH | cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError(f"Failed to load HDR/EXR image: {path}")
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    return sanitize_image(np.asarray(img, dtype=np.float32))


def canonicalize_hdr_image(img: np.ndarray, key: float = 0.18, eps: float = 1e-6) -> np.ndarray:
    img = sanitize_image(img)
    if img.ndim != 3 or img.shape[2] != 3:
        raise ValueError("canonicalize_hdr_image expects RGB image")
    R, G, B = img[..., 0], img[..., 1], img[..., 2]
    L = np.maximum(0.2126 * R + 0.7152 * G + 0.0722 * B, eps)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore", under="ignore"):
        L_avg = np.exp(np.mean(np.log(L), dtype=np.float64)).astype(np.float32)
    if not np.isfinite(L_avg) or L_avg <= 0:
        L_avg = np.float32(1.0)
    L_scaled = (key / L_avg) * L
    L_mapped = safe_divide(L_scaled, 1.0 + L_scaled, fill_value=0.0)
    scale = safe_divide(L_mapped, L, fill_value=0.0, eps=eps)
    out = np.empty_like(img, dtype=np.float32)
    out[..., 0] = R * scale
    out[..., 1] = G * scale
    out[..., 2] = B * scale
    return sanitize_image(out)


def preprocess_hdr_dataset(input_dir: str, output_dir: str, save_preview_pngs: bool = True):
    input_dir = Path(input_dir)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for image_path in sorted(p for p in input_dir.iterdir() if p.suffix.lower() in {".hdr", ".exr"}):
        img = load_image_any(str(image_path))
        out = canonicalize_hdr_image(img) if image_path.suffix.lower() == ".hdr" else sanitize_image(img)
        out_path = output_dir / image_path.name
        _save_image_same_format(out_path, out)
        if save_preview_pngs:
            _save_preview_png(output_dir / f"{image_path.stem}_preview.png", out)


def psnr_db(ref: np.ndarray, test: np.ndarray, data_range: float = 1.0) -> float:
    ref = sanitize_image(ref)
    test = sanitize_image(test)
    mse_val = np.mean((ref - test) ** 2, dtype=np.float64)
    if not np.isfinite(mse_val):
        return float("nan")
    if mse_val == 0:
        return float("inf")
    return 10.0 * math.log10((data_range ** 2) / mse_val)


def mse(ref: np.ndarray, test: np.ndarray) -> float:
    return float(np.mean((sanitize_image(ref) - sanitize_image(test)) ** 2, dtype=np.float64))


def mae(ref: np.ndarray, test: np.ndarray) -> float:
    return float(np.mean(np.abs(sanitize_image(ref) - sanitize_image(test)), dtype=np.float64))


def max_abs_error(ref: np.ndarray, test: np.ndarray) -> float:
    return float(np.max(np.abs(sanitize_image(ref) - sanitize_image(test))))


def _ssim_single_channel(x: np.ndarray, y: np.ndarray, data_range: float = 1.0) -> float:
    x = sanitize_image(x)
    y = sanitize_image(y)
    K1, K2 = 0.01, 0.03
    C1 = (K1 * data_range) ** 2
    C2 = (K2 * data_range) ** 2
    mu_x = np.mean(x, dtype=np.float64)
    mu_y = np.mean(y, dtype=np.float64)
    sigma_x = np.var(x, dtype=np.float64)
    sigma_y = np.var(y, dtype=np.float64)
    sigma_xy = np.mean((x - mu_x) * (y - mu_y), dtype=np.float64)
    numerator = (2 * mu_x * mu_y + C1) * (2 * sigma_xy + C2)
    denominator = (mu_x**2 + mu_y**2 + C1) * (sigma_x + sigma_y + C2)
    if not np.isfinite(numerator) or not np.isfinite(denominator):
        return float("nan")
    if denominator == 0:
        return 1.0
    return float(np.clip(numerator / denominator, 0.0, 1.0))


def ssim_image(ref: np.ndarray, test: np.ndarray, data_range: float = 1.0) -> float:
    ref = sanitize_image(ref)
    test = sanitize_image(test)
    vals = [_ssim_single_channel(ref[..., c], test[..., c], data_range) for c in range(ref.shape[2])] if ref.ndim == 3 else [_ssim_single_channel(ref, test, data_range)]
    return float(np.mean(np.clip(np.asarray(vals, dtype=np.float64), 0.0, 1.0)))


def gaussian5_kernel() -> np.ndarray:
    return ((1.0 / 256.0) * np.array([
        [-1, -4, -6, -4, -1],
        [-4, -16, -24, -16, -4],
        [-6, -24, 476, -24, -6],
        [-4, -16, -24, -16, -4],
        [-1, -4, -6, -4, -1]
    ], dtype=np.float32)).astype(np.float32)


def sobel_x_kernel() -> np.ndarray:
    return np.array([[-1, -2, -1], [0, 0, 0], [1, 2, 1]], dtype=np.float32)


def sobel_y_kernel() -> np.ndarray:
    return sobel_x_kernel().T.astype(np.float32)


def laplacian3_kernel() -> np.ndarray:
    return np.array([[0, -1, 0], [-1, 4, -1], [0, -1, 0]], dtype=np.float32)


def sharpen3_kernel() -> np.ndarray:
    return np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]], dtype=np.float32)


def _batched_dot_windows(channel: np.ndarray, kernel: np.ndarray, model: str = None) -> np.ndarray:
    channel = sanitize_image(channel)
    kernel = sanitize_image(kernel)
    kh, kw = kernel.shape
    ph, pw = kh // 2, kw // 2
    padded = np.pad(channel, ((ph, ph), (pw, pw)), mode="edge")
    windows = sliding_window_view(padded, (kh, kw))
    H, W = windows.shape[:2]
    windows_flat = windows.reshape(H, W, kh * kw).astype(np.float32, copy=False)
    kernel_flat = kernel.reshape(kh * kw).astype(np.float32, copy=False)
    if model is None:
        return sanitize_image(np.asarray(np.tensordot(windows_flat, kernel_flat, axes=([-1], [0])), dtype=np.float32))
    return sanitize_image(np.asarray(fpmult_py.dot_lastdim_float_array(windows_flat, kernel_flat, model), dtype=np.float32))


def filter_image(img: np.ndarray, kernel: np.ndarray, model: str = None) -> np.ndarray:
    img = sanitize_image(img)
    out_channels = [_batched_dot_windows(img[..., c], kernel, model=model) for c in range(img.shape[2])]
    return sanitize_image(np.stack(out_channels, axis=2))


def sobel_edge_image(img: np.ndarray, model: str = None) -> np.ndarray:
    img = sanitize_image(img)
    gray = (0.2989 * img[..., 0] + 0.5870 * img[..., 1] + 0.1140 * img[..., 2]).astype(np.float32)
    gx = _batched_dot_windows(gray, sobel_x_kernel(), model=model)
    gy = _batched_dot_windows(gray, sobel_y_kernel(), model=model)
    return sanitize_image(safe_square_sum_sqrt(gx, gy))


def repeated_gaussian(img: np.ndarray, repeats: int, model: str = None) -> np.ndarray:
    out = sanitize_image(img)
    k = gaussian5_kernel()
    for _ in range(repeats):
        out = filter_image(out, k, model=model)
    return sanitize_image(out)


def unsharp_mask(img: np.ndarray, alpha: float, model: str = None) -> np.ndarray:
    img = sanitize_image(img)
    blur = filter_image(img, gaussian5_kernel(), model=model)
    return sanitize_image(img + alpha * (img - blur))


def difference_of_gaussians(img: np.ndarray, r1: int, r2: int, model: str = None) -> np.ndarray:
    return sanitize_image(repeated_gaussian(img, r1, model=model) - repeated_gaussian(img, r2, model=model))


def tone_map_hdr(img: np.ndarray, model: str = None, eps: float = 1e-6) -> np.ndarray:
    img = sanitize_image(img)
    R, G, B = img[..., 0], img[..., 1], img[..., 2]
    if model is None:
        Ltmp = 0.27 * R + 0.67 * G + 0.06 * B
    else:
        c27 = np.full_like(R, 0.27, dtype=np.float32)
        c67 = np.full_like(G, 0.67, dtype=np.float32)
        c06 = np.full_like(B, 0.06, dtype=np.float32)
        Ltmp = (
            fpmult_py.multiply_float_array(R, c27, model) +
            fpmult_py.multiply_float_array(G, c67, model) +
            fpmult_py.multiply_float_array(B, c06, model)
        )
    Ltmp = np.maximum(sanitize_image(Ltmp, nan_value=eps, posinf_value=1.0, neginf_value=eps), eps)
    with np.errstate(divide="ignore", invalid="ignore", over="ignore", under="ignore"):
        Lm = np.exp(np.mean(np.log(Ltmp), dtype=np.float64)).astype(np.float32)
    if not np.isfinite(Lm) or Lm <= 0:
        Lm = np.float32(1.0)
    L = sanitize_image(safe_divide(Ltmp, Lm, fill_value=0.0, eps=eps))
    Lmapped = sanitize_image(safe_divide(L, 1.0 + L, fill_value=0.0, eps=eps))
    scale = sanitize_image(safe_divide(Lmapped, Ltmp, fill_value=0.0, eps=eps))
    out = np.empty_like(img, dtype=np.float32)
    out[..., 0] = R * scale
    out[..., 1] = G * scale
    out[..., 2] = B * scale
    return sanitize_image(out)


def prepare_for_metrics(img: np.ndarray) -> np.ndarray:
    return normalize_unit(sanitize_image(img))


def prepare_for_preview(img: np.ndarray) -> np.ndarray:
    return tonemap_simple(sanitize_image(img))


def _save_image_same_format(path: Path, img: np.ndarray):
    img = sanitize_image(img)
    out = img.astype(np.float32)
    if out.ndim == 3:
        out = cv2.cvtColor(out, cv2.COLOR_RGB2BGR)
    ok = cv2.imwrite(str(path), out)
    if not ok:
        raise ValueError(f"Failed to write image: {path}")


def _save_preview_png(path: Path, img: np.ndarray):
    preview = prepare_for_preview(img)
    preview_u8 = (np.clip(preview, 0.0, 1.0) * 255.0).astype(np.uint8)
    imageio.imwrite(path, preview_u8)


def _save_reference(save_dir: Path, input_path: Path, application: str, ref_raw: np.ndarray, save_preview_pngs: bool):
    ext = input_path.suffix.lower()
    base = input_path.stem
    baseline_tag = f"baseline_{REFERENCE_MODEL}"
    _save_image_same_format(save_dir / f"{base}_{application}_{baseline_tag}{ext}", ref_raw)
    if save_preview_pngs:
        _save_preview_png(save_dir / f"{base}_{application}_{baseline_tag}_preview.png", ref_raw)


def _save_model_output_and_metrics(save_dir: Path, input_path: Path, application: str, model_name: str,
                                   test_raw: np.ndarray, metrics: dict, save_preview_pngs: bool):
    ext = input_path.suffix.lower()
    base = input_path.stem
    _save_image_same_format(save_dir / f"{base}_{application}_{model_name}{ext}", test_raw)
    if save_preview_pngs:
        _save_preview_png(save_dir / f"{base}_{application}_{model_name}_preview.png", test_raw)
    with open(save_dir / f"{base}_{application}_{model_name}_metrics.txt", "w") as f:
        for k, v in metrics.items():
            f.write(f"{k}: {v}\n")


def _display_pair(ref_raw: np.ndarray, test_raw: np.ndarray, title_left: str, title_right: str):
    ref = prepare_for_preview(ref_raw)
    test = prepare_for_preview(test_raw)
    plt.figure(figsize=(12, 5))
    plt.subplot(1, 2, 1)
    plt.imshow(ref if ref.ndim == 3 else ref, cmap=None if ref.ndim == 3 else "gray")
    plt.title(title_left)
    plt.axis("off")
    plt.subplot(1, 2, 2)
    plt.imshow(test if test.ndim == 3 else test, cmap=None if test.ndim == 3 else "gray")
    plt.title(title_right)
    plt.axis("off")
    plt.tight_layout()
    plt.show()


def compute_metrics(ref_raw: np.ndarray, test_raw: np.ndarray) -> dict:
    ref_metric = prepare_for_metrics(ref_raw)
    test_metric = prepare_for_metrics(test_raw)
    return {
        "PSNR_dB": psnr_db(ref_metric, test_metric, data_range=1.0),
        "SSIM": ssim_image(ref_metric, test_metric, data_range=1.0),
        "MSE": mse(ref_metric, test_metric),
        "MAE": mae(ref_metric, test_metric),
        "MAX_ABS_ERR": max_abs_error(ref_metric, test_metric),
    }


def run_application(img: np.ndarray, application: str, model: str = None) -> np.ndarray:
    if application == "gaussian5":
        return filter_image(img, gaussian5_kernel(), model=model)
    if application == "laplacian3":
        return filter_image(img, laplacian3_kernel(), model=model)
    if application == "sharpen3":
        return filter_image(img, sharpen3_kernel(), model=model)
    if application == "sobel":
        return sobel_edge_image(img, model=model)
    if application == "tone_map":
        return tone_map_hdr(img, model=model)
    if application == "gaussian5_repeat_5":
        return repeated_gaussian(img, repeats=5, model=model)
    if application == "gaussian5_repeat_10":
        return repeated_gaussian(img, repeats=10, model=model)
    if application == "unsharp_alpha_1.0":
        return unsharp_mask(img, alpha=1.0, model=model)
    if application == "unsharp_alpha_1.5":
        return unsharp_mask(img, alpha=1.5, model=model)
    if application == "dog_1_2":
        return difference_of_gaussians(img, r1=1, r2=2, model=model)
    if application == "dog_1_3":
        return difference_of_gaussians(img, r1=1, r2=3, model=model)
    raise ValueError(f"Unknown application: {application}")


def evaluate_application(image_path: str, application: str, model: str, save_dir: str = None,
                         display: bool = True, save_preview_pngs: bool = True):
    img = load_image_any(image_path)
    ref_raw = run_application(img, application, model=REFERENCE_MODEL)
    test_raw = run_application(img, application, model=model)
    metrics = compute_metrics(ref_raw, test_raw)

    print(f"Application : {application}")
    print(f"Reference   : {REFERENCE_MODEL}")
    print(f"Model       : {model}")
    print(f"PSNR (dB)   : {metrics['PSNR_dB']:.4f}")
    print(f"SSIM        : {metrics['SSIM']:.6f}")
    print(f"MSE         : {metrics['MSE']:.8e}")
    print(f"MAE         : {metrics['MAE']:.8e}")
    print(f"MAX_ABS_ERR : {metrics['MAX_ABS_ERR']:.8e}")

    if save_dir is not None:
        save_dir_path = Path(save_dir)
        save_dir_path.mkdir(parents=True, exist_ok=True)
        input_path_obj = Path(image_path)
        _save_reference(save_dir_path, input_path_obj, application, ref_raw, save_preview_pngs)
        _save_model_output_and_metrics(save_dir_path, input_path_obj, application, model, test_raw, metrics, save_preview_pngs)

    if display:
        _display_pair(
            ref_raw,
            test_raw,
            f"Reference ({REFERENCE_MODEL}) - {application}",
            f"{model} - PSNR={metrics['PSNR_dB']:.2f} dB, SSIM={metrics['SSIM']:.4f}"
        )

    return {
        "application": application,
        "reference_model": REFERENCE_MODEL,
        "model": model,
        "psnr_db": metrics["PSNR_dB"],
        "ssim": metrics["SSIM"],
        "mse": metrics["MSE"],
        "mae": metrics["MAE"],
        "max_abs_err": metrics["MAX_ABS_ERR"],
    }


def _worker_image_application(job):
    image_path, application, models, save_dir, save_preview_pngs = job
    image_path = Path(image_path)
    save_dir = Path(save_dir)
    save_dir.mkdir(parents=True, exist_ok=True)

    img = load_image_any(str(image_path))
    ref_raw = run_application(img, application, model=REFERENCE_MODEL)
    _save_reference(save_dir, image_path, application, ref_raw, save_preview_pngs)

    rows = []
    group = 1 if application in GROUP1_APPLICATIONS else 2

    for model in models:
        test_raw = run_application(img, application, model=model)
        metrics = compute_metrics(ref_raw, test_raw)
        _save_model_output_and_metrics(save_dir, image_path, application, model, test_raw, metrics, save_preview_pngs)

        rows.append({
            "image": image_path.name,
            "group": group,
            "application": application,
            "reference_model": REFERENCE_MODEL,
            "model": model,
            "psnr_db": metrics["PSNR_dB"],
            "ssim": metrics["SSIM"],
            "mse": metrics["MSE"],
            "mae": metrics["MAE"],
            "max_abs_err": metrics["MAX_ABS_ERR"],
            "error": "",
        })

    return rows


def run_batch_experiments_parallel(image_dir: str, applications, models, save_dir="out_images",
                                   csv_name="summary.csv", save_preview_pngs=True, max_workers=8):
    image_dir = Path(image_dir)
    save_dir = Path(save_dir)
    save_dir.mkdir(parents=True, exist_ok=True)

    image_paths = sorted([p for p in image_dir.iterdir() if p.suffix.lower() in {".hdr", ".exr"}])

    jobs = [
        (str(image_path), application, list(models), str(save_dir), save_preview_pngs)
        for image_path in image_paths
        for application in applications
    ]

    rows = []
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(_worker_image_application, job): job for job in jobs}
        for future in as_completed(futures):
            image_path, application, _, _, _ = futures[future]
            try:
                job_rows = future.result()
                rows.extend(job_rows)
                print(f"Done: {Path(image_path).name} | {application}")
            except Exception as e:
                group = 1 if application in GROUP1_APPLICATIONS else 2
                for model in models:
                    rows.append({
                        "image": Path(image_path).name,
                        "group": group,
                        "application": application,
                        "reference_model": REFERENCE_MODEL,
                        "model": model,
                        "psnr_db": "",
                        "ssim": "",
                        "mse": "",
                        "mae": "",
                        "max_abs_err": "",
                        "error": str(e),
                    })
                print(f"ERROR: {Path(image_path).name} | {application} -> {e}")

    rows.sort(key=lambda r: (r["image"], r["group"], r["application"], r["model"]))

    csv_path = save_dir / csv_name
    fieldnames = [
        "image", "group", "application", "reference_model", "model",
        "psnr_db", "ssim", "mse", "mae", "max_abs_err", "error"
    ]
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nSaved summary CSV to: {csv_path}")
    return rows


if __name__ == "__main__":
    os.environ.setdefault("OMP_NUM_THREADS", "1")
    os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
    os.environ.setdefault("MKL_NUM_THREADS", "1")
    os.environ.setdefault("NUMEXPR_NUM_THREADS", "1")

    configure_numpy_warnings("ignore")
    warnings.filterwarnings("ignore", category=RuntimeWarning)

    preprocess_hdr_dataset(
        input_dir=TEST_IMAGES_DIR,
        output_dir=TEST_IMAGES_CANONICAL_DIR,
        save_preview_pngs=True,
    )

    rows = run_batch_experiments_parallel(
        image_dir=TEST_IMAGES_CANONICAL_DIR,
        applications=ALL_APPLICATIONS,
        models=ALL_MODELS,
        save_dir=OUT_IMAGES_DIR,
        csv_name="summary.csv",
        save_preview_pngs=True,
        max_workers=28,
    )
