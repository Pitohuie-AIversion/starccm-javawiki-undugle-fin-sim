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
    ScalarQuantityDesignParameter offsetParam = (ScalarQuantityDesignParameter) cadModel_0.getDesignParameterManager().getObject("Offset");
    Units meter = (Units) simulation_0.getUnitsManager().getObject("m");
    offsetParam.getQuantity().setValueAndUnits(Double.parseDouble(System.getenv("OFFSET")), meter);

    UserFieldFunction freqFunc = (UserFieldFunction) simulation_0.getFieldFunctionManager().getFunction("Frequency");
    freqFunc.setDefinition(System.getenv("FREQUENCY"));

    AutoMeshOperation autoMeshOperation_0 = (AutoMeshOperation) simulation_0.get(MeshOperationManager.class).getObject("Automated Mesh");
    autoMeshOperation_0.execute();

    Region region_0 = simulation_0.getRegionManager().getRegion("fluid");
    Boundary inlet = region_0.getBoundaryManager().getBoundary("inlet");
    VelocityProfile velocityProfile_0 = inlet.getValues().get(VelocityProfile.class);
    Units mps = (Units) simulation_0.getUnitsManager().getObject("m/s");
    velocityProfile_0.getMethod(ConstantVectorProfileMethod.class).getQuantity().setComponentsAndUnits(Double.parseDouble(System.getenv("VELOCITY")), 0.0, 0.0, mps);

    simulation_0.saveState(System.getenv("OUTPUT_DIR") + "/results.sim");
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

    PrimitiveFieldFunction p0 = (PrimitiveFieldFunction) simulation_0.getFieldFunctionManager().getFunction("AbsolutePressure");
    PrimitiveFieldFunction p1 = (PrimitiveFieldFunction) simulation_0.getFieldFunctionManager().getFunction("AbsoluteTotalPressure");

    autoExport_0.setScalars(new NeoObjectVector(new Object[] {p0, p1}));
    autoExport_0.setExportDirectory(System.getenv("OUTPUT_DIR") + "/export");
    autoExport_0.setBaseName("bottom_pressure");
    autoExport_0.setOptionSolutionOnly(false);

    simulation_0.saveState(System.getenv("OUTPUT_DIR") + "/results_final.sim");
  }
}
