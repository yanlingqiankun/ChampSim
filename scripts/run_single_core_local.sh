#!/bin/bash
set -e

# ============================================================================
# run_single_core_local.sh
# 在本机并行运行 ChampSim 模拟，替代原有的 SLURM 调度。
# 使用方法: ./scripts/run_single_core_local.sh [--mode=normal|cxl|all] [并行度]
# 例如:
#   ./scripts/run_single_core_local.sh --mode=normal 8   # 只跑普通模式
#   ./scripts/run_single_core_local.sh --mode=cxl 8      # 只跑CXL延时模式
#   ./scripts/run_single_core_local.sh --mode=all 8      # 跑全部（默认）
#   ./scripts/run_single_core_local.sh 8                 # 等同于 --mode=all 8
# Ctrl+C 会杀掉所有正在运行的子进程。
# ============================================================================

# ============================== 参数解析 ======================================
RUN_MODE="all"  # 默认跑全部

# 解析命名参数
POSITIONAL_ARGS=()
for arg in "$@"; do
  case $arg in
    --mode=*)
      RUN_MODE="${arg#*=}"
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$arg")
      ;;
  esac
done

# 验证 mode 参数
if [[ "$RUN_MODE" != "normal" && "$RUN_MODE" != "cxl" && "$RUN_MODE" != "all" ]]; then
  echo "[ERROR] 无效的 --mode 参数: ${RUN_MODE}"
  echo "  可选值: normal, cxl, all"
  exit 1
fi

# ============================== 配置区域 ======================================
TRACES_DIR="/data/home/dongfk/mshr-sim"
WORKING_DIR="$(cd "$(dirname "$0")/.." && pwd)"  # 项目根目录
TRACE_DIR="${TRACES_DIR}/traces/"
# OUTPUT_DIR="${WORKING_DIR}/results/single_core/100M/100M"
OUTPUT_DIR="${WORKING_DIR}/results/single_core/20M/30M"

# 并行度：默认为 CPU 核心数的一半，也可通过命令行参数指定
MAX_PARALLEL=${POSITIONAL_ARGS[0]:-$(( $(nproc) / 2 ))}
if [ "$MAX_PARALLEL" -lt 1 ]; then
  MAX_PARALLEL=1
fi

echo "=============================================="
echo " ChampSim 本地并行运行脚本"
echo " 工作目录:  ${WORKING_DIR}"
echo " Trace目录: ${TRACE_DIR}"
echo " 输出目录:  ${OUTPUT_DIR}"
echo " 运行模式:  ${RUN_MODE}"
echo " 并行度:    ${MAX_PARALLEL}"
echo "=============================================="

# ============================== 信号处理 ======================================
# 记录所有子进程 PID，Ctrl+C 时全部杀掉
CHILD_PIDS=()
RUNNING=true

cleanup() {
  echo ""
  echo "[INFO] 收到中断信号，正在终止所有子进程..."
  RUNNING=false
  for pid in "${CHILD_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null
    fi
  done
  # 等一小会儿，如果还没退出就强制杀
  sleep 2
  for pid in "${CHILD_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null
    fi
  done
  echo "[INFO] 所有子进程已终止。"
  exit 1
}

trap cleanup SIGINT SIGTERM

