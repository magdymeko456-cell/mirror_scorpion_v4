import { useEffect, useState } from "react";
import {
  AppState,
  FlatList,
  KeyboardAvoidingView,
  Linking,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  Share,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from "react-native";
import { StatusBar } from "expo-status-bar";
import { Stack, useLocalSearchParams, useRouter } from "expo-router";
import * as Haptics from "expo-haptics";
import * as Speech from "expo-speech";
import * as DocumentPicker from "expo-document-picker";
import * as Clipboard from "expo-clipboard";
import { RecordingPresets, requestRecordingPermissionsAsync, setAudioModeAsync, useAudioRecorder, useAudioRecorderState } from "expo-audio";
import * as FileSystem from "expo-file-system/legacy";
import { getSpeechAccessibilityLabel, getSpeechButtonLabel, prepareSpeechText, selectVoice, speechKey, storySpeechText, ttsDefaults, type AvailableVoice, type SpeechLanguage } from "@/lib/tts";

import { ScreenContainer } from "@/components/screen-container";
import { ChessBoard } from "@/components/chess-board";
import { checkContentSafety } from "@/lib/content-safety";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { useColors } from "@/hooks/use-colors";
import { trpc } from "@/lib/trpc";
import { defaultLanguagePreferences, languageLabel, loadLanguagePreferences, saveLanguagePreferences, type AppLanguage, type LanguagePreferences } from "@/lib/language";
import { type StoryVideoProject, type StoryVideoScene } from "@/lib/story-video";
import { downloadInspirationSource, fetchInspirationSource, readDownloadedInspiration, type InspirationCatalogItem } from "@/lib/inspiration";
import { legacyOfflineStories } from "@/lib/legacy-content";
import { persistLanguagePack } from "@/lib/offline-packs";
import { nativeFloatingTranslator } from "@/modules/floating-translator";
import { MINIMUM_DOCUMENT_PROCESSING_MS, normalizeDocumentUrl, waitForMinimumDocumentProcessing } from "@/lib/document-workflow";
import { storyNeedsExpansion, storyPreview } from "@/lib/story-preview";
import { isSignedProPatch, loadOrCreateProInstallationId, normalizeProPatch } from "@/lib/pro-activation-client";

const palette = {
  cyan: "#55D6FF",
  teal: "#62E9C7",
  orange: "#FFB340",
  purple: "#DA35F5",
  blue: "#5C9DFF",
};

function audioMimeType(fileName: string, reportedType?: string) {
  if (reportedType?.startsWith("audio/")) return reportedType;
  const extension = fileName.toLowerCase().split(".").pop();
  const byExtension: Record<string, string> = {
    mp3: "audio/mpeg",
    m4a: "audio/mp4",
    wav: "audio/wav",
    ogg: "audio/ogg",
    oga: "audio/ogg",
    webm: "audio/webm",
    aac: "audio/aac",
    flac: "audio/flac",
  };
  return extension ? byExtension[extension] ?? "" : "";
}

function stripBase64Prefix(value: string) {
  return value.replace(/^data:[^;]+;base64,/, "").replace(/\\s/g, "");
}

async function readAudioAsBase64(uri: string, suppliedBase64?: string) {
  if (suppliedBase64) return stripBase64Prefix(suppliedBase64);
  if (Platform.OS !== "web") {
    return FileSystem.readAsStringAsync(uri, { encoding: FileSystem.EncodingType.Base64 });
  }
  const response = await fetch(uri);
  if (!response.ok) throw new Error("تعذر قراءة الملف الصوتي من المتصفح");
  const bytes = new Uint8Array(await response.arrayBuffer());
  let binary = "";
  const chunkSize = 0x8000;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, Math.min(offset + chunkSize, bytes.length)));
  }
  return btoa(binary);
}

const titles: Record<string, string> = {
  translation: "ترجمة نصية",
  dialogue: "حوار مترجم",
  documents: "مستندات وعدسة",
  stories: "قصص وإلهام",
  games: "ألعاب 3D",
  settings: "الإعدادات",
};

const titlesEn: Record<string, string> = {
  translation: "Text Translation",
  dialogue: "Live Dialogue",
  documents: "Documents & Lens",
  stories: "Stories & Inspiration",
  games: "3D Games",
  settings: "Settings",
};

export default function FeatureScreen() {
  const { slug, sharedText } = useLocalSearchParams<{ slug: string; sharedText?: string }>();
  const router = useRouter();
  const colors = useColors("dark");
  const [appLanguage, setAppLanguage] = useState<AppLanguage>(() => defaultLanguagePreferences().appLanguage);
  useEffect(() => {
    void loadLanguagePreferences().then((preferences) => setAppLanguage(preferences.appLanguage));
  }, []);
  const title = (appLanguage === "en" ? titlesEn[slug ?? ""] : titles[slug ?? ""]) ?? "Mirror Scorpion";

  return (
    <ScreenContainer edges={["top", "bottom", "left", "right"]} containerClassName="bg-[#0B132B]">
      <StatusBar style="light" />
      <Stack.Screen options={{ headerShown: false }} />
      <View style={styles.screen}>
        <View style={styles.header}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="العودة"
            onPress={() => router.back()}
            style={({ pressed }) => [styles.backButton, pressed && styles.pressed]}
          >
            <Text style={[styles.backText, { color: colors.foreground }]}>‹</Text>
          </Pressable>
          <Text style={[styles.headerTitle, { color: colors.foreground }]}>{title}</Text>
          <View style={styles.headerSpacer} />
        </View>
        {slug === "translation" && <TranslationPanel colors={colors} initialText={sharedText} />}
        {slug === "dialogue" && <DialoguePanel colors={colors} />}
        {slug === "documents" && <DocumentsPanel colors={colors} />}
        {slug === "stories" && <StoriesPanel colors={colors} />}
        {slug === "games" && <GamesPanel colors={colors} />}
        {slug === "settings" && <SettingsPanel colors={colors} />}
      </View>
    </ScreenContainer>
  );
}

type Colors = ReturnType<typeof useColors>;

function useSpeechController() {
  const [activeKey, setActiveKey] = useState<string | null>(null);
  const [voices, setVoices] = useState<AvailableVoice[]>([]);

  useEffect(() => {
    let mounted = true;
    Speech.getAvailableVoicesAsync()
      .then((available) => {
        if (mounted) setVoices(available);
      })
      .catch(() => undefined);

    return () => {
      mounted = false;
      void Speech.stop();
    };
  }, []);

  const stop = () => {
    void Speech.stop();
    setActiveKey(null);
  };

  const speak = async (key: string, text: string, language: SpeechLanguage) => {
    const isSpeaking = await Speech.isSpeakingAsync();
    if (isSpeaking && activeKey === key) {
      stop();
      return;
    }

    await Speech.stop();
    const voice = selectVoice(voices, language);
    setActiveKey(key);
    Speech.speak(prepareSpeechText(text), {
      language,
      voice: voice?.identifier,
      ...ttsDefaults,
      onDone: () => setActiveKey(null),
      onStopped: () => setActiveKey(null),
      onError: () => setActiveKey(null),
    });
  };

  return { activeKey, speak, stop };
}

function SpeechButton({ label, active, onPress }: { label: string; active: boolean; onPress: () => void }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={getSpeechAccessibilityLabel(active, label)}
      onPress={onPress}
      style={({ pressed }) => [styles.speechButton, active && styles.speechButtonActive, pressed && styles.pressed]}
    >
      <Text style={[styles.speechButtonText, active && styles.speechButtonTextActive]}>{getSpeechButtonLabel(active)}</Text>
    </Pressable>
  );
}

