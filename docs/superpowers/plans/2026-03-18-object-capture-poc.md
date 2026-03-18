# Object Capture PoC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** React Native (Expo) から Swift ObjectCaptureSession で3Dスキャンし、USDZ をアプリ内で表示する PoC を構築する

**Architecture:** Expo Router で2画面構成 (ホーム + ビューア)。2つのローカル Expo Module で Swift ネイティブ機能を提供: ObjectCaptureModule (スキャン + 再構成) と ModelViewerModule (USDZ 表示)。SwiftUI の ObjectCaptureView は UIHostingController 経由で UIKit から表示。

**Tech Stack:** Expo SDK 52+, Expo Router, expo-modules-core, Swift, ObjectCaptureSession (iOS 17+), PhotogrammetrySession, SceneKit

**Spec:** `docs/superpowers/specs/2026-03-18-object-capture-poc-design.md`

---

## File Structure

```
rn-object-capture-bridge-example/
├── app/
│   ├── _layout.tsx                # Root layout (Stack navigator)
│   ├── index.tsx                  # ホーム画面（スキャン開始ボタン）
│   └── viewer.tsx                 # ビューア画面（USDZ 表示）
├── modules/
│   ├── object-capture/
│   │   ├── expo-module.config.json
│   │   ├── package.json           # autolinking に必要
│   │   ├── index.ts               # JS API: startCapture()
│   │   └── ios/
│   │       ├── ObjectCaptureModule.swift
│   │       └── ObjectCaptureView.swift
│   └── model-viewer/
│       ├── expo-module.config.json
│       ├── package.json           # autolinking に必要
│       ├── index.ts               # JS API: <ModelViewer />
│       └── ios/
│           ├── ModelViewerModule.swift
│           └── ModelViewerView.swift
├── app.json
├── package.json
└── tsconfig.json
```

---

### Task 1: Expo プロジェクトセットアップ

**Files:**
- Create: `package.json`, `app.json`, `tsconfig.json`, `app/_layout.tsx`, `app/index.tsx`

- [ ] **Step 1: Expo プロジェクトを作成**

```bash
cd /Users/konojunya/ghq/src/github.com/konojunya/rn-object-capture-bridge-example
npx create-expo-app@latest . --template blank-typescript
```

既にファイルがある場合 (README.md, .gitignore) は上書きを許可する。

- [ ] **Step 2: Expo Router と必要なパッケージをインストール**

```bash
npx expo install expo-router expo-linking expo-constants expo-status-bar expo-modules-core
```

- [ ] **Step 3: package.json のエントリポイントを設定**

`package.json` に `"main": "expo-router/entry"` を追加する。Expo Router がエントリポイントとして動作するために必要。

- [ ] **Step 4: app.json を設定**

`app.json` を編集して以下を反映:

```json
{
  "expo": {
    "name": "rn-object-capture-bridge-example",
    "slug": "rn-object-capture-bridge-example",
    "version": "1.0.0",
    "scheme": "rn-object-capture",
    "platforms": ["ios"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.konojunya.rn-object-capture-bridge-example",
      "deploymentTarget": "17.0",
      "infoPlist": {
        "NSCameraUsageDescription": "3Dオブジェクトをスキャンするためにカメラを使用します"
      }
    },
    "plugins": ["expo-router"]
  }
}
```

- [ ] **Step 5: app/_layout.tsx を作成**

```typescript
import { Stack } from "expo-router";

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="index" options={{ title: "Object Capture PoC" }} />
      <Stack.Screen name="viewer" options={{ title: "3D Viewer" }} />
    </Stack>
  );
}
```

- [ ] **Step 6: app/index.tsx にHello Worldを表示**

```typescript
import { View, Text, StyleSheet } from "react-native";

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <Text>Hello World</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});
```

- [ ] **Step 7: .gitignore に ios/ を追加**

Expo の CNG (Continuous Native Generation) ワークフローでは `ios/` は生成物なので gitignore する。`.gitignore` に以下を追加:

```
# Expo generated native projects
ios/
android/
```

- [ ] **Step 8: prebuild して iOS プロジェクトを生成**

```bash
npx expo prebuild --platform ios
```

- [ ] **Step 9: 実機でビルド・起動確認**

```bash
npx expo run:ios --device
```

Hello World が表示されることを確認。

- [ ] **Step 10: コミット**

```bash
git add -A
git commit -m "feat: setup Expo project with Router and hello world"
```

