# Floating-Point FP32 Evaluation Framework

This repository contains Verilog RTL, Vivado automation scripts, software reference models, Python bindings, image-processing evaluation scripts, and reporting helpers for evaluating accurate and approximate multiplier designs.

It supports:

- functional simulation of floating-point multiplier designs
- Vivado-based synthesis and implementation
- timing analysis of floating-point and integer multiplier variants
- software-vs-hardware comparison for FP32 designs
- image-processing-based quality evaluation of approximate FP32 multipliers
- LaTeX/PDF report generation from software results

---

## Repository Structure

```text
.
├── HW/
│   ├── accurate/
│   │   ├── acc1/
│   │   ├── acc2/
│   │   └── acc_vivado/
│   ├── approximate/
│   │   ├── lmul/
│   │   ├── lxa/
│   │   ├── mxa1/
│   │   ├── mxa2/
│   │   └── ssm/
│   ├── common/
│   ├── scripts/
│   ├── testbench/
│   ├── timing/
│   └── constraints.xdc
├── SW/
│   ├── core/
│   ├── eval/
│   ├── helpers/
│   ├── include/
│   ├── py/
│   ├── test_images/
│   └── Makefile
├── results/
├── reports/
└── README.md
```

---

## High-Level Overview

The project has two major parts:

### HW side
The hardware side contains:

- accurate and approximate RTL implementations
- simulation testbenches
- timing-analysis wrapper modules
- Vivado Tcl scripts to run one simulation or one synthesis flow at a time

### SW side
The software side contains:

- C++ reference models for FP32 and integer multiplier families
- C++ tools for error metric reporting and hardware CSV comparison
- Python bindings via `pybind11`
- HDR/EXR image-processing experiments using approximate FP32 multipliers
- helper scripts for PDF and LaTeX generation

---

# 1. Hardware Side

## 1.1 Hardware Directory Layout

### `HW/accurate/`
Accurate designs:

- `acc1/`
- `acc2/`
- `acc_vivado/`

These include both floating-point and integer multiplier implementations.

### `HW/approximate/`
Approximate designs:

- `mxa1/`
- `mxa2/`
- `lxa/`
- `lmul/`
- `ssm/`

### `HW/common/`
Shared building blocks:

- `adder.v`

### `HW/testbench/`
Simulation testbenches:

- `tb_fpmult_compare.v`
- `tb_fpmult_vivado_compare.v`
- `tb_mult_compare.v`
- `tb_mult_24x24_lxa_compare.v`

### `HW/timing/`
Timing wrappers for synthesis experiments:

- `timing_analysis.v`

### `HW/scripts/`
Vivado automation scripts:

- `run_sim_one.tcl`
- `run_synth_one.tcl`

---

## 1.2 Implemented Floating-Point Designs

### Accurate FP32
- `fpmult_e8m23_acc1`
- `fpmult_e8m23_acc2`
- `fpmult_e8m23_acc_vivado`

### Approximate FP32
- `fpmult_e8m23_mxa1`
- `fpmult_e8m23_mxa2`
- `fpmult_e8m23_lxa`
- `fpmult_e8m23_lmul`
- `fpmult_e8m23_ssm_m12`
- `fpmult_e8m23_ssm_m12c`
- `fpmult_e8m23_ssm_m14`
- `fpmult_e8m23_ssm_m14c`
- `fpmult_e8m23_ssm_m16`
- `fpmult_e8m23_ssm_m16c`
- `fpmult_e8m23_ssm_m18`
- `fpmult_e8m23_ssm_m18c`

---

## 1.3 Implemented Integer Designs

### Accurate integer multipliers
- `mult_3x3_acc1`
- `mult_6x6_acc1`
- `mult_12x12_acc1`
- `mult_24x24_acc1`

- `mult_3x3_acc2`
- `mult_6x6_acc2`
- `mult_12x12_acc2`
- `mult_24x24_acc2`