function TranslationPanel({ colors, initialText }: { colors: Colors; initialText?: string }) {
  const [source, setSource] = useState(initialText ?? "");
  const [result, setResult] = useState("");
  const [preferences, setPreferences] = useState<LanguagePreferences>(() => defaultLanguagePreferences());
  const [status, setStatus] = useState("");
  const [audioBusy, setAudioBusy] = useState(false);
  const [recordingBusy, setRecordingBusy] = useState(false);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const textMutation = trpc.translation.text.useMutation();
  const translateAsync = textMutation.mutateAsync;
  const audioMutation = trpc.translation.audio.useMutation();
  const recorder = useAudioRecorder(RecordingPresets.HIGH_QUALITY);
  const recorderState = useAudioRecorderState(recorder);

  useEffect(() => {
    void loadLanguagePreferences().then(setPreferences);
    void setAudioModeAsync({ playsInSilentMode: true, allowsRecording: true }).catch(() => undefined);
  }, []);

  useEffect(() => {
    if (initialText?.trim()) setSource(initialText);
  }, [initialText]);

  useEffect(() => {
    const value = source.trim();
    if (!value) {
      setResult("");
      setStatus("");
      return;
    }
    let cancelled = false;
    const timer = setTimeout(() => {
      setStatus("تتم الترجمة تلقائياً…");
      void translateAsync({
        text: value,
        sourceLanguage: preferences.sourceLanguage,
        targetLanguage: preferences.targetLanguage,
      }).then((response) => {
        if (!cancelled) {
          setResult(response.translatedText);
          setStatus("تمت الترجمة تلقائياً");
        }
      }).catch(() => {
        if (!cancelled) setStatus("تعذر الاتصال بخدمة الترجمة؛ تحقق من الاتصال ثم أعد المحاولة.");
      });
    }, 650);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [preferences.sourceLanguage, preferences.targetLanguage, source, translateAsync]);

  const updateLanguage = (patch: Partial<LanguagePreferences>) => {
    const next = { ...preferences, ...patch };
    setPreferences(next);
    void saveLanguagePreferences(next);
  };

  const recordFromMicrophone = async () => {
    if (recordingBusy || audioBusy || audioMutation.isPending) return;
    setRecordingBusy(true);
    try {
      if (recorderState.isRecording) {
        await recorder.stop();
        const uri = recorder.uri;
        if (!uri) throw new Error("لم يتم إنشاء ملف التسجيل");
        setStatus("جارٍ رفع التسجيل وتفريغه وترجمته…");
        const base64 = await readAudioAsBase64(uri);
        const response = await audioMutation.mutateAsync({
          base64,
          fileName: "mirror-scorpion-recording.m4a",
          mimeType: "audio/mp4",
          sourceLanguage: preferences.sourceLanguage,
          targetLanguage: preferences.targetLanguage,
        });
        setSource(response.transcription);
        setResult(response.translatedText);
        setAudioUrl(response.audioUrl);
        setStatus("تم تسجيل الكلام وتفريغه وترجمته فعلياً");
      } else {
        const permission = await requestRecordingPermissionsAsync();
        if (!permission.granted) {
          setStatus("يجب السماح بالوصول إلى الميكروفون لتسجيل الكلام فعلياً.");
          return;
        }
        await recorder.prepareToRecordAsync();
        recorder.record();
        setStatus("جاري التسجيل… اضغط الميكروفون مرة أخرى للإيقاف والترجمة.");
      }
    } catch {
      setStatus("تعذر تسجيل أو معالجة الصوت. تحقق من إذن الميكروفون والاتصال.");
    } finally {
      setRecordingBusy(false);
    }
  };

  const pickAudio = async () => {
    if (audioBusy || recordingBusy || audioMutation.isPending) return;
    setAudioBusy(true);
    setStatus("جارٍ فتح ملفات الجهاز…");
    try {
      const picked = await DocumentPicker.getDocumentAsync({ type: "audio/*", copyToCacheDirectory: true, multiple: false });
      if (picked.canceled || !picked.assets[0]) {
        setStatus("");
        return;
      }
      const asset = picked.assets[0];
      const size = asset.size ?? 0;
      if (size > 16 * 1024 * 1024) {
        setStatus("الحد الأقصى للملف الصوتي هو 16 ميغابايت.");
        return;
      }
      const mimeType = audioMimeType(asset.name, asset.mimeType);
      if (!mimeType) {
        setStatus("اختر ملفاً صوتياً بصيغة MP3 أو M4A أو WAV أو OGG.");
        return;
      }
      // file attached
      setStatus("جارٍ قراءة الملف ثم تفريغه وترجمته…");
      const base64 = await readAudioAsBase64(asset.uri, asset.base64);
      const response = await audioMutation.mutateAsync({
        base64,
        fileName: asset.name,
        mimeType,
        sourceLanguage: preferences.sourceLanguage,
        targetLanguage: preferences.targetLanguage,
      });
      setSource(response.transcription);
      setResult(response.translatedText);
      setAudioUrl(response.audioUrl);
      setStatus(`تمت ترجمة ${asset.name} فعلياً`);
    } catch {
      setStatus("تعذر فتح أو رفع الملف الصوتي. تحقق من الصيغة والحجم والاتصال ثم حاول مجدداً.");
    } finally {
      setAudioBusy(false);
    }
  };

  const speech = useSpeechController();
  const speechKeyVal = speechKey("message", "translation-main");
  const translatedSpeechText = storySpeechText("الترجمة", result);

  const handleMicToggle = () => {
    void recordFromMicrophone();
  };

  const handleShareAudioOnly = async () => {
    try {
      if (!audioUrl) {
        setStatus("سجّل أو ارفع ملفاً صوتياً أولاً حتى يمكن مشاركته.");
        return;
      }
      await Share.share({ url: audioUrl, message: "ملف الصوت المترجم بواسطة ميرور سكربيون" });
      setStatus("تمت مشاركة ملف الصوت المترجم بنجاح");
    } catch {
      setStatus("تعذرت مشاركة ملف الصوت حالياً.");
    }
  };

  return (
    <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === "ios" ? "padding" : undefined}>
      <ScrollView contentContainerStyle={styles.panel} keyboardShouldPersistTaps="handled">
        {/* زر في منتصف الشاشة العلوي لتحديد لغة الترجمة من بين 100 لغة */}
        <View style={{ alignItems: "center", marginBottom: 10 }}>
          <Pressable
            onPress={() => updateLanguage({ targetLanguage: preferences.targetLanguage === "ar" ? "en" : "ar" })}
            style={{ paddingHorizontal: 22, paddingVertical: 10, borderRadius: 20, backgroundColor: "#14304D", borderWidth: 1, borderColor: palette.blue }}
          >
            <Text style={{ color: palette.blue, fontWeight: "900", fontSize: 13 }}>
              🌐 اللغة المستهدفة: {languageLabel(preferences.targetLanguage, "ar")} (100 لغة مدعومة)
            </Text>
          </Pressable>
        </View>

        {/* محرر علوي مع مايك لالتقاط الكلام */}
        <View style={{ backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, padding: 12, marginBottom: 12 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
            <Text style={{ fontSize: 11, fontWeight: "800", color: palette.blue }}>المحرر العلوي (الكلام الملتقط أو المعدل يدوياً)</Text>
            <Pressable
              onPress={handleMicToggle}
              style={{ width: 36, height: 36, borderRadius: 18, backgroundColor: recorderState.isRecording ? "#E85D75" : "#1B3A5C", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: palette.blue }}
            >
              <Text style={{ fontSize: 16, color: "#fff" }}>🎤</Text>
            </Pressable>
          </View>
          <TextInput
            value={source}
            onChangeText={setSource}
            placeholder={`اكتب بـ ${languageLabel(preferences.sourceLanguage, "ar")} أو تحدث بالمايك...`}
            placeholderTextColor={colors.muted}
            multiline
            textAlign="right"
            style={[styles.input, { color: colors.foreground, backgroundColor: "transparent", borderWidth: 0, minHeight: 80 }]}
          />
        </View>

        {/* مربع محرر ثاني لترجمة الجمل */}
        <View style={{ backgroundColor: "#111D33", borderRadius: 16, borderWidth: 1, borderColor: colors.border, padding: 12, marginBottom: 10 }}>
          <Text style={{ fontSize: 11, fontWeight: "800", color: palette.teal, marginBottom: 6 }}>المحرر الثاني (الترجمة المباشرة)</Text>
          <TextInput
            value={result}
            editable={false}
            placeholder="ستظهر الترجمة هنا..."
            placeholderTextColor={colors.muted}
            multiline
            textAlign="right"
            style={[styles.input, { color: palette.cyan, backgroundColor: "transparent", borderWidth: 0, minHeight: 80 }]}
          />
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginTop: 8, borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 8 }}>
            <View style={{ flexDirection: "row", gap: 6 }}>
              <Pressable
                disabled={audioBusy || audioMutation.isPending}
                onPress={pickAudio}
                style={{ paddingHorizontal: 10, paddingVertical: 6, backgroundColor: "#14304D", borderRadius: 8, borderWidth: 1, borderColor: palette.blue }}
              >
                <Text style={{ fontSize: 11, color: palette.blue, fontWeight: "800" }}>📎 دبوس رفع صوت</Text>
              </Pressable>
            </View>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
              <Pressable onPress={handleShareAudioOnly} style={{ padding: 6 }}>
                <Text style={{ fontSize: 16 }}>🎵</Text>
              </Pressable>
              <SpeechButton label="نطق الترجمة" active={speech.activeKey === speechKeyVal} onPress={() => void speech.speak(speechKeyVal, translatedSpeechText, preferences.targetLanguage === "ar" ? "ar-SA" : "en-US")} />
              <Pressable onPress={() => void Clipboard.setStringAsync(result).then(() => setStatus("تم نسخ الترجمة إلى الحافظة"))} style={{ padding: 6 }}>
                <Text style={{ fontSize: 16 }}>📋</Text>
              </Pressable>
            </View>
          </View>
          <Text style={{ fontSize: 9, color: colors.muted, marginTop: 4, fontStyle: "italic", textAlign: "left" }}>تمت الترجمة بواسطة ميرور سكربيون</Text>
        </View>

        <Text style={[styles.statusText, { color: status.includes("تعذر") ? "#FF8DAF" : palette.teal, textAlign: "center" }]}>{status}</Text>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function DialoguePanel({ colors }: { colors: Colors }) {
  const [sourceBox, setSourceBox] = useState("");
  const [targetBox, setTargetBox] = useState("");
  const [rightLang, setRightLang] = useState("العربية");
  const [leftLang, setLeftLang] = useState("الإنجليزية");
  const [isSwapped, setIsSwapped] = useState(false);
  const [listening, setListening] = useState(false);
  const [status, setStatus] = useState("");
  const speech = useSpeechController();
  const audioMutation = trpc.translation.audio.useMutation();
  const recorder = useAudioRecorder(RecordingPresets.HIGH_QUALITY);
  const recorderState = useAudioRecorderState(recorder);
  const [audioBusy, setAudioBusy] = useState(false);

  useEffect(() => {
    void setAudioModeAsync({ playsInSilentMode: true, allowsRecording: true }).catch(() => undefined);
  }, []);

  const handleSwap = () => {
    setIsSwapped((prev) => !prev);
    const temp = rightLang;
    setRightLang(leftLang);
    setLeftLang(temp);
  };

  const handleMicToggle = async () => {
    try {
      if (recorderState.isRecording) {
        await recorder.stop();
        const uri = recorder.uri;
        if (!uri) throw new Error("لم يتم إنشاء ملف التسجيل");
        setListening(false);
        setStatus("جارٍ رفع تسجيل الحوار وتفريغه وترجمته…");
        const base64 = await readAudioAsBase64(uri);
        const res = await audioMutation.mutateAsync({
          base64,
          fileName: "mirror-scorpion-dialogue.m4a",
          mimeType: "audio/mp4",
          sourceLanguage: isSwapped ? "en" : "ar",
          targetLanguage: isSwapped ? "ar" : "en",
        });
        setSourceBox(res.transcription);
        setTargetBox(res.translatedText);
        setStatus("تمت ترجمة الحوار الصوتي فعلياً");
      } else {
        const permission = await requestRecordingPermissionsAsync();
        if (!permission.granted) {
          setStatus("يجب السماح بالوصول إلى الميكروفون لتسجيل الحوار.");
          return;
        }
        await recorder.prepareToRecordAsync();
        recorder.record();
        setListening(true);
        setStatus("جاري تسجيل الحوار… اضغط المايك مرة أخرى للإيقاف والترجمة.");
      }
    } catch {
      setListening(false);
      setStatus("تعذر تسجيل الحوار أو ترجمته.");
    }
  };

  const handlePickAudio = async () => {
    if (audioBusy || audioMutation.isPending) return;
    setAudioBusy(true);
    try {
      const picked = await DocumentPicker.getDocumentAsync({ type: "audio/*", copyToCacheDirectory: true, multiple: false });
      if (picked.canceled || !picked.assets[0]) return;
      const asset = picked.assets[0];
      if ((asset.size ?? 0) > 16 * 1024 * 1024) {
        setStatus("الحد الأقصى لملف الحوار الصوتي هو 16 ميغابايت.");
        return;
      }
      const mimeType = audioMimeType(asset.name, asset.mimeType);
      if (!mimeType) {
        setStatus("اختر ملفاً صوتياً بصيغة MP3 أو M4A أو WAV أو OGG.");
        return;
      }
      setStatus(`جارٍ تفريغ وترجمة الملف الصوتي: ${asset.name}…`);
      const base64 = await readAudioAsBase64(asset.uri, asset.base64);
      const res = await audioMutation.mutateAsync({
        base64,
        fileName: asset.name,
        mimeType,
        sourceLanguage: isSwapped ? "en" : "ar",
        targetLanguage: isSwapped ? "ar" : "en",
      });
      setSourceBox(res.transcription);
      setTargetBox(res.translatedText);
      setStatus("تمت ترجمة محتوى ملف الحوار الصوتي فعلياً");
    } catch {
      setStatus("تعذر معالجة الملف الصوتي للحوار.");
    } finally {
      setAudioBusy(false);
    }
  };

  const speechKeyVal = speechKey("message", "dialogue-main");
  const translatedTextSpeech = storySpeechText("حوار", targetBox);

  return (
    <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === "ios" ? "padding" : undefined}>
      <ScrollView contentContainerStyle={styles.panel} keyboardShouldPersistTaps="handled">
        {/* شريط الاختيارات العلوي: زر يمين، تبديل، مايك، زر يسار */}
        <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 12, backgroundColor: colors.surface, padding: 8, borderRadius: 14, borderWidth: 1, borderColor: colors.border }}>
          <Pressable onPress={() => setRightLang(rightLang === "العربية" ? "الفرنسية" : "العربية")} style={{ paddingHorizontal: 10, paddingVertical: 6, backgroundColor: "#14304D", borderRadius: 8 }}>
            <Text style={{ fontSize: 11, fontWeight: "800", color: palette.blue }}>{rightLang}</Text>
          </Pressable>
          <Pressable onPress={handleSwap} style={{ width: 32, height: 32, borderRadius: 16, backgroundColor: "#1B3A5C", alignItems: "center", justifyContent: "center" }}>
            <Text style={{ fontSize: 14, color: palette.cyan }}>⇄</Text>
          </Pressable>
          <Pressable
            onPress={() => void handleMicToggle()}
            style={{ width: 44, height: 44, borderRadius: 22, backgroundColor: listening ? "#E85D75" : palette.teal, alignItems: "center", justifyContent: "center", shadowColor: palette.teal, shadowOpacity: 0.4, shadowRadius: 6 }}
          >
            <Text style={{ fontSize: 18, color: "#111" }}>{listening ? "■" : "🎙️"}</Text>
          </Pressable>
          <Pressable onPress={() => setLeftLang(leftLang === "الإنجليزية" ? "الألمانية" : "الإنجليزية")} style={{ paddingHorizontal: 10, paddingVertical: 6, backgroundColor: "#14304D", borderRadius: 8 }}>
            <Text style={{ fontSize: 11, fontWeight: "800", color: palette.teal }}>{leftLang}</Text>
          </Pressable>
        </View>

        {/* المربع العلوي (المحرر الأول المرتبط باللغة اليمنى حصراً) */}
        <View style={{ backgroundColor: colors.surface, borderRadius: 16, borderWidth: 1, borderColor: colors.border, padding: 12, marginBottom: 10 }}>
          <Text style={{ fontSize: 11, fontWeight: "800", color: palette.blue, marginBottom: 4 }}>المربع العلوي (مستقبل كلام اللغة اليمنى: {rightLang})</Text>
          <TextInput
            value={sourceBox}
            onChangeText={setSourceBox}
            placeholder="اضغط الميكروفون للتحدث أو اكتب هنا..."
            placeholderTextColor={colors.muted}
            multiline
            textAlign="right"
            style={[styles.input, { color: colors.foreground, backgroundColor: "transparent", borderWidth: 0, minHeight: 75 }]}
          />
        </View>

        {/* المربع السفلي للترجمة المباشرة للغة اليسرى */}
        <View style={{ backgroundColor: "#111D33", borderRadius: 16, borderWidth: 1, borderColor: colors.border, padding: 12, marginBottom: 10 }}>
          <Text style={{ fontSize: 11, fontWeight: "800", color: palette.teal, marginBottom: 4 }}>المربع السفلي (الترجمة إلى اللغة اليسرى: {leftLang})</Text>
          <TextInput
            value={targetBox}
            editable={false}
            placeholder="ستظهر الترجمة الفورية هنا..."
            placeholderTextColor={colors.muted}
            multiline
            textAlign="right"
            style={[styles.input, { color: palette.cyan, backgroundColor: "transparent", borderWidth: 0, minHeight: 75 }]}
          />
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginTop: 8, borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 8 }}>
            <Pressable onPress={handlePickAudio} style={{ paddingHorizontal: 10, paddingVertical: 6, backgroundColor: "#14304D", borderRadius: 8, borderWidth: 1, borderColor: palette.blue }}>
              <Text style={{ fontSize: 11, color: palette.blue, fontWeight: "800" }}>📎 رفع ملف صوتي</Text>
            </Pressable>
            <SpeechButton label="نطق الترجمة" active={speech.activeKey === speechKeyVal} onPress={() => void speech.speak(speechKeyVal, translatedTextSpeech, leftLang === "الإنجليزية" ? "en-US" : "ar-SA")} />
          </View>
        </View>

        {!!status && <Text style={[styles.statusText, { color: palette.teal, textAlign: "center" }]}>{status}</Text>}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function DocumentsPanel({ colors }: { colors: Colors }) {
  const [urlInput, setUrlInput] = useState("");
  const [selectedAsset, setSelectedAsset] = useState<{ uri: string; name: string; mimeType: string } | null>(null);
  const [ocrResult, setOcrResult] = useState<{ extractedText: string; translatedText: string; detectedLanguage: string; fileName: string } | null>(null);
  const [loadingModal, setLoadingModal] = useState(false);
  const [loadingSeconds, setLoadingSeconds] = useState(0);
  const [showTranslatedSheet, setShowTranslatedSheet] = useState(false);
  const [isHoldingOriginal, setIsHoldingOriginal] = useState(false);
  const [status, setStatus] = useState("");
  const [preferences, setPreferences] = useState<LanguagePreferences>(() => defaultLanguagePreferences());
  const ocrMutation = trpc.translation.ocr.useMutation();

  useEffect(() => {
    void loadLanguagePreferences().then(setPreferences);
  }, []);

  useEffect(() => {
    if (!loadingModal) {
      setLoadingSeconds(0);
      return;
    }
    setLoadingSeconds(Math.ceil(MINIMUM_DOCUMENT_PROCESSING_MS / 1_000));
    const timer = setInterval(() => {
      setLoadingSeconds((seconds) => Math.max(0, seconds - 1));
    }, 1_000);
    return () => clearInterval(timer);
  }, [loadingModal]);

  const handleBrowserOpen = async () => {
    try {
      const picked = await DocumentPicker.getDocumentAsync({ type: ["application/pdf", "image/*"], copyToCacheDirectory: true });
      if (picked.canceled || !picked.assets[0]) return;
      const asset = picked.assets[0];
      const mimeType = asset.mimeType || (asset.name.toLowerCase().endsWith(".pdf") ? "application/pdf" : "image/jpeg");
      setSelectedAsset({ uri: asset.uri, name: asset.name, mimeType });
      setUrlInput(asset.name);
      setStatus(`تم اختيار ${asset.name}. اضغط ترجمة المستند لبدء OCR الحقيقي.`);
    } catch {
      setStatus("تعذر فتح مستعرض الجهاز.");
    }
  };

  const handleOpenDocumentLink = async () => {
    const url = normalizeDocumentUrl(urlInput);
    if (!url) {
      setStatus("أدخل رابط HTTP أو HTTPS صالحاً للمستند أولاً، أو اختر الملف من الجهاز.");
      return;
    }
    try {
      const supported = await Linking.canOpenURL(url);
      if (!supported) {
        setStatus("تعذر فتح الرابط على هذا الجهاز. اختر الملف من الجهاز بدلاً من ذلك.");
        return;
      }
      await Linking.openURL(url);
      setStatus("فُتح الرابط في متصفح الجهاز. نزّل الملف ثم عد واختره لترجمته وحماية بياناتك.");
    } catch {
      setStatus("تعذر فتح رابط المستند. تحقق من الرابط والاتصال ثم حاول مرة أخرى.");
    }
  };

  const handleTranslateDocument = async () => {
    if (!selectedAsset) {
      setStatus("اختر PDF أو صورة أولاً؛ إدخال الرابط وحده لا ينفذ OCR من مصدر غير مرفوع.");
      return;
    }
    setLoadingModal(true);
    setStatus("جاري قراءة الملف ورفعه إلى التحليل متعدد الوسائط…");
    try {
      const base64 = await readAudioAsBase64(selectedAsset.uri);
      const [response] = await Promise.all([
        ocrMutation.mutateAsync({
          base64,
          fileName: selectedAsset.name,
          mimeType: selectedAsset.mimeType,
          targetLanguage: preferences.targetLanguage,
        }),
        waitForMinimumDocumentProcessing(),
      ]);
      setOcrResult(response);
      setShowTranslatedSheet(true);
      setStatus("اكتمل OCR والترجمة. اضغط مطولاً لرؤية النص الأصلي.");
    } catch {
      setStatus("تعذر تحليل المستند. تحقق من النوع والحجم والاتصال ثم حاول مرة أخرى.");
    } finally {
      setLoadingModal(false);
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.panel} keyboardShouldPersistTaps="handled">
      <View style={[styles.featureIntro, { borderColor: palette.teal }]}>
        <Text style={[styles.featureKicker, { color: palette.teal }]}>ترجمة المستندات والعدسة</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>اختر صورة أو PDF من جهازك لاستخراج النص وترجمته. يفتح رابط المستند في متصفح الجهاز لتنزيله أولاً؛ حد الصفحات وحفظ الملفات في المتصفح يتطلبان مساراً أصلياً منفصلاً ولا يُدّعى تنفيذهما هنا.</Text>
      </View>

      {/* زر العدسة للوصول إلى العدسة الكاملة */}
      <Pressable
        onPress={() => void handleBrowserOpen()}
        style={{ backgroundColor: "#14304D", borderWidth: 1, borderColor: palette.teal, borderRadius: 14, padding: 14, alignItems: "center", marginBottom: 12 }}
      >
        <Text style={{ color: palette.teal, fontWeight: "900", fontSize: 13 }}>📷 تشغيل العدسة ورفع صورة OCR</Text>
      </Pressable>

      {/* مستطيل متوسط الحجم للرابط بجوار زر بحث */}
      <View style={{ gap: 10 }}>
        <View style={{ flexDirection: "row", gap: 8, alignItems: "center" }}>
          <TextInput
            value={urlInput}
            onChangeText={setUrlInput}
            placeholder="اكتب رابط المستند أو انسخه هنا..."
            placeholderTextColor={colors.muted}
            style={[styles.input, { flex: 1, color: colors.foreground, backgroundColor: colors.surface, minHeight: 46, padding: 12 }]}
            textAlign="right"
          />
          <Pressable onPress={() => void handleOpenDocumentLink()} style={{ paddingHorizontal: 14, paddingVertical: 12, backgroundColor: "#1B3A5C", borderRadius: 10 }}>
            <Text style={{ color: palette.cyan, fontWeight: "800", fontSize: 12 }}>فتح الرابط</Text>
          </Pressable>
        </View>

        {/* زر فتح من المستعرض */}
        <Pressable onPress={handleBrowserOpen} style={{ backgroundColor: "#12284B", borderWidth: 1, borderColor: palette.blue, borderRadius: 12, padding: 12, alignItems: "center" }}>
          <Text style={{ color: palette.blue, fontWeight: "800", fontSize: 13 }}>📂 فتح من المستعرض واختيار الملف</Text>
        </Pressable>

        {/* زر كبير في الثلث الأخير للشاشة للترجمة */}
        <Pressable
          onPress={handleTranslateDocument}
          style={{ backgroundColor: palette.teal, borderRadius: 14, padding: 16, alignItems: "center", marginTop: 8 }}
        >
          <Text style={{ color: "#111", fontWeight: "900", fontSize: 15 }}>ترجمة المستند الشاملة</Text>
        </Pressable>
      </View>

      {/* شاشة التحميل (3 ثوانٍ) */}
      <Modal visible={loadingModal} transparent animationType="fade">
        <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.85)", justifyContent: "center", alignItems: "center" }}>
          <View style={{ backgroundColor: colors.surface, padding: 26, borderRadius: 16, alignItems: "center", gap: 12, borderWidth: 1, borderColor: palette.teal }}>
            <Text style={{ fontSize: 18, color: palette.teal, fontWeight: "900" }}>جاري معالجة المستند...</Text>
            <Text style={{ fontSize: 13, color: colors.muted, textAlign: "center" }}>
              {loadingSeconds > 0
                ? `نُظهر المعالجة لمدة ${loadingSeconds} ${loadingSeconds === 1 ? "ثانية" : "ثوانٍ"} على الأقل قبل العرض.`
                : "اكتملت الثلاث ثوانٍ؛ ما زال OCR يعمل حتى تصل نتيجة حقيقية."}
            </Text>
          </View>
        </View>
      </Modal>

      {/* شاشة العرض الكامل (المستند المترجم والمسحوب) */}
      <Modal visible={showTranslatedSheet} animationType="slide" transparent>
        <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.9)", justifyContent: "flex-end" }}>
          <View
            onStartShouldSetResponder={() => { setIsHoldingOriginal(true); return true; }}
            onResponderRelease={() => setIsHoldingOriginal(false)}
            style={{ height: "88%", backgroundColor: colors.surface, borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 18, borderWidth: 1, borderColor: palette.teal, justifyContent: "space-between" }}
          >
            <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
              <Text style={{ fontSize: 13, fontWeight: "800", color: palette.teal }}>
                {isHoldingOriginal ? "📄 المستند الأصلي (اضغط مطولاً للمعاينة)" : "✨ المستند المترجم فوق الأصلي"}
              </Text>
              <Pressable onPress={() => setShowTranslatedSheet(false)} style={{ padding: 6 }}>
                <Text style={{ color: "#FF8DAF", fontWeight: "900" }}>إغلاق ✕</Text>
              </Pressable>
            </View>

            <View style={{ flex: 1, backgroundColor: "#111D33", borderRadius: 14, padding: 18, justifyContent: "center", alignItems: "center", marginVertical: 10, position: "relative", overflow: "hidden" }}>
              <Text style={{ fontSize: 14, color: colors.foreground, textAlign: "right", lineHeight: 24 }}>
                {isHoldingOriginal
                  ? `[النص الأصلي — ${ocrResult?.detectedLanguage || "غير محدد"}]:\n${ocrResult?.extractedText || "لا يوجد نص مستخرج بعد."}`
                  : `[الترجمة إلى ${preferences.targetLanguage}]:\n${ocrResult?.translatedText || "لا توجد ترجمة بعد."}`}
              </Text>

              {/* توقيع التطبيق بطريقة شفافة عريضة بخط مائل 130 درجة */}
              {!isHoldingOriginal && (
                <View style={{ position: "absolute", transform: [{ rotate: "-35deg" }], opacity: 0.25 }}>
                  <Text style={{ fontSize: 24, fontWeight: "900", color: palette.cyan }}>
                    ترجم هذا المستند بواسطة ميرور اسكربيون
                  </Text>
                </View>
              )}
            </View>

            <View style={{ gap: 8 }}>
              <Text style={{ fontSize: 11, color: colors.muted, textAlign: "center" }}>اضغط مطولاً على الشاشة لرؤية المستند الأصلي، وارفع إصبعك لرؤية المستند المترجم.</Text>
              <Pressable onPress={() => void Share.share({ message: ocrResult?.translatedText || "لا توجد ترجمة مستند متاحة" })} style={{ backgroundColor: "#14304D", padding: 12, borderRadius: 10, alignItems: "center" }}>
                <Text style={{ color: palette.blue, fontWeight: "800", fontSize: 13 }}>مشاركة المستند المترجم</Text>
              </Pressable>
            </View>
          </View>
        </View>
      </Modal>

      {!!status && <Text style={[styles.statusText, { color: palette.teal, textAlign: "center", marginTop: 8 }]}>{status}</Text>}
    </ScrollView>
  );
}