---

### Task 2: ModelViewer Expo Module (USDZ ビューア)

ObjectCaptureModule より先にビューアを作る。こちらの方がシンプルで、テスト用の USDZ ファイルを使って単独で動作確認できる。

**Files:**
- Create: `modules/model-viewer/package.json`
- Create: `modules/model-viewer/expo-module.config.json`
- Create: `modules/model-viewer/index.ts`
- Create: `modules/model-viewer/ios/ModelViewerModule.swift`
- Create: `modules/model-viewer/ios/ModelViewerView.swift`

- [ ] **Step 1: モジュールディレクトリを作成**

```bash
mkdir -p modules/model-viewer/ios
```

- [ ] **Step 2: package.json を作成 (autolinking に必要)**

```json
{
  "name": "model-viewer",
  "version": "1.0.0",
  "main": "index.ts"
}
```

- [ ] **Step 3: expo-module.config.json を作成**

```json
{
  "platforms": ["ios"],
  "apple": {
    "modules": ["ModelViewerModule"]
  }
}
```

- [ ] **Step 4: ModelViewerModule.swift を作成**

```swift
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
```

- [ ] **Step 5: ModelViewerView.swift を作成**

```swift
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
```

- [ ] **Step 6: index.ts を作成**

```typescript
import { requireNativeView } from "expo-modules-core";
import { ViewStyle } from "react-native";

type ModelViewerProps = {
  modelPath: string;
  style?: ViewStyle;
};

export const ModelViewer =
  requireNativeView<ModelViewerProps>("ModelViewer");
```

- [ ] **Step 7: prebuild してビルド確認**

```bash
npx expo prebuild --platform ios --clean
npx expo run:ios --device
```

ビルドが通ることを確認（まだ画面には組み込んでいないので表示確認は次のステップ）。

- [ ] **Step 8: コミット**

```bash
git add modules/model-viewer/
git commit -m "feat: add ModelViewer Expo Module with SceneKit USDZ rendering"
```

---

### Task 3: ObjectCapture Expo Module (スキャン + 再構成)

**Files:**
- Create: `modules/object-capture/package.json`
- Create: `modules/object-capture/expo-module.config.json`
- Create: `modules/object-capture/index.ts`
- Create: `modules/object-capture/ios/ObjectCaptureModule.swift`
- Create: `modules/object-capture/ios/ObjectCaptureView.swift`

- [ ] **Step 1: モジュールディレクトリを作成**

```bash
mkdir -p modules/object-capture/ios
```

- [ ] **Step 2: package.json を作成 (autolinking に必要)**

```json
{
  "name": "object-capture",
  "version": "1.0.0",
  "main": "index.ts"
}
```

- [ ] **Step 3: expo-module.config.json を作成**

```json
{
  "platforms": ["ios"],
  "apple": {
    "modules": ["ObjectCaptureModule"]
  }
}
```

- [ ] **Step 4: ObjectCaptureView.swift を作成**

ObjectCaptureSession の SwiftUI ビュー + 再構成処理を担当する。