### Approximate integer multipliers
- `mult_3x3_mxa1`
- `mult_6x6_mxa1`
- `mult_12x12_mxa1`
- `mult_24x24_mxa1`

- `mult_3x3_mxa2`
- `mult_6x6_mxa2`
- `mult_12x12_mxa2`
- `mult_24x24_mxa2`

- `mult_24x24_lxa`

### SSM integer-style mantissa multipliers
- `mult_23x23_ssm_m12`
- `mult_23x23_ssm_m12c`
- `mult_23x23_ssm_m14`
- `mult_23x23_ssm_m14c`
- `mult_23x23_ssm_m16`
- `mult_23x23_ssm_m16c`
- `mult_23x23_ssm_m18`
- `mult_23x23_ssm_m18c`

---

## 1.4 Hardware Testbenches

### `tb_fpmult_compare.v`
Compares selected FP32 DUT against `fpmult_e8m23_acc_vivado`.

It writes CSV output like:

- `fpmult_e8m23_acc1.csv`
- `fpmult_e8m23_mxa1.csv`
- `fpmult_e8m23_lxa.csv`
- `fpmult_e8m23_ssm_m18c.csv`

### `tb_fpmult_vivado_compare.v`
Compares:

- `fpmult_e8m23_viv_reference`
- `fpmult_e8m23_acc_vivado`

It writes:

- `fpmult_e8m23_viv_reference.csv`

### `tb_mult_compare.v`
Compares integer multiplier DUTs against exact multiplication.

### `tb_mult_24x24_lxa_compare.v`
Dedicated evaluation testbench for `mult_24x24_lxa`.

---

## 1.5 Timing Wrapper Modules

The file `HW/timing/timing_analysis.v` provides synthesis top wrappers such as:

### Floating-point timing tops
- `timing_fpmult_e8m23_acc1`
- `timing_fpmult_e8m23_acc2`
- `timing_fpmult_e8m23_acc_vivado`
- `timing_fpmult_e8m23_mxa1`
- `timing_fpmult_e8m23_mxa2`
- `timing_fpmult_e8m23_lxa`
- `timing_fpmult_e8m23_lmul`
- `timing_fpmult_e8m23_ssm_m12`
- `timing_fpmult_e8m23_ssm_m12c`
- `timing_fpmult_e8m23_ssm_m14`
- `timing_fpmult_e8m23_ssm_m14c`
- `timing_fpmult_e8m23_ssm_m16`
- `timing_fpmult_e8m23_ssm_m16c`
- `timing_fpmult_e8m23_ssm_m18`
- `timing_fpmult_e8m23_ssm_m18c`

### Integer timing tops
- `timing_mult_3x3_acc1`
- `timing_mult_3x3_acc2`
- `timing_mult_3x3_mxa1`
- `timing_mult_3x3_mxa2`
- `timing_mult_6x6_acc1`
- `timing_mult_6x6_acc2`
- `timing_mult_6x6_mxa1`
- `timing_mult_6x6_mxa2`
- `timing_mult_12x12_acc1`
- `timing_mult_12x12_acc2`
- `timing_mult_12x12_mxa1`
- `timing_mult_12x12_mxa2`
- `timing_mult_24x24_acc1`
- `timing_mult_24x24_acc2`
- `timing_mult_24x24_mxa1`
- `timing_mult_24x24_mxa2`
- `timing_mult_24x24_mxa2_plus_1`
- `timing_mult_24x24_mxa2_plus_2`
- `timing_mult_24x24_mxa2_plus_3`
- `timing_mult_24x24_mxa2_plus_4`
- `timing_mult_24x24_mxa2_plus_5`
- `timing_mult_24x24_mxa2_plus_6`
- `timing_mult_24x24_lxa`

---

## 1.6 Hardware Prerequisites

You need:

- Xilinx Vivado
- a Vivado project containing the RTL/testbench sources
- the generated floating-point reference IP/module if using `tb_fpmult_vivado_compare.v`

This README assumes you already have a Vivado project file such as:

