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
