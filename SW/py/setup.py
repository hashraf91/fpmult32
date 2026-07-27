from setuptools import setup, Extension
from pathlib import Path
import pybind11

here = Path(__file__).resolve().parent
project_root = here.parent
include_dir = project_root / "include"
core_dir = project_root / "core"

ext_modules = [
    Extension(
        "fpmult_py",
        sources=[
            str(here / "fpmult_pybind.cpp"),
            str(core_dir / "fpmult_e8m23.cpp"),
        ],
        include_dirs=[
            pybind11.get_include(),
            str(include_dir),
        ],
        language="c++",
        extra_compile_args=["-O3", "-std=c++17"],
    ),
]

setup(
    name="fpmult_py",
    version="0.1.0",
    ext_modules=ext_modules,
)
