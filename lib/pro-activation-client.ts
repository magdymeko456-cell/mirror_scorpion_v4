import AsyncStorage from "@react-native-async-storage/async-storage";

const DEVICE_ID_KEY = "mirror-scorpion-pro-installation-id";

function randomBase36(length: number) {
  let value = "";
  while (value.length < length) value += Math.random().toString(36).slice(2).toUpperCase();
  return value.slice(0, length);
}

export function createProInstallationId(now = Date.now()) {
  return `MS4-${now.toString(36).toUpperCase()}-${randomBase36(10)}`;
}

export async function loadOrCreateProInstallationId() {
  const existing = await AsyncStorage.getItem(DEVICE_ID_KEY);
  if (existing?.startsWith("MS4-")) return existing;
  const id = createProInstallationId();
  await AsyncStorage.setItem(DEVICE_ID_KEY, id);
  return id;
}

export function normalizeProPatch(value: string) {
  return value.trim().replace(/\s+/g, "");
}

export function isSignedProPatch(value: string) {
  return /^MS4\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{32,}$/.test(normalizeProPatch(value));
}
