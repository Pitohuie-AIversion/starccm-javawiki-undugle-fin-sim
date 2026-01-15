#!/bin/bash

# 自动转换脚本换行符为 Linux 格式（避免 Windows 换行符导致的问题）
#dos2unix $0

# 设置仿真文件路径
SIM_FILE="/share/fandixiaLab/suguangsheng/Zhaoyang/improve_case/near_wall/small_fin_U_F_D/fin-1.2-0.4-5-11.54o-200-0.2-u0-f1-n1-Y1-wall-0.5_test_remend_fieldfunc_30mm_nomesh.sim"

# 检查仿真文件是否存在
if [[ ! -f "$SIM_FILE" ]]; then
    echo "Error: The simulation file $SIM_FILE does not exist!"
    exit 1
fi

# 获取当前目录（即仿真文件所在目录）作为目标文件夹
TARGET_FOLDER=$(dirname "$SIM_FILE")

# 更新偏移数组，包含 0.001 和 0.031 这样的小值
offset_values=(0.001 0.031 0.061 0.091 0.121)

# 定义频率和流速的范围
frequencies=(1.0 1.5 2.0)
velocities=(-0.25 0.0 0.25)

# 设置 Java 脚本文件路径为与类名一致
TEMP_SCRIPT_PATH="correct_offset.java"
MESH_SCRIPT_PATH="mesh_generate.java"  # 网格生成脚本路径

# 设置 STARCCM_PATH（确保指向正确路径）
STARCCM_PATH="/share/soft/Siemens/17.04.008-R8/STAR-CCM+17.04.008-R8/star/bin/starccm+"  # 请确认这个路径是正确的

# 打印 STARCCM_PATH 以确认路径是否正确
echo "STARCCM_EXEC is set to: $STARCCM_PATH"

# 确保 STARCCM_PATH 路径有效
if [[ ! -f "$STARCCM_PATH" ]]; then
    echo "Error: The StarCCM+ executable at $STARCCM_PATH does not exist!"
    exit 1
fi

# 获取所有可用节点的资源
AVAILABLE_NODES=$(sinfo -h -o "%n" -t idle)  # 获取所有空闲节点的名称

# 如果没有空闲节点，退出脚本
if [[ -z "$AVAILABLE_NODES" ]]; then
    echo "No available nodes found!"
    exit 1
fi

# 输出可用节点
echo "Available nodes: $AVAILABLE_NODES"

# 遍历频率、流速和偏移量
for frequency in "${frequencies[@]}"; do
    for velocity in "${velocities[@]}"; do
        for offset in "${offset_values[@]}"; do  # 添加偏移循环

            # 为每个参数组合创建文件夹
            folder_name="${TARGET_FOLDER}/f${frequency}_U${velocity}_Offset${offset}"
            mkdir -p "$folder_name"

            # 创建仿真文件路径
            sim_file="${folder_name}/simulation_f${frequency}_U${velocity}_Offset${offset}.sim"
            cp "$SIM_FILE" "$sim_file"

            # 确保仿真文件复制成功
            echo "仿真文件已复制到: $sim_file"

            # 修改仿真文件中的参数（用sed替换）
            sed -i "s/parameter_frequency_value/${frequency}/g" "$sim_file"
            sed -i "s/parameter_velocity_value/${velocity}/g" "$sim_file"
            sed -i "s/parameter_offset_value/${offset}/g" "$sim_file"  # 替换偏移值

            # 生成网格操作：运行 mesh_generate.java 脚本
            cat > $MESH_SCRIPT_PATH <<EOL
package macro;

import star.common.*;
import star.meshing.*;

public class mesh_generate extends StarMacro {

  public void execute() {
    execute0();
  }

  private void execute0() {

    Simulation simulation_0 = 
      getActiveSimulation();

    MeshPipelineController meshPipelineController_0 = 
      simulation_0.get(MeshPipelineController.class);

    meshPipelineController_0.clearGeneratedMeshes();

    AutoMeshOperation autoMeshOperation_0 = 
      ((AutoMeshOperation) simulation_0.get(MeshOperationManager.class).getObject("Automated Mesh"));

    autoMeshOperation_0.execute();

    meshPipelineController_0.generateVolumeMesh();

    simulation_0.getSimulationIterator().run();
  }
}
EOL

            # 自动分配空闲节点并运行网格生成 Java 脚本
            for NODE in $AVAILABLE_NODES; do
                srun -n 192 --nodelist=$NODE "$STARCCM_PATH" -batch "$MESH_SCRIPT_PATH" "$sim_file"  # 在每个空闲节点上分配 192 个任务
            done

            # 删除临时网格生成脚本文件
            rm $MESH_SCRIPT_PATH

            # 生成临时的 Java 脚本内容（禁用 Thrust x 报告部分）
            cat > $TEMP_SCRIPT_PATH <<EOL