# ============================== Trace 列表 ====================================
TRACES_ARRAY=()
for trace in ${TRACE_DIR}/*sdc-*.champsimtrace.xz; do
  [ -e "$trace" ] || continue
  filename=$(basename -- "$trace")
  TRACES_ARRAY+=("$filename")
done

if [ ${#TRACES_ARRAY[@]} -eq 0 ]; then
  echo "[ERROR] 在 ${TRACE_DIR} 中没有找到任何 trace 文件 (*sdc-*.champsimtrace.xz)"
  exit 1
fi

echo "[INFO] 找到 ${#TRACES_ARRAY[@]} 个 trace 文件"

# ============================== 配置列表 ======================================
# 普通模式的配置和二进制
NORMAL_CONFIGS=(
  "baseline_cascade_lake_no_prefetchers"

  "baseline_cascade_lake_ipcp"
  "baseline_cascade_lake_ipcp_spp_ppf"
  "baseline_cascade_lake_ipcp_hermes_o"
  "baseline_cascade_lake_ipcp_spp_ppf_hermes_o"
  "baseline_cascade_lake_ipcp_hermes_o_double"
  "baseline_cascade_lake_ipcp_tlp_layered_core_l1d_f20_-25"
  "baseline_cascade_lake_ipcp_iso_prefetcher"
  "baseline_cascade_lake_ipcp_mshr256"

  "baseline_cascade_lake_berti"
  "baseline_cascade_lake_berti_spp_ppf"
  "baseline_cascade_lake_berti_hermes_o"
  "baseline_cascade_lake_berti_spp_ppf_hermes_o"
  "baseline_cascade_lake_berti_hermes_o_double"
  "baseline_cascade_lake_berti_tlp_layered_core_l1d_f20_-25"
  "baseline_cascade_lake_berti_iso_prefetcher"
  "baseline_cascade_lake_berti_mshr256"
)

NORMAL_BINARIES=(
  "1_cores_cascade_lake_800mtps"

  "1_cores_cascade_lake_800mtps"
  "1_cores_cascade_lake_800mtps"
  "1_cores_cascade_lake_hermes_o_800mtps"
  "1_cores_cascade_lake_hermes_o_800mtps"
  "1_cores_cascade_lake_hermes_o_800mtps"
  "1_cores_cascade_lake_tlp_800mtps"
  "1_cores_cascade_lake_800mtps"
  "1_cores_cascade_lake_800mtps"

  "1_cores_cascade_lake_800mtps"
  "1_cores_cascade_lake_800mtps"
  "1_cores_cascade_lake_hermes_o_800mtps"
  "1_cores_cascade_lake_hermes_o_800mtps"
  "1_cores_cascade_lake_hermes_o_800mtps"
  "1_cores_cascade_lake_tlp_800mtps"
  "1_cores_cascade_lake_800mtps"
  "1_cores_cascade_lake_800mtps"
)

# CXL 延时模式的配置和二进制（使用相同的配置文件，但使用 CXL 编译的二进制）
CXL_CONFIGS=(
  "baseline_cascade_lake_no_prefetchers"

  "baseline_cascade_lake_ipcp"
  "baseline_cascade_lake_ipcp_spp_ppf"
  "baseline_cascade_lake_ipcp_hermes_o"
  "baseline_cascade_lake_ipcp_spp_ppf_hermes_o"
  "baseline_cascade_lake_ipcp_hermes_o_double"
  "baseline_cascade_lake_ipcp_tlp_layered_core_l1d_f20_-25"
  "baseline_cascade_lake_ipcp_iso_prefetcher"
  "baseline_cascade_lake_ipcp_mshr256"

  "baseline_cascade_lake_berti"
  "baseline_cascade_lake_berti_spp_ppf"
  "baseline_cascade_lake_berti_hermes_o"
  "baseline_cascade_lake_berti_spp_ppf_hermes_o"
  "baseline_cascade_lake_berti_hermes_o_double"
  "baseline_cascade_lake_berti_tlp_layered_core_l1d_f20_-25"
  "baseline_cascade_lake_berti_iso_prefetcher"
  "baseline_cascade_lake_berti_mshr256"
)

CXL_BINARIES=(
  "1_cores_cascade_lake_800mtps_cxl"

  "1_cores_cascade_lake_800mtps_cxl"
  "1_cores_cascade_lake_800mtps_cxl"
  "1_cores_cascade_lake_hermes_o_800mtps_cxl"
  "1_cores_cascade_lake_hermes_o_800mtps_cxl"
  "1_cores_cascade_lake_hermes_o_800mtps_cxl"
  "1_cores_cascade_lake_tlp_800mtps_cxl"
  "1_cores_cascade_lake_800mtps_cxl"
  "1_cores_cascade_lake_800mtps_cxl"

  "1_cores_cascade_lake_800mtps_cxl"
  "1_cores_cascade_lake_800mtps_cxl"
  "1_cores_cascade_lake_hermes_o_800mtps_cxl"
  "1_cores_cascade_lake_hermes_o_800mtps_cxl"
  "1_cores_cascade_lake_hermes_o_800mtps_cxl"
  "1_cores_cascade_lake_tlp_800mtps_cxl"
  "1_cores_cascade_lake_800mtps_cxl"
  "1_cores_cascade_lake_800mtps_cxl"
)

# 根据 mode 组合最终的配置列表
CONFIGS=()
BINARIES=()
OUTPUT_SUFFIXES=()  # 用于区分 CXL 和普通结果的输出子目录

if [[ "$RUN_MODE" == "normal" || "$RUN_MODE" == "all" ]]; then
  for idx in "${!NORMAL_CONFIGS[@]}"; do
    CONFIGS+=("${NORMAL_CONFIGS[$idx]}")
    BINARIES+=("${NORMAL_BINARIES[$idx]}")
    OUTPUT_SUFFIXES+=("")  # 普通模式不加后缀
  done
fi

if [[ "$RUN_MODE" == "cxl" || "$RUN_MODE" == "all" ]]; then
  for idx in "${!CXL_CONFIGS[@]}"; do
    CONFIGS+=("${CXL_CONFIGS[$idx]}")
    BINARIES+=("${CXL_BINARIES[$idx]}")
    OUTPUT_SUFFIXES+=("_cxl")  # CXL 模式结果加 _cxl 后缀
  done
fi

# ============================== 统计信息 ======================================
TOTAL_JOBS=$(( ${#CONFIGS[@]} * ${#TRACES_ARRAY[@]} ))
COMPLETED_JOBS=0
FAILED_JOBS=0
ACTIVE_JOBS=0

echo "[INFO] 总任务数: ${TOTAL_JOBS} (${#CONFIGS[@]} 配置 × ${#TRACES_ARRAY[@]} traces)"
echo ""

# ============================== 并行执行 ======================================

# 等待直到活跃进程数低于并行度限制
wait_for_slot() {
  while [ $ACTIVE_JOBS -ge $MAX_PARALLEL ]; do
    # 检查已完成的子进程
    local new_pids=()
    for pid in "${CHILD_PIDS[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        new_pids+=("$pid")
      else
        # 进程已结束，获取退出状态
        wait "$pid" 2>/dev/null
        local exit_code=$?
        ACTIVE_JOBS=$((ACTIVE_JOBS - 1))
        COMPLETED_JOBS=$((COMPLETED_JOBS + 1))
        if [ $exit_code -ne 0 ]; then
          FAILED_JOBS=$((FAILED_JOBS + 1))
        fi
      fi
    done
    CHILD_PIDS=("${new_pids[@]}")

    if [ $ACTIVE_JOBS -ge $MAX_PARALLEL ]; then
      sleep 1
    fi
  done
}

# 运行单个模拟任务
run_simulation() {
  local config="$1"
  local binary="$2"
  local trace="$3"
  local output_file="$4"
  local error_file="$5"

  local bin_path="${WORKING_DIR}/bin/${binary}/champsim_simulator"

  if [ ! -x "$bin_path" ]; then
    echo "[ERROR] 二进制文件不存在或不可执行: ${bin_path}" >> "$error_file"
    return 1
  fi

  "$bin_path" \
    --config="config/${config}.json" \
    --warmup_instructions=20000000 \
    --simulation_instructions=20000000 \
    --traces="${TRACE_DIR}/${trace}" \
    > "$output_file" 2> "$error_file"
}

# 主循环
START_TIME=$(date +%s)
JOB_INDEX=0

for idx in "${!CONFIGS[@]}"; do
  config="${CONFIGS[$idx]}"
  binary="${BINARIES[$idx]}"
  suffix="${OUTPUT_SUFFIXES[$idx]}"

  # 输出目录：CXL 模式的结果放到带 _cxl 后缀的子目录
  config_output_dir="${config}${suffix}"

  for trace in "${TRACES_ARRAY[@]}"; do
    # 检查是否被中断
    if [ "$RUNNING" = false ]; then
      break 2
    fi

    JOB_INDEX=$((JOB_INDEX + 1))
    JOB_NAME="${config_output_dir}/${trace}"
    OUTPUT_FILE="${OUTPUT_DIR}/${config_output_dir}/${trace}.txt"
    ERROR_FILE="${OUTPUT_DIR}/${config_output_dir}/${trace}.err"

    # 创建输出目录
    mkdir -p "${OUTPUT_DIR}/${config_output_dir}"

    # 如果输出文件包含完整统计字段，跳过（支持断点续跑）
    if [ -f "$OUTPUT_FILE" ] && grep -q "BRANCH_OTHER" "$OUTPUT_FILE"; then
      echo "[SKIP] (${JOB_INDEX}/${TOTAL_JOBS}) ${JOB_NAME} - 输出已完整"
      COMPLETED_JOBS=$((COMPLETED_JOBS + 1))
      continue
    fi

    if [ -f "$OUTPUT_FILE" ]; then
      echo "[RERUN] (${JOB_INDEX}/${TOTAL_JOBS}) ${JOB_NAME} - 输出不完整，未找到 BRANCH_OTHER"
    fi

    # 等待一个空闲的并行槽位
    wait_for_slot

    # 启动后台任务
    echo "[START] (${JOB_INDEX}/${TOTAL_JOBS}) ${JOB_NAME} | 活跃: ${ACTIVE_JOBS}/${MAX_PARALLEL} | 完成: ${COMPLETED_JOBS} | 失败: ${FAILED_JOBS}"

    run_simulation "$config" "$binary" "$trace" "$OUTPUT_FILE" "$ERROR_FILE" &
    local_pid=$!
    CHILD_PIDS+=("$local_pid")
    ACTIVE_JOBS=$((ACTIVE_JOBS + 1))
  done
done

# 等待所有剩余的子进程完成
echo ""
echo "[INFO] 所有任务已提交，等待剩余 ${ACTIVE_JOBS} 个任务完成..."

for pid in "${CHILD_PIDS[@]}"; do
  if kill -0 "$pid" 2>/dev/null; then
    wait "$pid" 2>/dev/null
    exit_code=$?
    COMPLETED_JOBS=$((COMPLETED_JOBS + 1))
    if [ $exit_code -ne 0 ]; then
      FAILED_JOBS=$((FAILED_JOBS + 1))
    fi
  fi
done

# ============================== 汇总报告 ======================================
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED / 60))
ELAPSED_SEC=$((ELAPSED % 60))

echo ""
echo "=============================================="
echo " 执行完毕"
echo " 运行模式:  ${RUN_MODE}"
echo " 总耗时:    ${ELAPSED_MIN}分${ELAPSED_SEC}秒"
echo " 总任务数:  ${TOTAL_JOBS}"
echo " 完成:      ${COMPLETED_JOBS}"
echo " 失败:      ${FAILED_JOBS}"
echo "=============================================="

if [ $FAILED_JOBS -gt 0 ]; then
  echo ""
  echo "[WARN] 有 ${FAILED_JOBS} 个任务失败，请检查 .err 文件:"
  echo "  find ${OUTPUT_DIR} -name '*.err' -size +0"
  exit 1
fi
