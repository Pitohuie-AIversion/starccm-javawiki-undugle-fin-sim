# starccm-javawiki-undugle-fin-sim

本仓库整理并归档了 STAR-CCM+ 波纹鳍片（undulating fin）案例的批处理脚本、宏文件与演示结果，便于复现实验配置与批量仿真流程。

## 目录结构

```
.
├── assets/                         # 演示媒体
│   ├── output.gif
│   └── output.mp4
├── cases/
│   └── small_fin_U_F_D_20250624/    # 小尺度波纹鳍片案例
│       ├── altogether.java         # 一键参数化 + 网格 + 运行 + 保存
│       ├── mesh_generate.java      # 单独网格生成宏
│       ├── samll_fin_batch_U_F_D.sh
│       ├── samll_fin_batch_U_F_D0.03.sh
│       ├── samll_fin_batch_U_F_D0.06.sh
│       ├── samll_fin_batch_U_F_D0.09.sh
│       ├── samll_fin_batch_U_F_D_multinode.sh
│       └── *.sim                   # STAR-CCM+ 仿真文件
└── README.md
```

## Demo

![Undulating fin simulation demo](assets/output.gif)

[▶ Full video (mp4)](assets/output.mp4)

## 环境要求

- Linux 环境（脚本默认使用 bash 与 `dos2unix`）。
- 已安装 STAR-CCM+，并确保 `starccm+` 可在脚本中通过绝对路径调用。

## 使用说明

### 1. 批处理脚本

`cases/small_fin_U_F_D_20250624/` 目录下的 `samll_fin_batch_U_F_D*.sh` 脚本用于批量扫描偏移量、频率与入口速度，并自动：

1. 复制基础 `.sim` 文件。
2. 替换参数占位符。
3. 生成网格。
4. 运行仿真。

脚本中需要根据本地环境修改：

- `SIM_FILE`：基础 `.sim` 文件路径。
- `STARCCM_PATH`：STAR-CCM+ 可执行文件路径。
- 并行核心数（`-np` 参数）与计算资源配置。

> 注意：脚本会在目标目录下创建大量结果文件，请确保磁盘空间充足。

### 2. 宏脚本

- `altogether.java`：从环境变量读取参数并一键完成建模更新、网格生成、初始化、求解与结果保存。需要提供以下环境变量：
  - `OFFSET`：几何偏移量。
  - `VELOCITY`：入口速度。
  - `FREQUENCY`：频率表达式。
  - `OUTPUT_DIR`：结果保存目录。
- `mesh_generate.java`：仅执行网格生成与求解运行，可用于单独更新网格。

示例（仅展示变量传递方式，实际命令需结合 STAR-CCM+ 环境）：

```bash
export OFFSET=0.031
export VELOCITY=0.25
export FREQUENCY="1.0"
export OUTPUT_DIR=/path/to/output

# 以 STAR-CCM+ 执行宏（示例）
starccm+ -batch cases/small_fin_U_F_D_20250624/altogether.java -power your_case.sim
```

## 说明

此仓库主要用于记录仿真脚本与案例文件，便于在不同机器上重复执行与对比参数组合结果。
