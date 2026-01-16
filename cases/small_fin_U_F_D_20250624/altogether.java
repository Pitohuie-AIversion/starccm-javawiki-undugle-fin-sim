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