```bash
/path/to/project.xpr
```

---

## 1.7 Running One Simulation

Use:

```bash
vivado -mode batch -source HW/scripts/run_sim_one.tcl -tclargs <project.xpr> <sim_top> [out_csv_dir]
```

Example:

```bash
vivado -mode batch -source HW/scripts/run_sim_one.tcl -tclargs my_project.xpr tb_top_fpmult_e8m23_mxa1 results
```

If `out_csv_dir` is omitted, the script defaults to:

```text
<repo_root>/results
```

---

## 1.8 Running All Floating-Point Simulations

The following loop generates the CSV files you listed in `results/`.

Run from repository root:

```bash
mkdir -p results

for top in \
    tb_top_fpmult_e8m23_acc_vivado \
    tb_top_fpmult_e8m23_acc1 \
    tb_top_fpmult_e8m23_acc2 \
    tb_top_fpmult_e8m23_mxa1 \
    tb_top_fpmult_e8m23_mxa2 \
    tb_top_fpmult_e8m23_lxa \
    tb_top_fpmult_e8m23_lmul \
    tb_top_fpmult_e8m23_ssm_m12 \
    tb_top_fpmult_e8m23_ssm_m12c \
    tb_top_fpmult_e8m23_ssm_m14 \
    tb_top_fpmult_e8m23_ssm_m14c \
    tb_top_fpmult_e8m23_ssm_m16 \
    tb_top_fpmult_e8m23_ssm_m16c \
    tb_top_fpmult_e8m23_ssm_m18 \
    tb_top_fpmult_e8m23_ssm_m18c \
    tb_top_fpmult_e8m23_vivado_compare
do
    echo "Running simulation: $top"
    vivado -mode batch -source HW/scripts/run_sim_one.tcl -tclargs <project.xpr> "$top" results || break
done
```

This produces files such as:

```text
results/fpmult_e8m23_acc1.csv
results/fpmult_e8m23_acc2.csv
results/fpmult_e8m23_acc_vivado.csv
results/fpmult_e8m23_lmul.csv
results/fpmult_e8m23_lxa.csv
results/fpmult_e8m23_mxa1.csv
results/fpmult_e8m23_mxa2.csv
results/fpmult_e8m23_ssm_m12.csv
results/fpmult_e8m23_ssm_m12c.csv
results/fpmult_e8m23_ssm_m14.csv
results/fpmult_e8m23_ssm_m14c.csv
results/fpmult_e8m23_ssm_m16.csv
results/fpmult_e8m23_ssm_m16c.csv
results/fpmult_e8m23_ssm_m18.csv
results/fpmult_e8m23_ssm_m18c.csv
results/fpmult_e8m23_viv_reference.csv
```

A tidy little CSV factory.

---

## 1.9 Running One Synthesis / Implementation Flow

Use:

```bash
vivado -mode batch -source HW/scripts/run_synth_one.tcl -tclargs <project.xpr> <synth_top> [out_report_dir]
```

Example:

```bash
vivado -mode batch -source HW/scripts/run_synth_one.tcl -tclargs my_project.xpr timing_fpmult_e8m23_mxa1 reports
```

If `out_report_dir` is omitted, the script defaults to:

```text
<repo_root>/reports
```

For each top, a directory is created:

```text
reports/<synth_top>/
```

containing synthesis and implementation reports.

---

## 1.10 Running All Synthesis / Timing Experiments

The following loops generate the report directories you listed.

### Floating-point timing tops

```bash
mkdir -p reports

for top in \
    timing_fpmult_e8m23_acc_vivado \
    timing_fpmult_e8m23_lmul \
    timing_fpmult_e8m23_lxa \
    timing_fpmult_e8m23_mxa1 \
    timing_fpmult_e8m23_mxa2 \
    timing_fpmult_e8m23_ssm_m12 \
    timing_fpmult_e8m23_ssm_m12c \
    timing_fpmult_e8m23_ssm_m18 \
    timing_fpmult_e8m23_ssm_m18c
do
    echo "Running synthesis: $top"
    vivado -mode batch -source HW/scripts/run_synth_one.tcl -tclargs <project.xpr> "$top" reports || break
done
```

