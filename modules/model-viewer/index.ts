import { requireNativeView } from "expo-modules-core";
import { ViewStyle } from "react-native";

type ModelViewerProps = {
  modelPath: string;
  style?: ViewStyle;
};

export const ModelViewer =
  requireNativeView<ModelViewerProps>("ModelViewer");
