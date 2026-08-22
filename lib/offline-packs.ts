import AsyncStorage from "@react-native-async-storage/async-storage";
import * as FileSystem from "expo-file-system/legacy";
import { Platform } from "react-native";

export async function persistLanguagePack(language: string, pack: unknown) {
  const raw = JSON.stringify(pack);
  const bytes = new TextEncoder().encode(raw).byteLength;

  if (Platform.OS !== "web" && FileSystem.documentDirectory) {
    const directory = `${FileSystem.documentDirectory}mirror-scorpion/languages/`;
    await FileSystem.makeDirectoryAsync(directory, { intermediates: true });
    const localUri = `${directory}${language}.json`;
    await FileSystem.writeAsStringAsync(localUri, raw, { encoding: FileSystem.EncodingType.UTF8 });
    return { localUri, byteLength: bytes };
  }

  await AsyncStorage.setItem(`mirror-scorpion-offline-language:${language}`, raw);
  return { localUri: undefined, byteLength: bytes };
}

export async function hasPersistedLanguagePack(language: string) {
  if (Platform.OS !== "web" && FileSystem.documentDirectory) {
    const uri = `${FileSystem.documentDirectory}mirror-scorpion/languages/${language}.json`;
    const info = await FileSystem.getInfoAsync(uri);
    return info.exists;
  }
  return Boolean(await AsyncStorage.getItem(`mirror-scorpion-offline-language:${language}`));
}