function StoriesPanel({ colors }: { colors: Colors }) {
  const speech = useSpeechController();
  const [userStories, setUserStories] = useState<{ id: string; category: string; title: string; content: string }[]>([]);
  const [newTitle, setNewTitle] = useState("");
  const [newContent, setNewContent] = useState("");
  const [feedback, setFeedback] = useState("");
  const [videoProject, setVideoProject] = useState<StoryVideoProject | null>(null);
  const [isGeneratingVideo, setIsGeneratingVideo] = useState(false);
  const [aiMessage, setAiMessage] = useState("");
  const [expandedStoryId, setExpandedStoryId] = useState<string | null>(null);
  const [fullStoryText, setFullStoryText] = useState<Record<string, string>>({});
  const [downloadedSources, setDownloadedSources] = useState<Record<string, boolean>>({});
  const [sourceBusyId, setSourceBusyId] = useState<string | null>(null);
  const catalogQuery = trpc.inspiration.catalog.useQuery();
  const messageMutation = trpc.inspiration.message.useMutation();
  const videoMutation = trpc.inspiration.videoScript.useMutation();

  const handleGenerateVideo = async (title: string, category: string, content: string) => {
    setIsGeneratingVideo(true);
    setFeedback(`جارٍ تحليل القصة بواسطة الذكاء الاصطناعي وبناء سيناريو 10–15 دقيقة…`);
    try {
      const fullText = content.trim().length >= 80 ? content.trim() : `${content.trim()}\n\nيرجى إثراء هذه المادة من المصدر المرفق مع المحافظة على الإسناد وعدم اختلاق أحداث.`;
      const project = await videoMutation.mutateAsync({ title, category, fullText, language: "ar" });
      setVideoProject(project);
      setFeedback(`تم توليد سيناريو ذكاء اصطناعي منظم (${project.scenes.length} مشهد، مدة مقترحة لا تقل عن 10 دقائق).`);
    } catch {
      setFeedback("تعذر الاتصال بأداة الذكاء الاصطناعي. احتفظت بالمادة ولم أستبدلها بنص وهمي.");
    } finally {
      setIsGeneratingVideo(false);
    }
  };

  const handleGenerateInspiration = async () => {
    setFeedback("جاري إنشاء رسالة إلهام مخصصة وآمنة…");
    try {
      const response = await messageMutation.mutateAsync({ language: "ar", mood: "التوازن والثبات", focus: "الأمل والعمل الهادئ" });
      setAiMessage(`${response.message}${response.action ? `\\n\\nخطوة اليوم: ${response.action}` : ""}`);
      setFeedback("تم إنشاء الرسالة بواسطة الذكاء الاصطناعي.");
    } catch {
      setFeedback("تعذر إنشاء رسالة الذكاء الاصطناعي حالياً.");
    }
  };

  const predefinedStories = [
    { id: "1", category: "تفسير الجلالين", title: "حكمة استخلاف الإنسان في الأرض", content: "مستوحى من تفسير الجلالين: إن جعل الإنسان خليفة في الأرض يحمل أمانة الإعمار والعدل، فالكلمة الطيبة والعمل النافع هما أساس بقاء الأثر الجميل في حياة الأمم وتنمية المجتمعات." },
    { id: "2", category: "قصص الأنبياء", title: "صبر نوح عليه السلام ودعوته", content: "من قصص الأنبياء لابن كثير: دعا قومه ألف سنة إلا خمسين عاماً بالحكمة والموعظة الحسنة، ليضرب أعظم مثال في الصبر والمثابرة على الحق والرفق بالمدعوين." },
    { id: "3", category: "قصص الأقوام", title: "عبرة قوم سبأ وحكمة الشكر", content: "من تاريخ الأمم: كانت جنتان عن يمين وشمال، فلما أعرضوا عن الشكر وبطرتهم النعمة، أرسل الله عليهم سيل العرم لتكون عبرة بأن شكر النعم يديمها." },
    { id: "4", category: "قصص الحيوانات", title: "حكمة الهدهد مع نبي الله سليمان", content: "من قصص القرآن والحيوان: لم تكن طاعة الهدهد عمياء، بل حمل خبراً عظيماً وحكمة في استطلاع الحقائق ونقل المعرفة بصدق ودقة بالغة." },
  ];

  useEffect(() => {
    void AsyncStorage.getItem("mirror-scorpion-user-stories").then((saved) => {
      if (saved) {
        try {
          const parsed = JSON.parse(saved);
          if (Array.isArray(parsed)) setUserStories(parsed);
        } catch {}
      }
    });
  }, []);

  useEffect(() => {
    const catalog = catalogQuery.data ?? [];
    if (catalog.length === 0) return;
    void Promise.all(catalog.map(async (item) => ({ id: item.id, cached: await readDownloadedInspiration(item).catch(() => null) })))
      .then((entries) => setDownloadedSources(Object.fromEntries(entries.filter((entry) => entry.cached).map((entry) => [entry.id, true]))));
  }, [catalogQuery.data]);

  const downloadSource = async (item: InspirationCatalogItem) => {
    if (sourceBusyId) return;
    setSourceBusyId(item.id);
    setFeedback(`جاري تنزيل مصدر "${item.titleAr}" إلى مساحة التطبيق…`);
    try {
      const downloaded = await downloadInspirationSource(item);
      setDownloadedSources((current) => ({ ...current, [item.id]: true }));
      setFeedback(`اكتمل تنزيل المصدر فعلياً (${Math.max(1, Math.round(downloaded.byteLength / 1024))} كيلوبايت).`);
    } catch {
      setFeedback("تعذر تنزيل المصدر. تحقق من الاتصال وحاول مرة أخرى.");
    } finally {
      setSourceBusyId(null);
    }
  };

  const showMoreSource = async (item: InspirationCatalogItem) => {
    setSourceBusyId(item.id);
    setExpandedStoryId(item.id);
    try {
      const cached = await readDownloadedInspiration(item);
      const source = cached ?? await fetchInspirationSource(item);
      setFullStoryText((current) => ({ ...current, [item.id]: source.text || source.raw }));
    } catch {
      setExpandedStoryId(null);
      setFeedback("تعذر فتح النص الكامل للمصدر حالياً.");
    } finally {
      setSourceBusyId(null);
    }
  };

  const publishStory = () => {
    const title = newTitle.trim();
    const content = newContent.trim();
    if (!title || !content) {
      setFeedback("يرجى إدخال عنوان ومحتوى القصة.");
      return;
    }
    const checkT = checkContentSafety(title);
    const checkC = checkContentSafety(content);
    if (!checkT.safe || !checkC.safe) {
      setFeedback(checkT.reason || checkC.reason || "المحتوى يخالف معايير الأمان والاحترام.");
      return;
    }
    const newItem = {
      id: `user-${Date.now()}`,
      category: "قصص المستخدم",
      title,
      content,
    };
    const next = [newItem, ...userStories];
    setUserStories(next);
    setNewTitle("");
    setNewContent("");
    setFeedback("تم نشر قصتك بنجاح وبشكل آمن يحترم معايير المجتمع.");
    void AsyncStorage.setItem("mirror-scorpion-user-stories", JSON.stringify(next));
    if (Platform.OS !== "web") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const remoteStories: { id: string; category: string; title: string; content: string; source: InspirationCatalogItem }[] = (catalogQuery.data ?? [])
    .filter((item) => item.category !== "inspiration")
    .map((item) => ({ id: `remote-${item.id}`, category: item.sourceName, title: item.titleAr, content: item.summaryAr, source: item }));
  const allStories = [...userStories, ...legacyOfflineStories, ...remoteStories, ...predefinedStories];

  return (
    <View style={styles.flex}>
      <FlatList
        data={allStories}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.storyList}
        ListHeaderComponent={
          <View style={[styles.featureIntro, { borderColor: palette.orange, marginBottom: 16 }]}>
            <Text style={[styles.featureKicker, { color: palette.orange }]}>ركن الإلهام والمصادر</Text>
            <Text style={[styles.featureDescription, { color: colors.muted }]}>مستوحى من مصادر قابلة للتنزيل مع إسناد واضح، وقصص مستخدمين آمنة، وأدوات ذكاء اصطناعي تنشئ رسالة إلهام أو سيناريو مفصلاً دون اختلاق أو إساءة.</Text>
            <View style={{ flexDirection: "row", gap: 8, marginTop: 12 }}>
              <ActionButton label={messageMutation.isPending ? "جاري الإلهام…" : "✨ رسالة إلهام بالذكاء"} color={palette.orange} onPress={() => void handleGenerateInspiration()} />
              <Text style={{ flex: 1, color: colors.muted, fontSize: 10, lineHeight: 16, textAlign: "right" }}>توليد عند الطلب، وليس تشخيصاً للحالة.</Text>
            </View>
            {!!aiMessage && <Text style={{ color: colors.foreground, backgroundColor: "#152642", borderColor: palette.orange, borderWidth: 1, borderRadius: 12, padding: 12, lineHeight: 22, textAlign: "right" }}>{aiMessage}</Text>}
            <View style={{ gap: 8, marginTop: 12 }}>
              <TextInput value={newTitle} onChangeText={setNewTitle} placeholder="عنوان القصة أو الحكمة..." placeholderTextColor={colors.muted} textAlign="right" style={[styles.input, { minHeight: 46, color: colors.foreground, borderColor: colors.border, backgroundColor: colors.surface, padding: 12 }]} />
              <TextInput value={newContent} onChangeText={setNewContent} placeholder="اكتب قصتك بأسلوب هادف وراقي..." placeholderTextColor={colors.muted} multiline textAlign="right" style={[styles.input, { minHeight: 90, color: colors.foreground, borderColor: colors.border, backgroundColor: colors.surface, padding: 12 }]} />
              <ActionButton label="نشر القصة بحرية آمنة" color={palette.orange} onPress={publishStory} />
              {!!feedback && <Text style={[styles.statusText, { color: feedback.includes("نجاح") || feedback.includes("بنجاح") || feedback.includes("اكتمل") || feedback.includes("تم توليد") ? palette.teal : "#FF8DAF" }]}>{feedback}</Text>}
            {!!catalogQuery.isLoading && <Text style={{ color: colors.muted, textAlign: "center", fontSize: 11 }}>جاري تحميل فهرس المصادر…</Text>}
            {!!catalogQuery.isError && <Text style={{ color: "#FF8DAF", textAlign: "center", fontSize: 11 }}>تعذر تحميل الفهرس الآن؛ يمكنك استخدام القصص المحلية.</Text>}
            </View>
            {videoProject && (
              <View style={{ marginTop: 14, backgroundColor: "#152642", borderWidth: 1, borderColor: palette.orange, borderRadius: 16, padding: 14, gap: 10 }}>
                <Text style={{ fontSize: 15, fontWeight: "800", color: palette.orange }}>🎬 مشروع الفيديو السينمائي: {videoProject.title}</Text>
                <Text style={{ fontSize: 12, color: colors.muted }}>عدد المشاهد المتسلسلة: {videoProject.scenes.length} مشهد وثائقي مفصل بدون اختصار.</Text>
                {videoProject.scenes.map((scene: StoryVideoScene) => (
                  <View key={scene.sceneNumber} style={{ backgroundColor: colors.surface, borderRadius: 10, padding: 10, borderWidth: 1, borderColor: colors.border, gap: 4 }}>
                    <Text style={{ fontSize: 12, fontWeight: "800", color: palette.cyan }}>مشهد {scene.sceneNumber} ({scene.durationSeconds} ثوانٍ)</Text>
                    <Text style={{ fontSize: 12, color: colors.foreground }}>{scene.narrativeText}</Text>
                    <Text style={{ fontSize: 10, color: colors.muted, fontStyle: "italic" }}>وصف المشهد البصري: {scene.visualPrompt}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        }
        renderItem={({ item }) => {
          const sourceItem: InspirationCatalogItem | undefined = "source" in item ? (item.source as InspirationCatalogItem) : undefined;
          const expansionId = sourceItem?.id ?? item.id;
          const isExpanded = expandedStoryId === expansionId;
          const fullContent = sourceItem && isExpanded ? fullStoryText[sourceItem.id] || item.content : item.content;
          const visibleContent = isExpanded ? fullContent : storyPreview(fullContent);
          const canExpand = Boolean(sourceItem) || storyNeedsExpansion(fullContent);
          const storySpeechKey = speechKey("story", item.id);
          const storyText = storySpeechText(item.title, fullContent);
          return (
            <View style={[styles.storyCard, { backgroundColor: colors.surface, borderColor: "#70501E" }]}>
              <View style={styles.storyTopline}>
                <Text style={[styles.storyCategory, { color: palette.orange }]}>{item.category}</Text>
                <View style={{ flexDirection: "row", gap: 6 }}>
                  <Pressable
                    disabled={isGeneratingVideo}
                    onPress={() => handleGenerateVideo(item.title, item.category, item.content)}
                    style={{ paddingHorizontal: 10, paddingVertical: 6, borderRadius: 8, backgroundColor: "#1B3A5C", borderWidth: 1, borderColor: palette.orange }}
                  >
                    <Text style={{ fontSize: 11, fontWeight: "800", color: palette.orange }}>{isGeneratingVideo ? "جاري التوليد…" : "🎥 تحويل لفيديو"}</Text>
                  </Pressable>
                  <SpeechButton label={`قصة ${item.title}`} active={speech.activeKey === storySpeechKey} onPress={() => void speech.speak(storySpeechKey, storyText, "ar-SA")} />
                  {sourceItem && <Pressable onPress={() => void downloadSource(sourceItem)} disabled={sourceBusyId === sourceItem.id} style={{ paddingHorizontal: 8, paddingVertical: 6, borderRadius: 8, backgroundColor: "#14304D", borderWidth: 1, borderColor: palette.teal }}><Text style={{ fontSize: 10, fontWeight: "800", color: palette.teal }}>{downloadedSources[sourceItem.id] ? "✓ تم التنزيل" : sourceBusyId === sourceItem.id ? "جاري…" : "📥 تنزيل"}</Text></Pressable>}
                </View>
              </View>
              <Text style={[styles.storyTitle, { color: colors.foreground }]}>{item.title}</Text>
              <Text style={[styles.storyContent, { color: colors.muted }]}>{visibleContent}</Text>
              {(sourceItem || canExpand) && <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginTop: 8 }}>
                <Text style={{ flex: 1, color: colors.muted, fontSize: 10, textAlign: "right" }}>{sourceItem ? `المصدر: ${sourceItem.sourceName}` : "محتوى محفوظ محلياً داخل التطبيق"}</Text>
                <Pressable disabled={sourceItem ? sourceBusyId === sourceItem.id : false} onPress={() => {
                  if (isExpanded) {
                    setExpandedStoryId(null);
                  } else if (sourceItem) {
                    void showMoreSource(sourceItem);
                  } else {
                    setExpandedStoryId(item.id);
                  }
                }} style={{ paddingHorizontal: 9, paddingVertical: 6, borderRadius: 8, borderWidth: 1, borderColor: palette.orange, opacity: sourceItem && sourceBusyId === sourceItem.id ? 0.55 : 1 }}><Text style={{ fontSize: 10, fontWeight: "800", color: palette.orange }}>{sourceItem && sourceBusyId === sourceItem.id ? "جاري الفتح…" : isExpanded ? "إخفاء" : "المزيد"}</Text></Pressable>
              </View>}
              {sourceItem && isExpanded && sourceBusyId === sourceItem.id && <Text style={{ color: colors.muted, marginTop: 8, textAlign: "right" }}>جاري تنزيل النص الكامل من المصدر…</Text>}
            </View>
          );
        }}
      />
    </View>
  );
}

function GamesPanel({ colors }: { colors: Colors }) {
  const [rubikState, setRubikState] = useState([
    ["#E63946", "#F1FAEE", "#A8DADC"],
    ["#457B9D", "#1D3557", "#E9C46A"],
    ["#2A9D8F", "#F4A261", "#E76F51"]
  ]);
  const [rubikMsg, setRubikMsg] = useState("قم بتدوير الوجوه أو اضغط حل المكعب لتعلم خطوات التفكير المنطقي.");

  const rotateTile = (r: number, c: number) => {
    const colorsList = ["#E63946", "#F1FAEE", "#A8DADC", "#457B9D", "#1D3557", "#E9C46A", "#2A9D8F", "#F4A261"];
    setRubikState((current) => {
      const next = current.map((row) => [...row]);
      const currentIdx = colorsList.indexOf(next[r][c]);
      next[r][c] = colorsList[(currentIdx + 1) % colorsList.length];
      return next;
    });
    setRubikMsg(`تم تعديل المربع (${r + 1}, ${c + 1}). ركّز في الأنماط لإيجاد التناسق.`);
    if (Platform.OS !== "web") Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const solveRubik = () => {
    setRubikState([
      ["#E63946", "#E63946", "#E63946"],
      ["#F1FAEE", "#F1FAEE", "#F1FAEE"],
      ["#A8DADC", "#A8DADC", "#A8DADC"]
    ]);
    setRubikMsg("تم تطبيق خوارزمية الحل التلقائي: ترتيب الألوان وتنسيق المربعات. تدرّب مجدداً لاكتساب مهارات حل المشكلات.");
    if (Platform.OS !== "web") Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  return (
    <ScrollView contentContainerStyle={styles.panel}>
      <View style={[styles.featureIntro, { borderColor: palette.purple }]}>
        <Text style={[styles.featureKicker, { color: palette.purple }]}>ساحة التفكير - الشطرنج</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>لوحة شطرنج محلية تفاعلية مع مؤقت متقدم وحركات قانونية.</Text>
      </View>
      <ChessBoard />
      <View style={styles.divider} />
      <View style={[styles.featureIntro, { borderColor: palette.purple }]}>
        <Text style={[styles.featureKicker, { color: palette.purple }]}>مكعب روبيك التفاعلي 3D</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>اضغط على أي مربع لتدوير لونه، أو استخدم زر الحل التلقائي عند التعثر لتعلم مهارات التفكير واستراتيجيات الحل.</Text>
        <View style={{ alignItems: "center", marginVertical: 12 }}>
          <View style={styles.rubik}>
            {rubikState.map((row, r) => row.map((color, c) => (
              <Pressable
                key={`${r}-${c}`}
                accessibilityRole="button"
                accessibilityLabel={`مربع روبيك ${r + 1} و ${c + 1}`}
                onPress={() => rotateTile(r, c)}
                style={[styles.rubikTile, { backgroundColor: color }]}
              />
            )))}
          </View>
        </View>
        <ActionButton label="حل المكعب تلقائياً (إظهار المسار)" color={palette.purple} onPress={solveRubik} />
        {!!rubikMsg && <Text style={[styles.statusText, { color: colors.muted, textAlign: "center", marginTop: 8 }]}>{rubikMsg}</Text>}
      </View>
    </ScrollView>
  );
}


function SettingsPanel({ colors }: { colors: Colors }) {
  const [notifications, setNotifications] = useState(true);
  const [compact, setCompact] = useState(false);
  const [preferences, setPreferences] = useState<LanguagePreferences>(() => defaultLanguagePreferences());
  const [paymentStatus, setPaymentStatus] = useState("");
  const [proInstallationId, setProInstallationId] = useState("");
  const [activationPatch, setActivationPatch] = useState("");
  const [isProActive, setIsProActive] = useState(false);
  const [offlineDownloaded, setOfflineDownloaded] = useState<Record<string, boolean>>({});
  const [offlineProgress, setOfflineProgress] = useState<Record<string, number>>({});
  const [downloadingCode, setDownloadingCode] = useState<string | null>(null);
  const [offlineMsg, setOfflineMsg] = useState("");
  const [bubbleEnabled, setBubbleEnabled] = useState(false);
  const [bubbleMsg, setBubbleMsg] = useState("");
  const [sourceDownloaded, setSourceDownloaded] = useState<Record<string, boolean>>({});
  const [sourceDownloading, setSourceDownloading] = useState<string | null>(null);
  const [sourceMsg, setSourceMsg] = useState("");
  const packMutation = trpc.translation.pack.useMutation();
  const inspirationCatalogQuery = trpc.inspiration.catalog.useQuery();
  const proStatusQuery = trpc.pro.status.useQuery();
  const proActivationMutation = trpc.pro.activate.useMutation();

  const allLanguages = [
    { code: "ar", name: "العربية (العربية)" },
    { code: "en", name: "الإنجليزية (English)" },
    { code: "fr", name: "الفرنسية (Français)" },
    { code: "es", name: "الإسبانية (Español)" },
    { code: "de", name: "الألمانية (Deutsch)" },
    { code: "tr", name: "التركية (Türkçe)" },
    { code: "it", name: "الإيطالية (Italiano)" },
    { code: "pt", name: "البرتغالية (Português)" },
    { code: "ja", name: "اليابانية (日本語)" },
    { code: "ko", name: "الكورية (한국어)" },
    { code: "zh", name: "الصينية (中文)" },
    { code: "ru", name: "الروسية (Русский)" },
  ];

  useEffect(() => {
    void loadLanguagePreferences().then(setPreferences);
    void loadOrCreateProInstallationId().then(setProInstallationId).catch(() => setPaymentStatus("تعذر إنشاء معرّف التثبيت المحلي حالياً."));
    void AsyncStorage.getItem("mirror-scorpion-offline-packs").then((val) => {
      if (val) {
        try { setOfflineDownloaded(JSON.parse(val)); } catch {}
      }
    });
    void AsyncStorage.getItem("mirror-scorpion-bubble-enabled").then(async (val) => {
      const enabled = val === "true";
      setBubbleEnabled(enabled);
      if (enabled && Platform.OS === "android" && nativeFloatingTranslator?.canDrawOverlays()) {
        const state = nativeFloatingTranslator.getState();
        setBubbleEnabled(await nativeFloatingTranslator.start(state.x, state.y));
      }
    });
    const subscription = AppState.addEventListener("change", (state) => {
      if (state !== "active" || Platform.OS !== "android" || !nativeFloatingTranslator) return;
      void AsyncStorage.getItem("mirror-scorpion-bubble-enabled").then(async (val) => {
        if (val !== "true" || !nativeFloatingTranslator?.canDrawOverlays()) return;
        const position = nativeFloatingTranslator.getState();
        setBubbleEnabled(await nativeFloatingTranslator.start(position.x, position.y));
      });
    });
    return () => {
      subscription.remove();
    };
  }, []);

  useEffect(() => {
    const catalog = inspirationCatalogQuery.data ?? [];
    if (catalog.length === 0) return;
    void Promise.all(catalog.map(async (item) => ({ id: item.id, cached: await readDownloadedInspiration(item).catch(() => null) })))
      .then((entries) => setSourceDownloaded(Object.fromEntries(entries.filter((entry) => entry.cached).map((entry) => [entry.id, true]))));
  }, [inspirationCatalogQuery.data]);

  const chooseAppLanguage = (appLanguage: AppLanguage) => {
    const next = { ...preferences, appLanguage };
    setPreferences(next);
    void saveLanguagePreferences(next);
  };

  const downloadInspirationPack = async (item: InspirationCatalogItem) => {
    if (sourceDownloading) return;
    setSourceDownloading(item.id);
    setSourceMsg(`جاري تنزيل مصدر "${item.titleAr}"…`);
    try {
      const downloaded = await downloadInspirationSource(item);
      setSourceDownloaded((current) => ({ ...current, [item.id]: true }));
      setSourceMsg(`تم تنزيل "${item.titleAr}" فعلياً (${Math.max(1, Math.round(downloaded.byteLength / 1024))} كيلوبايت).`);
    } catch {
      setSourceMsg("تعذر تنزيل المصدر. لم يتم تسجيله كمصدر أوف لاين.");
    } finally {
      setSourceDownloading(null);
    }
  };

  const downloadLanguagePack = async (code: string, name: string) => {
    if (downloadingCode || packMutation.isPending) return;
    setDownloadingCode(code);
    setOfflineProgress((current) => ({ ...current, [code]: 5 }));
    setOfflineMsg(`جاري طلب حزمة بيانات لغة "${name}" من الخادم…`);
    try {
      const pack = await packMutation.mutateAsync({ language: code as never });
      setOfflineProgress((current) => ({ ...current, [code]: 65 }));
      const stored = await persistLanguagePack(code, pack);
      setOfflineProgress((current) => ({ ...current, [code]: 100 }));
      setOfflineDownloaded((current) => {
        const next = { ...current, [code]: true };
        void AsyncStorage.setItem("mirror-scorpion-offline-packs", JSON.stringify(next));
        return next;
      });
      setOfflineMsg(`اكتمل تنزيل حزمة "${name}" وتخزينها فعلياً (${Math.max(1, Math.round(stored.byteLength / 1024))} كيلوبايت).`);
      if (Platform.OS !== "web") void Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } catch {
      setOfflineProgress((current) => ({ ...current, [code]: 0 }));
      setOfflineMsg(`تعذر تنزيل حزمة "${name}". لم يتم تسجيلها كحزمة جاهزة.`);
    } finally {
      setDownloadingCode(null);
    }
  };

  const copyProInstallationId = async () => {
    if (!proInstallationId) return;
    await Clipboard.setStringAsync(proInstallationId);
    setPaymentStatus("تم نسخ معرّف التثبيت. أرسله للدعم فقط عند طلب باتش PRO.");
  };

  const activatePro = async () => {
    const patch = normalizeProPatch(activationPatch);
    if (!proInstallationId) {
      setPaymentStatus("جاري تجهيز معرّف التثبيت؛ أعد المحاولة بعد لحظة.");
      return;
    }
    if (!isSignedProPatch(patch)) {
      setPaymentStatus("صيغة الباتش غير صالحة. الصيغة المتوقعة: MS4.payload.signature.");
      return;
    }
    if (!proStatusQuery.data?.verificationAvailable) {
      setPaymentStatus("تحقق التوقيع الخادمي غير متاح حالياً؛ لم يتم تفعيل PRO ولم يُحفظ الباتش.");
      return;
    }
    try {
      const result = await proActivationMutation.mutateAsync({ deviceId: proInstallationId, patch });
      if (!result.valid) {
        setIsProActive(false);
        setPaymentStatus("تعذر التحقق من الباتش أو أنه لا يخص معرّف التثبيت الحالي.");
        return;
      }
      setIsProActive(true);
      setPaymentStatus("تم التحقق من توقيع باتش PRO بنجاح على الخادم لهذا التثبيت.");
      await AsyncStorage.setItem("mirror-scorpion-pro-verified", JSON.stringify({ deviceId: proInstallationId, verifiedAt: Date.now(), plan: result.payload?.plan ?? "pro" }));
      if (Platform.OS !== "web") void Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } catch {
      setIsProActive(false);
      setPaymentStatus("تعذر الاتصال بخدمة تحقق PRO؛ لم يتم تفعيل أي ميزة مدفوعة.");
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.panel}>
      {/* قسم تفعيل النسخة البرو وطرق التفعيل */}
      <View style={[styles.proCard, { borderColor: palette.orange }]}>
        <Text style={[styles.proBadge, { color: palette.orange }]}>MIRROR SCORPION PRO</Text>
        <Text style={[styles.proTitle, { color: colors.foreground }]}>تفعيل النسخة المدفوعة والترقية</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>تُفعَّل النسخة PRO بباتش موقّع ومربوط بمعرّف تثبيت محلي. لا يجمع التطبيق رقم الهاتف أو معرّفات العتاد، ولا يعتبر الاختيار التسويقي أو إدخال أي نص تفعيلاً فعلياً.</Text>
        <View style={styles.planRow}>
          <ChoiceButton label="شهري" active={false} onPress={() => setPaymentStatus("تم اختيار الخطة الشهرية؛ تواصل مع الدعم لاستلام باتش موقّع.")} colors={colors} />
          <ChoiceButton label="سنوي" active={false} onPress={() => setPaymentStatus("تم اختيار الخطة السنوية؛ تواصل مع الدعم لاستلام باتش موقّع.")} colors={colors} />
        </View>
        <View style={{ gap: 8, marginTop: 12 }}>
          <Text style={{ color: colors.muted, fontSize: 11, textAlign: "right" }}>معرّف التثبيت المحلي</Text>
          <Pressable onPress={() => void copyProInstallationId()} style={{ borderWidth: 1, borderColor: palette.orange, backgroundColor: "#111D33", borderRadius: 12, padding: 12 }}>
            <Text style={{ color: colors.foreground, fontSize: 13, fontWeight: "800", textAlign: "center" }}>{proInstallationId || "جارٍ تجهيز المعرّف…"}</Text>
            <Text style={{ color: palette.orange, fontSize: 10, textAlign: "center", marginTop: 4 }}>اضغط لنسخه</Text>
          </Pressable>
          <TextInput value={activationPatch} onChangeText={setActivationPatch} placeholder="ألصق باتش التفعيل الموقّع MS4.…" placeholderTextColor={colors.muted} autoCapitalize="none" autoCorrect={false} textAlign="left" style={[styles.input, { minHeight: 56, color: colors.foreground, backgroundColor: colors.surface, borderColor: colors.border, padding: 12 }]} />
          <ActionButton label={proActivationMutation.isPending ? "جارٍ التحقق…" : isProActive ? "PRO مفعّلة ✓" : "تفعيل النسخة PRO"} color={palette.orange} onPress={() => void activatePro()} disabled={proActivationMutation.isPending || isProActive} />
          <Text style={{ color: proStatusQuery.data?.verificationAvailable ? palette.teal : colors.muted, fontSize: 11, lineHeight: 17, textAlign: "right" }}>{proStatusQuery.data?.verificationAvailable ? "خدمة التحقق الموقّع جاهزة." : "خدمة التحقق الموقّع قيد الإعداد؛ لن تُفعّل PRO محلياً قبل تحقق الخادم."}</Text>
        </View>
        {!!paymentStatus && <Text style={[styles.statusText, { color: isProActive ? palette.teal : colors.muted, textAlign: "center", marginTop: 6 }]}>{paymentStatus}</Text>}
      </View>

      <View style={[styles.proCard, { borderColor: palette.orange }]}>
        <Text style={[styles.proBadge, { color: palette.orange }]}>مصادر القصص والإلهام أوف لاين</Text>
        <Text style={[styles.proTitle, { color: colors.foreground }]}>تنزيل المصادر للقراءة دون اتصال</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>يتم تنزيل JSON/النص المصدر إلى مساحة التطبيق الخاصة. لا يتم اعتبار المصدر جاهزاً أوف لاين إلا بعد نجاح الكتابة الفعلية.</Text>
        <View style={{ gap: 8, marginTop: 10 }}>
          {(inspirationCatalogQuery.data ?? []).filter((item) => item.category !== "inspiration").map((item) => (
            <View key={item.id} style={[styles.languagePackRow, { borderColor: colors.border, backgroundColor: colors.surface }]}>
              <View style={styles.languagePackHeader}>
                <Text style={[styles.infoLabel, { color: colors.foreground, flex: 1, textAlign: "right" }]}>{item.titleAr}</Text>
                <ActionButton label={sourceDownloaded[item.id] ? "تم التنزيل ✓" : sourceDownloading === item.id ? "جاري…" : "تنزيل المصدر"} color={sourceDownloaded[item.id] ? palette.teal : palette.orange} onPress={() => void downloadInspirationPack(item)} disabled={sourceDownloaded[item.id] || sourceDownloading !== null} />
              </View>
              <Text style={{ color: colors.muted, fontSize: 10, textAlign: "right" }}>{item.sourceName}</Text>
            </View>
          ))}
        </View>
        {!!sourceMsg && <Text style={[styles.statusText, { color: palette.teal, textAlign: "center", marginTop: 8 }]}>{sourceMsg}</Text>}
      </View>
      {/* قائمة مستقلة لتنزيل حزم اللغات أوف لاين */}
      <View style={[styles.proCard, { borderColor: palette.blue }]}>
        <Text style={[styles.proBadge, { color: palette.blue }]}>حزم اللغات أوف لاين المستقلة</Text>
        <Text style={[styles.proTitle, { color: colors.foreground }]}>مركز تحميل اللغات للعمل بدون إنترنت</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>قم بتنزيل حزمة بيانات اللغة وتخزينها داخل مساحة التطبيق. الحزمة الحالية تمهّد للتشغيل المحلي، بينما الترجمة العامة غير المحدودة تحتاج محرك ترجمة عصبي مضمناً في نسخة أصلية لاحقة.</Text>
        <View style={{ gap: 8, marginTop: 10 }}>
          {allLanguages.map((lang) => {
            const isDownloaded = !!offlineDownloaded[lang.code];
            return (
              <View key={lang.code} style={[styles.languagePackRow, { borderColor: colors.border, backgroundColor: colors.surface }]}>
                <View style={styles.languagePackHeader}>
                  <Text style={[styles.infoLabel, { color: colors.foreground }]}>{lang.name}</Text>
                  <ActionButton
                    label={isDownloaded ? "تم التنزيل أوف لاين ✓" : downloadingCode === lang.code ? "جاري التحميل..." : "تنزيل الحزمة"}
                  color={isDownloaded ? palette.teal : downloadingCode === lang.code ? "#52708A" : palette.blue}
                  onPress={() => downloadLanguagePack(lang.code, lang.name)}
                  disabled={isDownloaded || downloadingCode !== null}
                />
                </View>
                {downloadingCode === lang.code && (
                  <View style={styles.progressArea}>
                    <View style={[styles.progressTrack, { backgroundColor: colors.border }]}>
                      <View style={[styles.progressFill, { width: `${offlineProgress[lang.code] ?? 0}%`, backgroundColor: palette.cyan }]} />
                    </View>
                    <Text style={[styles.progressLabel, { color: palette.cyan }]}>{offlineProgress[lang.code] ?? 0}% — جاري تنزيل الحزمة</Text>
                  </View>
                )}
              </View>
            );
          })}
        </View>
        {!!offlineMsg && <Text style={[styles.statusText, { color: palette.teal, textAlign: "center", marginTop: 8 }]}>{offlineMsg}</Text>}
      </View>

      {/* حول التطبيق والمزايا أوف لاين */}
      <View style={[styles.proCard, { borderColor: palette.teal }]}>
        <Text style={[styles.proBadge, { color: palette.teal }]}>حول التطبيق والمزايا أوف لاين</Text>
        <Text style={[styles.proTitle, { color: colors.foreground }]}>Mirror Scorpion v4 - الإصدار الملكي</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>
          تطبيق متكامل يجمع بين قوة الترجمة الذكية، مكتبة الإلهام وأسباب النزول المستوحاة من التراث الأصيل، وساحة الألعاب والتفكير (شطرنج ومكعب روبيك 3D).{"\n\n"}
          مزايا العمل أوف لاين: تتيح لك حزم اللغات المحملة إجراء عمليات الترجمة واستعراض المكتبة محلياً دون استهلاك باقة الإنترنت أو الحاجة لشبكة قوية.
        </Text>
      </View>

      {/* نبذة المطور والإهداء */}
      <View style={[styles.proCard, { borderColor: palette.purple }]}>
        <Text style={[styles.proBadge, { color: palette.purple }]}>نبذة عن المطور والإهداء</Text>
        <Text style={[styles.proTitle, { color: colors.foreground }]}>رسالة وفاء وإهداء خاص</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>
          تم تطوير هذا النظام الهندسي المتقدم بواسطة المهندس / المبرمج بجهد متواصل وشغف عميق بالحلول البرمجية النظيفة.{"\n\n"}
          الإهداء: إلى كل باحث عن الإتقان، وإلى كل روح تتبنى التفرد والابتكار بلا حدود؛ هذا العمل ثمرة تضافر الفكر البشري والقدرات الذكية لصنع أدوات تخلد الأثر الطيب.
        </Text>
      </View>

      {/* طرق التواصل الرسمية */}
      <View style={[styles.proCard, { borderColor: palette.cyan }]}>
        <Text style={[styles.proBadge, { color: palette.cyan }]}>طرق التواصل والدعم</Text>
        <Text style={[styles.proTitle, { color: colors.foreground }]}>تواصل معنا ومقترحاتك</Text>
        <Text style={[styles.featureDescription, { color: colors.muted }]}>
          نرحب دائماً بمقترحاتكم وتواصلكم لتطوير النظام:{"\n"}
          • WhatsApp: 01017341250 | 01031680816 | 01558203456{"\n"}
          • البريد الإلكتروني: dosoky.server@gmail.com{"\n"}
          • الدعم: أرسل معرّف التثبيت للحصول على باتش PRO موقّع عند التفعيل اليدوي.
        </Text>
      </View>

      <View style={[styles.infoRow, { borderColor: colors.border, backgroundColor: colors.surface }]}><Text style={[styles.infoLabel, { color: colors.muted }]}>لغة الجهاز</Text><Text style={[styles.infoValue, { color: colors.foreground }]}>{preferences.appLanguage === "ar" ? "العربية" : "English"}</Text></View>
      <View style={[styles.settingLanguage, { borderColor: colors.border, backgroundColor: colors.surface }]}><Text style={[styles.settingTitle, { color: colors.foreground }]}>لغة واجهة التطبيق</Text><View style={styles.planRow}><ChoiceButton label="العربية" active={preferences.appLanguage === "ar"} onPress={() => chooseAppLanguage("ar")} colors={colors} /><ChoiceButton label="English" active={preferences.appLanguage === "en"} onPress={() => chooseAppLanguage("en")} colors={colors} /></View></View>
      <SettingRow title="الفقاعة العائمة فوق التطبيقات" subtitle={bubbleEnabled ? "مفعلة: اسحبها فوق البريد وWhatsApp واضغطها لفتح الترجمة" : "مغلقة"} value={bubbleEnabled} onChange={(value) => {
        if (Platform.OS === "android" && nativeFloatingTranslator) {
          if (!value) {
            nativeFloatingTranslator.stop();
            setBubbleEnabled(false);
            setBubbleMsg("");
            void AsyncStorage.setItem("mirror-scorpion-bubble-enabled", "false");
          } else {
            const state = nativeFloatingTranslator.getState();
            if (!state.permissionGranted) {
              nativeFloatingTranslator.requestOverlayPermission();
              setBubbleEnabled(false);
              setBubbleMsg("فعّل إذن الظهور فوق التطبيقات في إعدادات Android ثم عد إلى التطبيق.");
              void AsyncStorage.setItem("mirror-scorpion-bubble-enabled", "true");
            } else {
              void nativeFloatingTranslator.start(state.x, state.y).then((started) => {
                setBubbleEnabled(started);
                setBubbleMsg(started ? "تم تشغيل الفقاعة فوق التطبيقات. يمكنك سحبها إلى الموضع المناسب." : "تعذر تشغيل الفقاعة الأصلية.");
                void AsyncStorage.setItem("mirror-scorpion-bubble-enabled", String(started));
              });
            }
          }
        } else {
          setBubbleEnabled(value);
          setBubbleMsg(Platform.OS === "web" ? "المعاينة الحالية تعرض الفقاعة داخل التطبيق فقط؛ Overlay النظام يحتاج APK Android." : "هذه النسخة لا تحتوي على وحدة Overlay أصلية.");
          void AsyncStorage.setItem("mirror-scorpion-bubble-enabled", String(value));
        }
      }} colors={colors} />
      {!!bubbleMsg && <Text style={{ color: colors.muted, fontSize: 11, lineHeight: 18, textAlign: "right" }}>{bubbleMsg}</Text>}
      <Text style={{ color: colors.muted, fontSize: 11, lineHeight: 18, textAlign: "right" }}>تعمل الفقاعة وفق مسار آمن: يشارك المستخدم النص من البريد أو WhatsApp إلى Mirror Scorpion، أو يضغط الفقاعة لفتح الترجمة. لا يقرأ التطبيق رسائل التطبيقات الأخرى تلقائياً ولا يستخدم Accessibility Service.</Text>
      <SettingRow title="الإشعارات الذكية" subtitle="تنبيهات خفيفة عند اكتمال المهام" value={notifications} onChange={setNotifications} colors={colors} />
      <SettingRow title="الوضع المختصر" subtitle="تقليل المسافات في القوائم" value={compact} onChange={setCompact} colors={colors} />
      <View style={[styles.infoRow, { borderColor: colors.border }]}><Text style={[styles.infoLabel, { color: colors.muted }]}>الإصدار</Text><Text style={[styles.infoValue, { color: colors.foreground }]}>v4.0.0</Text></View>
    </ScrollView>
  );
}

function SettingRow({ title, subtitle, value, onChange, colors }: { title: string; subtitle: string; value: boolean; onChange: (value: boolean) => void; colors: Colors }) {
  return <View style={[styles.settingRow, { borderColor: colors.border, backgroundColor: colors.surface }]}><View style={styles.settingCopy}><Text style={[styles.settingTitle, { color: colors.foreground }]}>{title}</Text><Text style={[styles.settingSubtitle, { color: colors.muted }]}>{subtitle}</Text></View><Switch value={value} onValueChange={onChange} trackColor={{ false: "#4B5566", true: palette.cyan }} thumbColor="#FFFFFF" /></View>;
}

function ChoiceButton({ label, active, onPress, colors }: { label: string; active: boolean; onPress: () => void; colors: Colors }) {
  return <Pressable accessibilityRole="button" onPress={onPress} style={({ pressed }) => [styles.choice, { borderColor: active ? palette.cyan : colors.border, backgroundColor: active ? "#143A50" : colors.surface }, pressed && styles.pressed]}><Text style={[styles.choiceText, { color: active ? palette.cyan : colors.muted }]}>{label}</Text></Pressable>;
}

function ActionButton({ label, color, onPress, disabled = false }: { label: string; color: string; onPress: () => void; disabled?: boolean }) {
  return <Pressable accessibilityRole="button" accessibilityState={{ disabled }} disabled={disabled} onPress={onPress} style={({ pressed }) => [styles.actionButton, { backgroundColor: color, opacity: disabled ? 0.72 : 1 }, pressed && styles.pressed]}><Text style={styles.actionLabel}>{label}</Text></Pressable>;
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  screen: { flex: 1 },
  header: { height: 60, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 16 },
  backButton: { width: 42, height: 42, alignItems: "center", justifyContent: "center", borderRadius: 21, backgroundColor: "#15243B" },
  backText: { fontSize: 38, lineHeight: 42, fontWeight: "300" },
  headerTitle: { fontSize: 21, lineHeight: 30, fontWeight: "800" },
  headerSpacer: { width: 42 },
  panel: { padding: 18, paddingBottom: 38, gap: 16 },
  featureIntro: { borderWidth: 1, borderRadius: 22, padding: 16, gap: 5 },
  featureKicker: { fontSize: 15, lineHeight: 22, fontWeight: "800" },
  featureDescription: { fontSize: 14, lineHeight: 22 },
  segmentRow: { flexDirection: "row-reverse", gap: 8 },
  choice: { flex: 1, minHeight: 44, borderWidth: 1, borderRadius: 14, paddingHorizontal: 12, alignItems: "center", justifyContent: "center" },
  choiceText: { fontSize: 12, lineHeight: 18, fontWeight: "700", textAlign: "center" },
  input: { minHeight: 130, borderWidth: 1, borderRadius: 18, padding: 15, fontSize: 16, lineHeight: 24, textAlignVertical: "top" },
  tallInput: { minHeight: 190 },
  actionButton: { minHeight: 50, borderRadius: 17, alignItems: "center", justifyContent: "center", paddingHorizontal: 20 },
  actionLabel: { color: "#07131E", fontSize: 15, lineHeight: 21, fontWeight: "800" },
  resultBox: { minHeight: 122, borderWidth: 1, borderRadius: 18, padding: 16, gap: 10 },
  resultLabel: { fontSize: 12, lineHeight: 18, fontWeight: "700" },
  resultText: { fontSize: 18, lineHeight: 28, fontWeight: "700" },
  audioUpload: { minHeight: 72, borderWidth: 1, borderRadius: 18, paddingHorizontal: 16, paddingVertical: 12, justifyContent: "center", flexDirection: "row", alignItems: "center", gap: 12 },
  audioUploadBusy: { opacity: 0.6 },
  audioPin: { fontSize: 24, lineHeight: 28 },
  audioUploadCopy: { flex: 1, gap: 4 },
  audioUploadTitle: { fontSize: 15, lineHeight: 22, fontWeight: "800", textAlign: "right" },
  audioUploadHint: { fontSize: 12, lineHeight: 18, textAlign: "right" },
  statusText: { minHeight: 20, fontSize: 12, lineHeight: 18, textAlign: "right" },
  chatList: { padding: 18, gap: 10, flexGrow: 1 },
  message: { maxWidth: "82%", paddingHorizontal: 15, paddingVertical: 12, borderRadius: 18, marginVertical: 5 },
  messageLeft: { alignSelf: "flex-start", borderBottomLeftRadius: 5 },
  messageRight: { alignSelf: "flex-end", borderBottomRightRadius: 5 },
  messageText: { color: "#F2F7FF", fontSize: 15, lineHeight: 23 },
  messageFooter: { marginTop: 8, flexDirection: "row", justifyContent: "flex-start" },
  speechButton: { minHeight: 30, paddingHorizontal: 10, borderRadius: 10, justifyContent: "center", backgroundColor: "#17334A", borderWidth: 1, borderColor: "#4B7894" },
  speechButtonActive: { backgroundColor: "#63314C", borderColor: "#FF8DAF" },
  speechButtonText: { color: "#BCEAFF", fontSize: 10, fontWeight: "800" },
  speechButtonTextActive: { color: "#FFD1DD" },
  composer: { borderTopWidth: 1, padding: 12, flexDirection: "row-reverse", alignItems: "center", gap: 8 },
  composerInput: { flex: 1, minHeight: 46, borderWidth: 1, borderRadius: 16, paddingHorizontal: 13, fontSize: 15 },
  micButton: { width: 46, height: 46, borderRadius: 23, alignItems: "center", justifyContent: "center" },
  micText: { color: "#07131E", fontSize: 16, fontWeight: "800" },
  sendButton: { minHeight: 46, paddingHorizontal: 14, borderRadius: 16, alignItems: "center", justifyContent: "center" },
  sendText: { color: "#07131E", fontSize: 13, fontWeight: "800" },
  scanFrame: { minHeight: 190, borderWidth: 1, borderRadius: 26, alignItems: "center", justifyContent: "center", gap: 7, borderStyle: "dashed" },
  scanIcon: { fontSize: 54, lineHeight: 60 },
  scanTitle: { fontSize: 18, lineHeight: 25, fontWeight: "800" },
  scanHint: { fontSize: 13, lineHeight: 19 },
  categoryRow: { gap: 8, paddingVertical: 14 },
  storyList: { padding: 18, paddingBottom: 36 },
  storyCard: { borderWidth: 1, borderRadius: 20, padding: 16, marginBottom: 12, gap: 7 },
  storyTopline: { flexDirection: "row-reverse", alignItems: "center", justifyContent: "space-between", gap: 10 },
  storyCategory: { fontSize: 12, lineHeight: 18, fontWeight: "800" },
  storyTitle: { fontSize: 19, lineHeight: 27, fontWeight: "800" },
  storyContent: { fontSize: 14, lineHeight: 23 },
  gameTitle: { fontSize: 18, lineHeight: 26, fontWeight: "800", marginTop: 4 },
  board: { width: "100%", aspectRatio: 1, flexDirection: "row", flexWrap: "wrap", borderWidth: 3, borderColor: "#9C6F3D" },
  square: { width: "12.5%", height: "12.5%" },
  selectedSquare: { borderWidth: 3, borderColor: "#FFFFFF" },
  selectedLabel: { textAlign: "center", fontSize: 13, lineHeight: 20 },
  divider: { height: 1, backgroundColor: "#31435F", marginVertical: 8 },
  rubik: { width: 210, height: 210, alignSelf: "center", flexDirection: "row", flexWrap: "wrap", gap: 5, padding: 7, backgroundColor: "#0F1727", borderRadius: 18 },
  rubikTile: { width: 62, height: 62, borderRadius: 8, borderWidth: 2, borderColor: "#0B132B" },
  proCard: { borderWidth: 1, borderRadius: 22, padding: 18, gap: 9, backgroundColor: "#2B2418" },
  planRow: { flexDirection: "row-reverse", gap: 8 },
  settingLanguage: { borderWidth: 1, borderRadius: 18, padding: 16, gap: 12 },
  proBadge: { fontSize: 11, lineHeight: 17, fontWeight: "900", letterSpacing: 1.5 },
  proTitle: { fontSize: 22, lineHeight: 30, fontWeight: "800" },
  settingRow: { minHeight: 78, borderWidth: 1, borderRadius: 18, paddingHorizontal: 16, paddingVertical: 12, flexDirection: "row-reverse", alignItems: "center", justifyContent: "space-between", gap: 12 },
  settingCopy: { flex: 1, gap: 3 },
  settingTitle: { fontSize: 16, lineHeight: 23, fontWeight: "800", textAlign: "right" },
  settingSubtitle: { fontSize: 12, lineHeight: 18, textAlign: "right" },
  infoRow: { minHeight: 56, borderWidth: 1, borderRadius: 16, paddingHorizontal: 16, flexDirection: "row-reverse", alignItems: "center", justifyContent: "space-between" },
  languagePackRow: { borderWidth: 1, borderRadius: 16, padding: 12, gap: 8 },
  languagePackHeader: { flexDirection: "row-reverse", alignItems: "center", justifyContent: "space-between", gap: 10 },
  progressArea: { gap: 4 },
  progressTrack: { height: 8, borderRadius: 5, overflow: "hidden" },
  progressFill: { height: "100%", borderRadius: 5 },
  progressLabel: { fontSize: 11, lineHeight: 16, textAlign: "right", fontWeight: "800" },
  infoLabel: { fontSize: 13, lineHeight: 19 },
  infoValue: { fontSize: 14, lineHeight: 20, fontWeight: "800" },
  pressed: { opacity: 0.75, transform: [{ scale: 0.98 }] },
});
