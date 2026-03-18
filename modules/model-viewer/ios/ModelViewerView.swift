import ExpoModulesCore
import SceneKit

class ModelViewerView: ExpoView {
  private let sceneView = SCNView()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    setupSceneView()
  }

  private func setupSceneView() {
    sceneView.autoenablesDefaultLighting = true
    sceneView.allowsCameraControl = true
    sceneView.backgroundColor = .systemBackground
    sceneView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(sceneView)
    NSLayoutConstraint.activate([
      sceneView.topAnchor.constraint(equalTo: topAnchor),
      sceneView.bottomAnchor.constraint(equalTo: bottomAnchor),
      sceneView.leadingAnchor.constraint(equalTo: leadingAnchor),
      sceneView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  func loadModel(path: String) {
    guard !path.isEmpty else { return }
    let url = URL(fileURLWithPath: path)
    guard let scene = try? SCNScene(url: url) else {
      print("Failed to load USDZ from: \(path)")
      return
    }
    sceneView.scene = scene
  }
}