### Integer timing tops

```bash
for top in \
    timing_mult_3x3_acc1 \
    timing_mult_3x3_acc2 \
    timing_mult_3x3_mxa1 \
    timing_mult_3x3_mxa2 \
    timing_mult_6x6_acc1 \
    timing_mult_6x6_acc2 \
    timing_mult_6x6_mxa1 \
    timing_mult_6x6_mxa2 \
    timing_mult_12x12_acc1 \
    timing_mult_12x12_acc2 \
    timing_mult_12x12_mxa1 \
    timing_mult_12x12_mxa2 \
    timing_mult_24x24_acc1 \
    timing_mult_24x24_acc2 \
    timing_mult_24x24_lxa \
    timing_mult_24x24_mxa1 \
    timing_mult_24x24_mxa2 \
    timing_mult_24x24_mxa2_plus_1 \
    timing_mult_24x24_mxa2_plus_2 \
    timing_mult_24x24_mxa2_plus_3 \
    timing_mult_24x24_mxa2_plus_4 \
    timing_mult_24x24_mxa2_plus_5 \
    timing_mult_24x24_mxa2_plus_6
do
    echo "Running synthesis: $top"
    vivado -mode batch -source HW/scripts/run_synth_one.tcl -tclargs <project.xpr> "$top" reports || break
done
```

---

## 1.11 Generated Hardware Outputs

### Simulation outputs
Generated under:

```text
results/
```

Example:

```text
results/
├── fpmult_e8m23_acc1.csv
├── fpmult_e8m23_acc2.csv
├── fpmult_e8m23_acc_vivado.csv
├── fpmult_e8m23_lmul.csv
├── fpmult_e8m23_lxa.csv
├── fpmult_e8m23_mxa1.csv
├── fpmult_e8m23_mxa2.csv
├── fpmult_e8m23_ssm_m12.csv
├── fpmult_e8m23_ssm_m12c.csv
├── fpmult_e8m23_ssm_m14.csv
├── fpmult_e8m23_ssm_m14c.csv
├── fpmult_e8m23_ssm_m16.csv
├── fpmult_e8m23_ssm_m16c.csv
├── fpmult_e8m23_ssm_m18.csv
├── fpmult_e8m23_ssm_m18c.csv
└── fpmult_e8m23_viv_reference.csv
```

### Synthesis outputs
Generated under:

```text
reports/
```

Example directories:

```text
reports/
├── timing_fpmult_e8m23_acc_vivado
├── timing_fpmult_e8m23_lmul
├── timing_fpmult_e8m23_lxa
├── timing_fpmult_e8m23_mxa1
├── timing_fpmult_e8m23_mxa2
├── timing_fpmult_e8m23_ssm_m12
├── timing_fpmult_e8m23_ssm_m12c
├── timing_fpmult_e8m23_ssm_m18
├── timing_fpmult_e8m23_ssm_m18c
├── timing_mult_12x12_acc1
├── timing_mult_12x12_acc2
├── timing_mult_12x12_mxa1
├── timing_mult_12x12_mxa2
├── timing_mult_24x24_acc1
├── timing_mult_24x24_acc2
├── timing_mult_24x24_lxa
├── timing_mult_24x24_mxa1
├── timing_mult_24x24_mxa2
├── timing_mult_24x24_mxa2_plus_1
├── timing_mult_24x24_mxa2_plus_2
├── timing_mult_24x24_mxa2_plus_3
├── timing_mult_24x24_mxa2_plus_4
├── timing_mult_24x24_mxa2_plus_5
├── timing_mult_24x24_mxa2_plus_6
├── timing_mult_3x3_acc1
├── timing_mult_3x3_acc2
├── timing_mult_3x3_mxa1
├── timing_mult_3x3_mxa2
├── timing_mult_6x6_acc1
├── timing_mult_6x6_acc2
├── timing_mult_6x6_mxa1
└── timing_mult_6x6_mxa2
```

