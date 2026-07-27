CXX := g++
PYTHON := python3
CXXFLAGS := -O2 -std=c++17 -pthread -Iinclude

CORE_SRC := core/fpmult_e8m23.cpp

EVAL_DIR := eval
PY_DIR := py
HELPERS_DIR := helpers

EVAL_TARGETS := \
	$(EVAL_DIR)/report_error_metrics \
	$(EVAL_DIR)/fpmult_e8m23_cmp_hw_impl

all: eval py

eval: $(EVAL_TARGETS)

$(EVAL_DIR)/report_error_metrics: $(EVAL_DIR)/report_error_metrics.cpp $(CORE_SRC) include/fpmult_e8m23.h
	$(CXX) $(CXXFLAGS) $^ -o $@

$(EVAL_DIR)/fpmult_e8m23_cmp_hw_impl: $(EVAL_DIR)/fpmult_e8m23_cmp_hw_impl.cpp $(CORE_SRC) include/fpmult_e8m23.h
	$(CXX) $(CXXFLAGS) $^ -o $@

py:
	cd $(PY_DIR) && $(PYTHON) setup.py build_ext --inplace

images:
	$(PYTHON) $(PY_DIR)/image_applications.py

pdf:
	$(PYTHON) $(HELPERS_DIR)/convert_out_images_to_pdf.py

latex:
	$(PYTHON) $(HELPERS_DIR)/generate_latex_tables.py

latex-images:
	$(PYTHON) $(HELPERS_DIR)/generate_latex_tables_with_images.py

results: images pdf latex latex-images

clean:
	rm -f $(EVAL_TARGETS)
	rm -rf $(PY_DIR)/build
	rm -f $(PY_DIR)/fpmult_py*.so
	rm -f $(PY_DIR)/fpmult_py*.pyd

clean-results:
	rm -rf test_images_canonical
	rm -rf out_images
	rm -rf out_pdfs

clean-all: clean clean-results
	find $(PY_DIR) -type d -name "__pycache__" -exec rm -rf {} +
	find $(PY_DIR) -type f -name "*.pyc" -delete
	find $(HELPERS_DIR) -type d -name "__pycache__" -exec rm -rf {} +
	find $(HELPERS_DIR) -type f -name "*.pyc" -delete

.PHONY: all eval py images pdf latex latex-images results clean clean-results clean-all
