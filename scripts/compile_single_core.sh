#!/bin/bash
set -e

# Extra latency (in nanoseconds) added to every DRAM access when ENABLE_CXL_LATENCY=ON.
# Approximates the CXL.mem link round-trip on top of native DRAM timings.
# Override at invocation time, e.g.: CXL_ADDITIONAL_LATENCY_NS=120 ./scripts/compile_single_core.sh
CXL_ADDITIONAL_LATENCY_NS="${CXL_ADDITIONAL_LATENCY_NS:-80}"

# Compiling the baseline (legacy & extended formats).
mkdir -p build/1_cores_cascade_lake_800mtps_legacy
mkdir -p build/1_cores_cascade_lake_800mtps

cd build/1_cores_cascade_lake_800mtps_legacy
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_800mtps_legacy" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=ON -DENABLE_FSP=OFF -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=OFF && make -j
cd ../1_cores_cascade_lake_800mtps
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_800mtps" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=OFF -DENABLE_FSP=OFF -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=OFF && make -j
cd ../../

# Compiling Hermes (legacy & extended formats).
mkdir -p build/1_cores_cascade_lake_hermes_o_800mtps_legacy
mkdir -p build/1_cores_cascade_lake_hermes_o_800mtps

cd build/1_cores_cascade_lake_hermes_o_800mtps_legacy
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_hermes_o_800mtps_legacy" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=ON -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=OFF && make -j
cd ../1_cores_cascade_lake_hermes_o_800mtps
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_hermes_o_800mtps" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=OFF -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=OFF && make -j
cd ../../

# Compiling TLP (legacy & extended formats).
mkdir -p build/1_cores_cascade_lake_tlp_800mtps_legacy
mkdir -p build/1_cores_cascade_lake_tlp_800mtps

cd build/1_cores_cascade_lake_tlp_800mtps_legacy
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_tlp_800mtps_legacy" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=ON -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=ON -DENABLE_SSP=ON -DENABLE_CXL_LATENCY=OFF && make -j
cd ../1_cores_cascade_lake_tlp_800mtps
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_tlp_800mtps" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=OFF -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=ON -DENABLE_SSP=ON -DENABLE_CXL_LATENCY=OFF && make -j
cd ../../

################################################################################
# CXL Latency variants                                                         #
#                                                                              #
# Native DRAM timings (tRP/tRCD/tCAS) are kept identical to the non-CXL build. #
# Instead, every DRAM access is charged an extra CXL_ADDITIONAL_LATENCY_NS     #
# (default 80 ns) to approximate the CXL.mem link round-trip. Override the    #
# value at invocation time, e.g.:                                              #
#   CXL_ADDITIONAL_LATENCY_NS=120 ./scripts/compile_single_core.sh             #
################################################################################

echo "[compile_single_core] CXL variants will be built with CXL_ADDITIONAL_LATENCY_NS=${CXL_ADDITIONAL_LATENCY_NS} ns"

# Compiling the baseline with CXL latency (legacy & extended formats).
mkdir -p build/1_cores_cascade_lake_800mtps_cxl_legacy
mkdir -p build/1_cores_cascade_lake_800mtps_cxl

cd build/1_cores_cascade_lake_800mtps_cxl_legacy
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_800mtps_cxl_legacy" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=ON -DENABLE_FSP=OFF -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=ON -DCXL_ADDITIONAL_LATENCY_NS="${CXL_ADDITIONAL_LATENCY_NS}" && make -j
cd ../1_cores_cascade_lake_800mtps_cxl
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_800mtps_cxl" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=OFF -DENABLE_FSP=OFF -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=ON -DCXL_ADDITIONAL_LATENCY_NS="${CXL_ADDITIONAL_LATENCY_NS}" && make -j
cd ../../

# Compiling Hermes with CXL latency (legacy & extended formats).
mkdir -p build/1_cores_cascade_lake_hermes_o_800mtps_cxl_legacy
mkdir -p build/1_cores_cascade_lake_hermes_o_800mtps_cxl

cd build/1_cores_cascade_lake_hermes_o_800mtps_cxl_legacy
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_hermes_o_800mtps_cxl_legacy" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=ON -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=ON -DCXL_ADDITIONAL_LATENCY_NS="${CXL_ADDITIONAL_LATENCY_NS}" && make -j
cd ../1_cores_cascade_lake_hermes_o_800mtps_cxl
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_hermes_o_800mtps_cxl" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=OFF -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=OFF -DENABLE_SSP=OFF -DENABLE_CXL_LATENCY=ON -DCXL_ADDITIONAL_LATENCY_NS="${CXL_ADDITIONAL_LATENCY_NS}" && make -j
cd ../../

# Compiling TLP with CXL latency (legacy & extended formats).
mkdir -p build/1_cores_cascade_lake_tlp_800mtps_cxl_legacy
mkdir -p build/1_cores_cascade_lake_tlp_800mtps_cxl

cd build/1_cores_cascade_lake_tlp_800mtps_cxl_legacy
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_tlp_800mtps_cxl_legacy" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=ON -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=ON -DENABLE_SSP=ON -DENABLE_CXL_LATENCY=ON -DCXL_ADDITIONAL_LATENCY_NS="${CXL_ADDITIONAL_LATENCY_NS}" && make -j
cd ../1_cores_cascade_lake_tlp_800mtps_cxl
cmake -G "Unix Makefiles" ../../ -DCMAKE_BUILD_TYPE=Release -DSIMULATOR_OUTPUT_DIRECTORY="1_cores_cascade_lake_tlp_800mtps_cxl" -DCHAMPSIM_CPU_NUMBER_CORE=1 -DCHAMPSIM_CPU_DRAM_IO_FREQUENCY=800 -DLEGACY_TRACE=OFF -DENABLE_FSP=ON -DENABLE_DELAYED_FSP=OFF -DENABLE_BIMODAL_FSP=ON -DENABLE_SSP=ON -DENABLE_CXL_LATENCY=ON -DCXL_ADDITIONAL_LATENCY_NS="${CXL_ADDITIONAL_LATENCY_NS}" && make -j
cd ../../

# Copying prefetchers and replacement policies plugins.
cp bin/prefetchers/* prefetchers/
cp bin/replacements/* replacements/

cp prefetchers/libl1d_ipcp.so prefetchers/libl1d_ipcp_iso.so