Each report directory contains files such as:

- `post_synth_utilization.rpt`
- `post_synth_timing_summary.rpt`
- `post_synth_power.rpt`
- `post_impl_utilization.rpt`
- `post_impl_utilization_hier.rpt`
- `post_impl_timing_summary.rpt`
- `post_impl_timing.rpt`
- `post_impl_power.rpt`
- `post_impl_route_status.rpt`
- `post_impl_drc.rpt`
- `post_impl_clock_utilization.rpt`

## 1.12 Summarizing Vivado Reports

`HW/scripts/extract_metrics.py` summarizes the report directories written
by `run_synth_one.tcl`:

```bash
python3 HW/scripts/extract_metrics.py reports --csv reports_summary.csv
```

For every `timing_*` directory it prints the post-route LUTs, CARRY8
blocks and CLBs, the critical-path delay (data-path delay of the worst
register-to-register path), WNS, `Fmax = 1/(T - WNS)` (T = 5 ns virtual
clock, `--period` to change), the dynamic power of the combinational
datapath at 200 MHz and the power-delay product (PDP = power x CPD, pJ).

The power is read from `post_impl_power.xpe` (vectorless activity). It is
the sum of the unclocked and high-fanout-net logic power of the `inst0`
hierarchy and excludes static power, the clock tree, I/O and the
registers of the timing wrapper. All designs use the same wrapper, the
same constraint (`HW/constraints.xdc`) and the same flow. The results in
the paper were obtained with Vivado 2022.2 for the device
`xczu7ev-ffvc1156-2-e`.

---

# 2. Software Side

## 2.1 Software Directory Layout

### `SW/core/`
Core C++ implementations:

- `fpmult_e8m23.cpp`

### `SW/include/`
Headers:

- `fpmult_e8m23.h`

### `SW/eval/`
C++ evaluation tools:

- `report_error_metrics.cpp`
- `fpmult_e8m23_cmp_hw_impl.cpp`

### `SW/py/`
Python bindings and image-processing application code:

- `fpmult_pybind.cpp`
- `image_applications.py`
- `setup.py`

### `SW/helpers/`
Helper scripts:

- `convert_out_images_to_pdf.py`
- `generate_latex_tables.py`
- `generate_latex_tables_with_images.py`

### `SW/test_images/`
Input HDR/EXR images for image-processing experiments.

---

## 2.2 Ubuntu 24.04 Package Installation

This project is intended to work on Ubuntu 24.04 using system-wide Python packages installed with `apt`.

Install prerequisites with:

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    g++ \
    make \
    python3 \
    python3-dev \
    python3-setuptools \
    python3-numpy \
    python3-opencv \
    python3-imageio \
    python3-matplotlib \
    python3-pandas \
    pybind11-dev \
    python3-pybind11 \
    gimp
