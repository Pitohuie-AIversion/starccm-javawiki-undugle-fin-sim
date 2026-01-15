#!/bin/bash

# 自动转换脚本换行符为 Linux 格式（避免 Windows 换行符导致的问题）
dos2unix $0

# 设置仿真文件路径
SIM_FILE="/share/fandixiaLab/suguangsheng/Zhaoyang/improve_case/near_wall/small_fin_U_F_D_2025_4_21/fin-1.2-0.4-5-11.54o-200-0.2-u0-f1-n1-Y1-wall-0.5_test_remend_fieldfunc_30mm_nomesh_add_all_field.sim"
if [[ ! -f "$SIM_FILE" ]]; then
    echo "Error: The simulation file $SIM_FILE does not exist!"
    exit 1
fi

# 获取目标路径
TARGET_FOLDER=$(dirname "$SIM_FILE")

# 参数设置
offset_values=(0.091)
frequencies=(1.0 1.5 2.0)
velocities=(-0.25 0.0 0.25)

# StarCCM路径
STARCCM_PATH="/share/soft/Siemens/17.04.008-R8/STAR-CCM+17.04.008-R8/star/bin/starccm+"
echo "STARCCM_EXEC is set to: $STARCCM_PATH"

if [[ ! -f "$STARCCM_PATH" ]]; then
    echo "Error: The StarCCM+ executable at $STARCCM_PATH does not exist!"
    exit 1
fi

# 生成宏文件 altogether.java
cat <<EOF > altogether.java
package macro;
import java.util.*;
import star.common.*;
import star.base.neo.*;
import star.cadmodeler.*;
import star.flow.*;
import star.vis.*;
import star.meshing.*;

public class altogether extends StarMacro {

  public void execute() {
    execute0();
  }

  private void execute0() {
    Simulation simulation_0 = getActiveSimulation();
    CadModel cadModel_0 = ((CadModel) simulation_0.get(SolidModelManager.class).getObject("3D-CAD Model 1"));
    ScalarQuantityDesignParameter offsetParam = ((ScalarQuantityDesignParameter) cadModel_0.getDesignParameterManager().getObject("Offset"));
    Units m = ((Units) simulation_0.getUnitsManager().getObject("m"));
    offsetParam.getQuantity().setValueAndUnits(Double.parseDouble(System.getenv("OFFSET")), m);
    cadModel_0.update();

    Region region_0 = simulation_0.getRegionManager().getRegion("fluid");
    Boundary inlet = region_0.getBoundaryManager().getBoundary("inlet");
    VelocityProfile velocityProfile_0 = inlet.getValues().get(VelocityProfile.class);
    Units mps = ((Units) simulation_0.getUnitsManager().getObject("m/s"));
    velocityProfile_0.getMethod(ConstantVectorProfileMethod.class).getQuantity().setComponentsAndUnits(Double.parseDouble(System.getenv("VELOCITY")), 0.0, 0.0, mps);

    UserFieldFunction userFieldFunction_0 = ((UserFieldFunction) simulation_0.getFieldFunctionManager().getFunction("Frequency"));
    userFieldFunction_0.setDefinition(System.getenv("FREQUENCY"));

    AutoMeshOperation autoMeshOperation_0 = ((AutoMeshOperation) simulation_0.get(MeshOperationManager.class).getObject("Automated Mesh"));
    autoMeshOperation_0.execute();

    simulation_0.getSolution().initializeSolution();

    PhysicsContinuum physicsContinuum_0 = ((PhysicsContinuum) simulation_0.getContinuumManager().getContinuum("Physics 1"));
    VelocityProfile velocityProfile_1 = physicsContinuum_0.getInitialConditions().get(VelocityProfile.class);
    velocityProfile_1.getMethod(ConstantVectorProfileMethod.class).getQuantity().setComponentsAndUnits(0.011, 0.0, 0.0, mps);

    simulation_0.getSimulationIterator().run();

    simulation_0.saveState(System.getenv("OUTPUT_DIR") + "/final_result.sim");
  }
}
EOF

# 循环运行仿真
for frequency in "${frequencies[@]}"; do
    for velocity in "${velocities[@]}"; do
        for offset in "${offset_values[@]}"; do

            folder_name="${TARGET_FOLDER}/f${frequency}_U${velocity}_Offset${offset}"
            mkdir -p "$folder_name"
            sim_file="${folder_name}/simulation_f${frequency}_U${velocity}_Offset${offset}.sim"
            cp "$SIM_FILE" "$sim_file"
            echo "仿真文件已复制到: $sim_file"

            export OFFSET="$offset"
            export VELOCITY="$velocity"
            export FREQUENCY="$frequency"
            export SIM_FILE_PATH="$sim_file"
            export OUTPUT_DIR="$folder_name"

            "$STARCCM_PATH" -batch altogether.java -np 190 -power "$sim_file"

            echo "仿真完成：f=${frequency}, U=${velocity}, Offset=${offset}"

        done
    done
done

rm -f altogether.java

echo "所有仿真已完成"
