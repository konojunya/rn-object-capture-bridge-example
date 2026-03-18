# rn-object-capture-bridge-example

React Native (Expo) から Swift の ObjectCaptureSession を使って、現実のオブジェクトを3Dスキャンする PoC。

## Overview

フィギュアなど現実のオブジェクトを iPhone の LiDAR でスキャンし、3D モデル (USDZ) としてアプリ内で閲覧できます。

- **ObjectCaptureSession** (iOS 17+) によるガイド付き3Dキャプチャ
- **PhotogrammetrySession** によるオンデバイス USDZ 再構成
- **SceneKit** による USDZ ビューア（回転・ズーム対応）

## Architecture

```
app/
  index.tsx        → ホーム画面（スキャン開始）
  viewer.tsx       → 3Dモデルビューア
modules/
  object-capture/  → Expo Module: ObjectCaptureSession + PhotogrammetrySession
  model-viewer/    → Expo Module: SceneKit SCNView ラッパー
```

2つのローカル Expo Module で Swift ネイティブ機能を提供し、Expo Router で画面遷移を管理します。

## Requirements

- **iOS 17+**
- **LiDAR 搭載デバイス** (iPhone 12 Pro 以降)
- Node.js 18+
- [Bun](https://bun.sh/)
- Xcode 15+
- Apple Developer Program (TestFlight 配布の場合)

## Setup

```bash
bun install
bunx expo prebuild --platform ios
```

## Run

### USB 接続 (実機)

```bash
bunx expo run:ios --device
```

### TestFlight

```bash
eas build --platform ios --profile production
eas submit --platform ios --latest
```

## Data Flow

```
スキャン開始ボタン
  → ObjectCaptureModule.startCapture()
  → SwiftUI ObjectCaptureView (フルスクリーン)
  → ユーザーがオブジェクト周りを撮影
  → PhotogrammetrySession で USDZ 再構成 (.reduced)
  → Documents/{UUID}.usdz に保存
  → ビューア画面で 3D 表示（回転・ズーム）
```

## Tech Stack

- Expo SDK 55 + Expo Router
- expo-modules-core (Swift ネイティブモジュール)
- ObjectCaptureSession / PhotogrammetrySession (RealityKit)
- SceneKit (USDZ ビューア)
- Bun (パッケージマネージャ)

## License

MIT
