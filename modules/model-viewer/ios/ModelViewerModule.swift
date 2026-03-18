import ExpoModulesCore

public class ModelViewerModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ModelViewer")

    View(ModelViewerView.self) {
      Prop("modelPath") { (view, path: String) in
        view.loadModel(path: path)
      }
    }
  }
}