package macro;

import java.util.*;

import star.common.*;
import star.base.neo.*;
import star.base.report.*;
import star.cadmodeler.*;
import star.flow.*;
import star.vis.*;
import star.meshing.*;

public class correct_offset extends StarMacro {

  public void execute() {
    execute0();
    execute1();
  }

  private void execute0() {
    Simulation simulation_0 = getActiveSimulation();

    CadModel cadModel_0 = (CadModel) simulation_0.get(SolidModelManager.class).getObject("3D-CAD Model 1");
    ScalarQuantityDesignParameter scalarQuantityDesignParameter_5 = (ScalarQuantityDesignParameter) cadModel_0.getDesignParameterManager().getObject("Offset");
    Units units_0 = (Units) simulation_0.getUnitsManager().getObject("m");
    scalarQuantityDesignParameter_5.getQuantity().setValueAndUnits(${offset}, units_0);

    AutoMeshOperation autoMeshOperation_0 = (AutoMeshOperation) simulation_0.get(MeshOperationManager.class).getObject("Automated Mesh");
    autoMeshOperation_0.execute();

    Region region_0 = simulation_0.getRegionManager().getRegion("fluid");
    Boundary boundary_1 = region_0.getBoundaryManager().getBoundary("inlet");
    VelocityProfile velocityProfile_0 = boundary_1.getValues().get(VelocityProfile.class);
    Units units_5 = (Units) simulation_0.getUnitsManager().getObject("m/s");
    velocityProfile_0.getMethod(ConstantVectorProfileMethod.class).getQuantity().setComponentsAndUnits(${velocity}, 0.0, 0.0, units_5);

    MomentReport momentReport_0 = (MomentReport) simulation_0.getReportManager().getReport("Mx");
    ForceReport forceReport_0 = (ForceReport) simulation_0.getReportManager().getReport("X");

    simulation_0.saveState("${folder_name}/results_f${frequency}_U${velocity}_Offset${offset}.sim");
  }

  private void execute1() {
    Simulation simulation_0 = getActiveSimulation();
    AutoExport autoExport_0 = simulation_0.getSimulationIterator().getAutoExport();

    Region region_0 = simulation_0.getRegionManager().getRegion("fluid");
    Boundary boundary_0 = region_0.getBoundaryManager().getBoundary("bottom");

    autoExport_0.setBoundaries(new NeoObjectVector(new Object[] {boundary_0}));

    StarUpdate starUpdate_1 = autoExport_0.getStarUpdate();
    starUpdate_1.setEnabled(true);
    starUpdate_1.getUpdateModeOption().setSelected(StarUpdateModeOption.Type.TIMESTEP);

    PrimitiveFieldFunction primitiveFieldFunction_0 = (PrimitiveFieldFunction) simulation_0.getFieldFunctionManager().getFunction("AbsolutePressure");
    PrimitiveFieldFunction primitiveFieldFunction_1 = (PrimitiveFieldFunction) simulation_0.getFieldFunctionManager().getFunction("AbsoluteTotalPressure");

    autoExport_0.setScalars(new NeoObjectVector(new Object[] {primitiveFieldFunction_0, primitiveFieldFunction_1}));
    autoExport_0.setExportDirectory("testcsgn");
    autoExport_0.setBaseName("bottom_pressure\n");
    autoExport_0.setOptionSolutionOnly(false);

    simulation_0.saveState("${folder_name}/results_f${frequency}_U${velocity}_Offset${offset}.sim");
  }
}
EOL

            # 在 STARCCM+ 中运行临时 Java 脚本
            for NODE in $AVAILABLE_NODES; do
                srun -n 192 --nodelist=$NODE "$STARCCM_PATH" -batch "$TEMP_SCRIPT_PATH" "$sim_file"  # 在每个空闲节点上运行仿真任务
            done

            # 删除临时脚本文件
            rm $TEMP_SCRIPT_PATH

            # 运行仿真
            for NODE in $AVAILABLE_NODES; do
                srun -n 192 --nodelist=$NODE "$STARCCM_PATH" -batch "$sim_file"  # 在每个空闲节点上运行仿真任务
            done

            # 可选：在仿真后进行一些后处理，例如保存结果、导出数据等
            echo "仿真已完成：f=${frequency}, U=${velocity}, Offset=${offset}"

        done  # 结束偏移循环
    done
done

echo "所有仿真已完成"
