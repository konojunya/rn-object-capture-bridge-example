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