```swift
import SwiftUI
import RealityKit

@available(iOS 17.0, *)
@MainActor
class ObjectCaptureCoordinator: ObservableObject {
  var session: ObjectCaptureSession?
  private var captureDir: URL?
  var onComplete: ((String) -> Void)?
  var onError: ((Error) -> Void)?
  var onCancel: (() -> Void)?

  func startSession() async {
    let session = ObjectCaptureSession()
    self.session = session

    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let captureDir = documentsDir.appendingPathComponent("capture-\(UUID().uuidString)")
    self.captureDir = captureDir

    let imagesDir = captureDir.appendingPathComponent("Images")
    let checkpointsDir = captureDir.appendingPathComponent("Checkpoints")

    try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: checkpointsDir, withIntermediateDirectories: true)

    var config = ObjectCaptureSession.Configuration()
    config.checkpointDirectory = checkpointsDir

    session.start(
      imagesDirectory: imagesDir,
      configuration: config
    )
  }

  func reconstruct() async {
    guard let captureDir = captureDir else {
      onError?(NSError(domain: "ObjectCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "No capture directory"]))
      return
    }

    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let outputPath = documentsDir.appendingPathComponent("\(UUID().uuidString).usdz")

    do {
      let request = PhotogrammetrySession.Request.modelFile(url: outputPath, detail: .reduced)
      let imagesDir = captureDir.appendingPathComponent("Images")
      let photogrammetrySession = try PhotogrammetrySession(input: imagesDir)

      try photogrammetrySession.process(requests: [request])

      for try await output in photogrammetrySession.outputs {
        switch output {
        case .requestComplete(_, let result):
          switch result {
          case .modelFile(let url):
            cleanupCaptureDir()
            onComplete?(url.path)
            return
          default:
            break
          }
        case .requestError(_, let error):
          cleanupCaptureDir()
          onError?(error)
          return
        default:
          continue
        }
      }
    } catch {
      cleanupCaptureDir()
      onError?(error)
    }
  }

  func cancel() {
    session?.cancel()
    cleanupCaptureDir()
    onCancel?()
  }

  private func cleanupCaptureDir() {
    guard let captureDir = captureDir else { return }
    try? FileManager.default.removeItem(at: captureDir)
    self.captureDir = nil
  }
}

@available(iOS 17.0, *)
struct ObjectCaptureContentView: View {
  @ObservedObject var coordinator: ObjectCaptureCoordinator
  @State private var isReconstructing = false

  var body: some View {
    ZStack {
      if let session = coordinator.session {
        ObjectCaptureView(session: session)
          .overlay(alignment: .bottom) {
            HStack(spacing: 20) {
              Button("Cancel") {
                coordinator.cancel()
              }
              .buttonStyle(.bordered)

              if case .completing = session.state {
                // Session is finishing, no additional buttons needed
              } else if case .finished = session.state {
                // Will auto-transition to reconstruction
              }
            }
            .padding(.bottom, 40)
          }
      }

      if isReconstructing {
        Color.black.opacity(0.7)
          .ignoresSafeArea()
        VStack(spacing: 16) {
          ProgressView()
            .scaleEffect(1.5)
          Text("3Dモデルを構築中...")
            .foregroundColor(.white)
            .font(.headline)
        }
      }
    }
    .task {
      await coordinator.startSession()
      guard let session = coordinator.session else { return }

      for await newState in session.stateUpdates {
        switch newState {
        case .completed:
          isReconstructing = true
          await coordinator.reconstruct()
          return
        case .failed(let error):
          coordinator.onError?(error)
          return
        default:
          continue
        }
      }
    }
  }
}
```

- [ ] **Step 5: ObjectCaptureModule.swift を作成**

```swift
import ExpoModulesCore
import SwiftUI
import RealityKit

class NotSupportedException: Exception {
  override var reason: String {
    "Object Capture is not supported on this device. Requires iOS 17+ and LiDAR."
  }
}

class PresentationFailedException: Exception {
  override var reason: String {
    "Could not find a view controller to present from"
  }
}

class CaptureFailedException: GenericException<String> {
  override var reason: String {
    "Capture failed: \(param)"
  }
}

class CaptureCancelledException: Exception {
  override var reason: String {
    "Capture was cancelled by the user"
  }
}

public class ObjectCaptureModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ObjectCapture")

    AsyncFunction("isSupported") { () -> Bool in
      if #available(iOS 17.0, *) {
        return ObjectCaptureSession.isSupported
      }
      return false
    }

    AsyncFunction("startCapture") { (promise: Promise) in
      if #available(iOS 17.0, *) {
        guard ObjectCaptureSession.isSupported else {
          promise.reject(NotSupportedException())
          return
        }

        Task { @MainActor [weak self] in
          self?.presentCaptureView(promise: promise)
        }
      } else {
        promise.reject(NotSupportedException())
      }
    }
  }

  @available(iOS 17.0, *)
  @MainActor
  private func presentCaptureView(promise: Promise) {
    guard let viewController = appContext?.utilities?.currentViewController() else {
      promise.reject(PresentationFailedException())
      return
    }

    let coordinator = ObjectCaptureCoordinator()

    coordinator.onComplete = { [weak viewController] path in
      DispatchQueue.main.async {
        viewController?.dismiss(animated: true) {
          promise.resolve(path)
        }
      }
    }

    coordinator.onError = { [weak viewController] error in
      DispatchQueue.main.async {
        viewController?.dismiss(animated: true) {
          promise.reject(CaptureFailedException(error.localizedDescription))
        }
      }
    }

    coordinator.onCancel = { [weak viewController] in
      DispatchQueue.main.async {
        viewController?.dismiss(animated: true) {
          promise.reject(CaptureCancelledException())
        }
      }
    }

    let swiftUIView = ObjectCaptureContentView(coordinator: coordinator)
    let hostingController = UIHostingController(rootView: swiftUIView)
    hostingController.modalPresentationStyle = .fullScreen
    viewController.present(hostingController, animated: true)
  }
}
```