```

### Why these packages are needed

#### Build tools
- `build-essential`
- `g++`
- `make`

Used for:
- compiling C++ evaluation tools
- building the Python extension module

#### Python runtime and development
- `python3`
- `python3-dev`
- `python3-setuptools`

Used for:
- running Python scripts
- building `fpmult_py`

#### Python scientific/image packages
- `python3-numpy`
- `python3-opencv`
- `python3-imageio`
- `python3-matplotlib`
- `python3-pandas`

Used by:
- image-processing scripts
- plotting / saving outputs
- CSV / LaTeX summary generation

#### pybind11
- `pybind11-dev`
- `python3-pybind11`

Used by:
- `SW/py/setup.py`
- `SW/py/fpmult_pybind.cpp`

#### External tool
- `gimp`

Used by:
- `convert_out_images_to_pdf.py`

---

## 2.3 Verifying Software Installation

### Verify Python imports

```bash
python3 -c "import numpy, cv2, imageio, matplotlib, pandas, setuptools, pybind11; print('ok')"
```

### Verify compiler and make

```bash
g++ --version
make --version
```

### Verify GIMP

```bash
gimp --version
```

---

## 2.4 Building the Software

From `SW/`:

```bash
cd SW
make
```

Default `make` does only:

- compile `eval/report_error_metrics`
- compile `eval/fpmult_e8m23_cmp_hw_impl`
- build Python extension in `py/`

It does **not** run applications by default.

---

## 2.5 SW Makefile Targets

From `SW/`:

### Build only
```bash
make
```

### Build C++ eval tools only
```bash
make eval
```

### Build Python extension only
```bash
make py
```

### Run image applications
```bash
make images
```

### Convert generated images to PDF
```bash
make pdf
```

### Generate LaTeX summary tables
```bash
make latex
```

### Generate LaTeX tables with embedded images
```bash
make latex-images
```

### Run whole post-processing pipeline
```bash
make results
```

### Clean build outputs
```bash
make clean
```

### Clean generated image/PDF outputs
```bash
make clean-results
```

### Clean everything
```bash
make clean-all
```

---

## 2.6 C++ Evaluation Tools

### `report_error_metrics`
Computes error metrics directly from software models.

In `fp32` mode the tool evaluates 2^26 random normalized operand pairs
(random sign, biased exponent in [1,254], random fraction). Pairs whose
exact product exponent is outside [2,253] are rejected, so NaN, Inf, zero,
subnormal, overflow and underflow cases are not evaluated. Every chunk uses
a fixed seed, so results are reproducible and independent of the thread
count. The reference is `fpmult_e8m23_viv_acc` (round-to-nearest-even).
Error distances (ED) are integer distances between IEEE-754 bit patterns,
i.e. ULPs; MRED is the mean of ED divided by the exact bit pattern and NMED
is MED/MaxED.

Build:
```bash
cd SW/eval
make
```

Example usage:

```bash
./report_error_metrics acc1 3
./report_error_metrics acc2 24
./report_error_metrics mxa1 12
./report_error_metrics mxa2 24
./report_error_metrics lxa 24
./report_error_metrics viv_acc fp32
./report_error_metrics mxa1 fp32
./report_error_metrics lmul fp32
./report_error_metrics ssm_m12 fp32
./report_error_metrics ssm_m12 23
./report_error_metrics ssm_m12c 23
```

### `fpmult_e8m23_cmp_hw_impl`
Compares software model output against hardware-generated CSVs.

Example usage:

```bash
./fpmult_e8m23_cmp_hw_impl viv_acc /path/to/results/fpmult_e8m23_acc_vivado.csv
./fpmult_e8m23_cmp_hw_impl mxa1 /path/to/results/fpmult_e8m23_mxa1.csv
./fpmult_e8m23_cmp_hw_impl mxa2 /path/to/results/fpmult_e8m23_mxa2.csv
./fpmult_e8m23_cmp_hw_impl lxa /path/to/results/fpmult_e8m23_lxa.csv
./fpmult_e8m23_cmp_hw_impl lmul /path/to/results/fpmult_e8m23_lmul.csv
./fpmult_e8m23_cmp_hw_impl ssm_m12 /path/to/results/fpmult_e8m23_ssm_m12.csv
./fpmult_e8m23_cmp_hw_impl ssm_m18c /path/to/results/fpmult_e8m23_ssm_m18c.csv
```

If no CSV path is provided, the tool uses its built-in default path.

---

## 2.7 Python Extension

The Python extension is built by:

```bash
cd SW
make py
```

or directly:

```bash
cd SW/py
python3 setup.py build_ext --inplace
```

This produces a module named:

```text
fpmult_py
```

Used by:

- `SW/py/image_applications.py`

---

## 2.8 Image-Processing Evaluation Flow

The script:

```text
SW/py/image_applications.py
```

does the following:

1. loads HDR/EXR images from `SW/test_images/`
2. canonicalizes HDR inputs into `SW/test_images_canonical/`
3. runs image-processing applications using different multiplier models
4. writes outputs into `SW/out_images/`
5. writes summary CSV into `SW/out_images/summary.csv`

### Supported models
- `viv_acc`
- `mxa1`
- `mxa2`
- `lxa`
- `lmul`
- `ssm_m12`
- `ssm_m12c`
- `ssm_m18`
- `ssm_m18c`

### Applications
- `sharpen5`
- `laplacian3`
- `sharpen3`
- `sobel`
- `tone_map`
- `sharpen5_repeat_5`
- `sharpen5_repeat_10`
- `unsharp_alpha_1.0`
- `unsharp_alpha_1.5`
- `sharpen5_diff_1_2`
- `sharpen5_diff_1_3`

### Run it
From `SW/`:

```bash
make images
```

---

## 2.9 PDF and LaTeX Generation

### Convert output images to PDF
```bash
cd SW
make pdf
```

### Generate LaTeX tables
```bash
make latex
```

Output:
```text
SW/out_images/results_per_application.tex
```

### Generate LaTeX longtables with embedded images
```bash
make latex-images
```

Output:
```text
SW/out_images/results_per_application_with_images_longtable.tex
```

---

# 3. Typical End-to-End Workflows

## 3.1 Hardware simulation only

```bash
mkdir -p results

