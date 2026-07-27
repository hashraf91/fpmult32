CXX := g++
CXXFLAGS := -O2 -std=c++17 -pthread -I../include
CORE_SRC := ../core/fpmult_e8m23.cpp

all: report_error_metrics fpmult_e8m23_cmp_hw_impl

report_error_metrics: report_error_metrics.cpp $(CORE_SRC)
	$(CXX) $(CXXFLAGS) $^ -o $@

fpmult_e8m23_cmp_hw_impl: fpmult_e8m23_cmp_hw_impl.cpp $(CORE_SRC)
	$(CXX) $(CXXFLAGS) $^ -o $@

clean:
	rm -f report_error_metrics fpmult_e8m23_cmp_hw_impl

.PHONY: all clean
