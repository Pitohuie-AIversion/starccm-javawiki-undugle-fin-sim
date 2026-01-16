package macro;
import star.common.*;
import star.meshing.*;
public class mesh_generate extends StarMacro {
  public void execute() {
    Simulation simulation_0 = getActiveSimulation();
    MeshPipelineController meshPipelineController_0 = simulation_0.get(MeshPipelineController.class);
    meshPipelineController_0.clearGeneratedMeshes();
    AutoMeshOperation autoMeshOperation_0 = (AutoMeshOperation) simulation_0.get(MeshOperationManager.class).getObject("Automated Mesh");
    autoMeshOperation_0.execute();
    meshPipelineController_0.generateVolumeMesh();
    simulation_0.getSimulationIterator().run();
  }
}