for top in \
    tb_top_fpmult_e8m23_acc_vivado \
    tb_top_fpmult_e8m23_acc1 \
    tb_top_fpmult_e8m23_acc2 \
    tb_top_fpmult_e8m23_mxa1 \
    tb_top_fpmult_e8m23_mxa2 \
    tb_top_fpmult_e8m23_lxa \
    tb_top_fpmult_e8m23_lmul \
    tb_top_fpmult_e8m23_ssm_m12 \
    tb_top_fpmult_e8m23_ssm_m12c \
    tb_top_fpmult_e8m23_ssm_m14 \
    tb_top_fpmult_e8m23_ssm_m14c \
    tb_top_fpmult_e8m23_ssm_m16 \
    tb_top_fpmult_e8m23_ssm_m16c \
    tb_top_fpmult_e8m23_ssm_m18 \
    tb_top_fpmult_e8m23_ssm_m18c \
    tb_top_fpmult_e8m23_vivado_compare
do
    vivado -mode batch -source HW/scripts/run_sim_one.tcl -tclargs <project.xpr> "$top" results || break
done
```

---

## 3.2 Hardware synthesis only

```bash
mkdir -p reports

for top in \
    timing_fpmult_e8m23_acc_vivado \
    timing_fpmult_e8m23_lmul \
    timing_fpmult_e8m23_lxa \
    timing_fpmult_e8m23_mxa1 \
    timing_fpmult_e8m23_mxa2 \
    timing_fpmult_e8m23_ssm_m12 \
    timing_fpmult_e8m23_ssm_m12c \
    timing_fpmult_e8m23_ssm_m18 \
    timing_fpmult_e8m23_ssm_m18c \
    timing_mult_3x3_acc1 \
    timing_mult_3x3_acc2 \
    timing_mult_3x3_mxa1 \
    timing_mult_3x3_mxa2 \
    timing_mult_6x6_acc1 \
    timing_mult_6x6_acc2 \
    timing_mult_6x6_mxa1 \
    timing_mult_6x6_mxa2 \
    timing_mult_12x12_acc1 \
    timing_mult_12x12_acc2 \
    timing_mult_12x12_mxa1 \
    timing_mult_12x12_mxa2 \
    timing_mult_24x24_acc1 \
    timing_mult_24x24_acc2 \
    timing_mult_24x24_lxa \
    timing_mult_24x24_mxa1 \
    timing_mult_24x24_mxa2 \
    timing_mult_24x24_mxa2_plus_1 \
    timing_mult_24x24_mxa2_plus_2 \
    timing_mult_24x24_mxa2_plus_3 \
    timing_mult_24x24_mxa2_plus_4 \
    timing_mult_24x24_mxa2_plus_5 \
    timing_mult_24x24_mxa2_plus_6