- [ ] **Step 6: index.ts を作成**

```typescript
import { requireNativeModule } from "expo-modules-core";

const ObjectCaptureModule = requireNativeModule("ObjectCapture");

export async function startCapture(): Promise<string> {
  return await ObjectCaptureModule.startCapture();
}

export async function isSupported(): Promise<boolean> {
  return await ObjectCaptureModule.isSupported();
}
```

- [ ] **Step 7: prebuild してビルド確認**

```bash
npx expo prebuild --platform ios --clean
npx expo run:ios --device
```

ビルドが通ることを確認。

- [ ] **Step 8: コミット**

```bash
git add modules/object-capture/
git commit -m "feat: add ObjectCapture Expo Module with session management and reconstruction"
```

---

### Task 4: React Native 画面を接続

**Files:**
- Modify: `app/index.tsx`
- Create: `app/viewer.tsx`

- [ ] **Step 1: app/index.tsx をスキャン開始画面に更新**

```typescript
import { View, Text, Pressable, StyleSheet, Alert } from "react-native";
import { useRouter } from "expo-router";
import { startCapture, isSupported } from "../modules/object-capture";

export default function HomeScreen() {
  const router = useRouter();

  const handleStartCapture = async () => {
    try {
      const supported = await isSupported();
      if (!supported) {
        Alert.alert("非対応デバイス", "このデバイスは Object Capture に対応していません。");
        return;
      }

      const modelPath = await startCapture();
      router.push({ pathname: "/viewer", params: { modelPath } });
    } catch (error: any) {
      if (error?.code === "ERR_CANCELLED") {
        // ユーザーキャンセル、何もしない
        return;
      }
      Alert.alert("エラー", error?.message ?? "スキャンに失敗しました");
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Object Capture PoC</Text>
      <Pressable style={styles.button} onPress={handleStartCapture}>
        <Text style={styles.buttonText}>スキャン開始</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#fff",
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 32,
  },
  button: {
    backgroundColor: "#007AFF",
    paddingHorizontal: 32,
    paddingVertical: 16,
    borderRadius: 12,
  },
  buttonText: {
    color: "#fff",
    fontSize: 18,
    fontWeight: "600",
  },
});
```

- [ ] **Step 2: app/viewer.tsx を作成**

```typescript
import { View, StyleSheet } from "react-native";
import { useLocalSearchParams } from "expo-router";
import { ModelViewer } from "../modules/model-viewer";

export default function ViewerScreen() {
  const { modelPath } = useLocalSearchParams<{ modelPath: string }>();

  return (
    <View style={styles.container}>
      {modelPath ? (
        <ModelViewer modelPath={modelPath} style={styles.viewer} />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#000",
  },
  viewer: {
    flex: 1,
  },
});
```

- [ ] **Step 3: ビルドして実機で動作確認**

```bash
npx expo prebuild --platform ios --clean
npx expo run:ios --device
```

確認項目:
1. ホーム画面に「スキャン開始」ボタンが表示される
2. ボタンタップで ObjectCaptureSession のフルスクリーンUIが開く
3. オブジェクトをスキャンして完了すると再構成が始まる
4. 再構成完了後、ビューア画面に遷移して3Dモデルが表示される
5. モデルを回転・ズームできる

- [ ] **Step 4: コミット**

```bash
git add app/
git commit -m "feat: connect home and viewer screens with capture flow"
```

---

### Task 5: エラーハンドリングの強化と最終確認

**Files:**
- Modify: `app/index.tsx` (必要に応じて)
- Modify: `modules/object-capture/ios/ObjectCaptureModule.swift` (必要に応じて)

- [ ] **Step 1: 各エラーケースを実機で確認**

以下を確認:
- 非対応デバイスでの動作（`isSupported` チェック）
- カメラ権限拒否時の動作
- キャプチャ中のキャンセル
- 再構成中のメモリ警告（コンソールログで確認）

- [ ] **Step 2: 問題があれば修正**

エラーケースで問題があれば修正する。

- [ ] **Step 3: 最終コミット**

```bash
git add -A
git commit -m "fix: improve error handling for edge cases"
```