do
    vivado -mode batch -source HW/scripts/run_synth_one.tcl -tclargs <project.xpr> "$top" reports || break
done
```

---

## 3.3 Software build and image experiments

```bash
cd SW
make
make images
make pdf
make latex
make latex-images
```

---

## 3.4 Hardware/software FP32 comparison flow

1. Generate CSVs from hardware simulation into `results/`
2. Build software tools:

```bash
cd SW
make
```

3. Compare software model against hardware CSV:

```bash
cd SW/eval
./fpmult_e8m23_cmp_hw_impl viv_acc ../../results/fpmult_e8m23_acc_vivado.csv
./fpmult_e8m23_cmp_hw_impl mxa1 ../../results/fpmult_e8m23_mxa1.csv
./fpmult_e8m23_cmp_hw_impl mxa2 ../../results/fpmult_e8m23_mxa2.csv
./fpmult_e8m23_cmp_hw_impl lxa ../../results/fpmult_e8m23_lxa.csv
./fpmult_e8m23_cmp_hw_impl lmul ../../results/fpmult_e8m23_lmul.csv
./fpmult_e8m23_cmp_hw_impl ssm_m12 ../../results/fpmult_e8m23_ssm_m12.csv
./fpmult_e8m23_cmp_hw_impl ssm_m18c ../../results/fpmult_e8m23_ssm_m18c.csv
```

---

# 4. Notes and Assumptions

- Vivado project setup is external to this repository.
- The Tcl scripts assume the required RTL, testbench, timing wrapper, and constraints files are already included in the Vivado project.
- `tb_fpmult_vivado_compare.v` requires the Vivado-generated floating-point reference module `fpmult_e8m23_viv_reference`.
- Python image-processing scripts assume HDR/EXR support is available in the installed OpenCV build.
- PDF generation helper scripts require `gimp` to be installed and callable from the shell.
- `SW/py/setup.py` expects `pybind11` to be importable from Python.

---

# 5. Outputs Produced by the Project

## Hardware outputs
- `results/*.csv`
- `reports/<timing_top>/*.rpt`
- `reports/<timing_top>/*.xpe`

## Software outputs
- `SW/test_images_canonical/*`
- `SW/out_images/*`
- `SW/out_images/summary.csv`
- `SW/out_images/results_per_application.tex`
- `SW/out_images/results_per_application_with_images_longtable.tex`
- `SW/out_pdfs/*`

---

# 6. Suggested First-Time Setup

From repository root:

## Install Ubuntu packages
```bash
sudo apt update
sudo apt install -y \
    build-essential \
    g++ \
    make \
    python3 \
    python3-dev \
    python3-setuptools \
    python3-numpy \
    python3-opencv \
    python3-imageio \
    python3-matplotlib \
    python3-pandas \
    pybind11-dev \
    python3-pybind11 \
    gimp
```

## Build software
```bash
cd SW
make
```

## Run image experiments
```bash
make images
```

## Generate PDFs and LaTeX
```bash
make pdf
make latex
make latex-images
```

## Run one hardware simulation
```bash
cd ..
vivado -mode batch -source HW/scripts/run_sim_one.tcl -tclargs <project.xpr> tb_top_fpmult_e8m23_mxa1 results
```

## Run one synthesis
```bash
vivado -mode batch -source HW/scripts/run_synth_one.tcl -tclargs <project.xpr> timing_fpmult_e8m23_mxa1 reports
```

---

# 7. Future Improvements

Possible future additions:

- Makefile targets for HW simulation and synthesis loops
- automatic aggregation of Vivado report summaries
- automatic parsing of timing/utilization/power reports
- automated regression scripts for all FP32 and integer designs
- unified top-level runner script for HW + SW flows

---

# 8. License
