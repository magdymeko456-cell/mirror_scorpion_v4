import { useCallback, useEffect, useMemo, useState } from "react";
import {
  AppState,
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
import { Image } from "expo-image";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";

import { ScreenContainer } from "@/components/screen-container";
import { useColors } from "@/hooks/use-colors";
import { trpc } from "@/lib/trpc";
import { defaultLanguagePreferences, loadLanguagePreferences, type LanguagePreferences } from "@/lib/language";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { nativeFloatingTranslator } from "@/modules/floating-translator";
import { shouldShowInAppTranslationBubble } from "@/lib/floating-bubble-visibility";

const palette = {
  cyan: "#55D6FF",
  teal: "#62E9C7",
  orange: "#FFB340",
  purple: "#DA35F5",
  blue: "#5C9DFF",
};

const features = [
  {
    id: "translation",
    title: "الترجمة النصية",
    titleEn: "Text Translation",
    subtitle: "نص، صوت، ولغات متعددة",
    subtitleEn: "Text, voice, multi-language",
    icon: "文",
    accent: "#5C9DFF",
    glow: "#162C56",
  },
  {
    id: "dialogue",
    title: "الحوار الفوري",
    titleEn: "Live Dialogue",
    subtitle: "محادثة ثنائية ومتابعة",
    subtitleEn: "Two-way dialogue",
    icon: "💬",
    accent: "#16E6E2",
    glow: "#123C4A",
  },
  {
    id: "documents",
    title: "المستندات والعدسة",
    titleEn: "Documents & Lens",
    subtitle: "مسح ضوئي واستخراج نصوص",
    subtitleEn: "OCR & Document analysis",
    icon: "▣",
    accent: "#62E9C7",
    glow: "#123C48",
  },
  {
    id: "stories",
    title: "قصص وأسباب النزول",
    titleEn: "Stories & Context",
    subtitle: "تفسير الجلالين وقصص الأنبياء",
    subtitleEn: "Spiritual library & stories",
    icon: "📖",
    accent: "#FFB340",
    glow: "#43341C",
  },
  {
    id: "games",
    title: "ساحة الألعاب والتفكير",
    titleEn: "Games & Logic",
    subtitle: "شطرنج ومكعب روبيك 3D",
    subtitleEn: "Chess & Rubik 3D",
    icon: "✦",
    accent: "#DA35F5",
    glow: "#321A4C",
  },
  {
    id: "settings",
    title: "الإعدادات والنسخة المدفوعة",
    titleEn: "Settings & PRO",
    subtitle: "اشتراكات وحزم أوف لاين",
    subtitleEn: "PRO plans & offline packs",
    icon: "⚙️",
    accent: "#91A4BA",
    glow: "#1A2C42",
  },
] as const;

export default function HomeScreen() {
  const router = useRouter();
  const colors = useColors("dark");
  const [bubbleEnabled, setBubbleEnabled] = useState(false);
  const [bubbleNotice, setBubbleNotice] = useState("");
  const [pressedId, setPressedId] = useState<string | null>(null);
  const [preferences, setPreferences] = useState<LanguagePreferences>(() => defaultLanguagePreferences());

  useEffect(() => {
    void loadLanguagePreferences().then(setPreferences);
  }, []);

  const syncNativeBubble = useCallback(async (enabled: boolean, requestPermission = true) => {
    if (Platform.OS !== "android" || !nativeFloatingTranslator) {
      setBubbleEnabled(enabled);
      setBubbleNotice("");
      return;
    }

    if (!enabled) {
      nativeFloatingTranslator.stop();
      setBubbleEnabled(false);
      setBubbleNotice("");
      await AsyncStorage.setItem("mirror-scorpion-bubble-enabled", "false");
      return;
    }

    const state = nativeFloatingTranslator.getState();
    if (!state.permissionGranted) {
      if (requestPermission) nativeFloatingTranslator.requestOverlayPermission();
      setBubbleEnabled(false);
      setBubbleNotice("اسمح بالظهور فوق التطبيقات من إعدادات Android ثم عد إلى التطبيق لإكمال التفعيل.");
      await AsyncStorage.setItem("mirror-scorpion-bubble-enabled", "true");
      return;
    }

    const started = await nativeFloatingTranslator.start(state.x, state.y);
    setBubbleEnabled(started);
    setBubbleNotice(started ? "الفقاعة تعمل فوق التطبيقات ويمكن سحبها إلى أي موضع." : "تعذر تشغيل الفقاعة الأصلية؛ حاول مجدداً بعد منح الصلاحية.");
    await AsyncStorage.setItem("mirror-scorpion-bubble-enabled", String(started));
  }, []);

  useEffect(() => {
    let mounted = true;
    void AsyncStorage.getItem("mirror-scorpion-bubble-enabled").then(async (value) => {
      if (!mounted || value !== "true") return;
      if (Platform.OS === "android" && nativeFloatingTranslator) {
        const state = nativeFloatingTranslator.getState();
        if (state.permissionGranted) {
          const started = await nativeFloatingTranslator.start(state.x, state.y);
          if (mounted) setBubbleEnabled(started);
        } else if (mounted) {
          setBubbleNotice("امنح صلاحية الظهور فوق التطبيقات لإظهار الفقاعة فوق البريد وWhatsApp عند طلبك.");
        }
      } else if (mounted) {
        setBubbleEnabled(true);
      }
    });
    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    if (Platform.OS !== "android" || !nativeFloatingTranslator) return;
    const subscription = AppState.addEventListener("change", (state) => {
      if (state !== "active") return;
      const sharedText = nativeFloatingTranslator?.consumeSharedText();
      if (sharedText?.trim()) {
        router.push({ pathname: "/feature/translation", params: { sharedText } } as never);
        return;
      }
      void AsyncStorage.getItem("mirror-scorpion-bubble-enabled").then(async (value) => {
        if (value !== "true" || !nativeFloatingTranslator?.canDrawOverlays()) return;
        const position = nativeFloatingTranslator.getState();
        const started = await nativeFloatingTranslator.start(position.x, position.y);
        setBubbleEnabled(started);
        setBubbleNotice(started ? "الفقاعة تعمل فوق التطبيقات ويمكن سحبها إلى أي موضع." : "");
      });
    });
    return () => subscription.remove();
  }, [router]);

  useEffect(() => {
    if (Platform.OS !== "android" || !nativeFloatingTranslator) return;
    const sharedText = nativeFloatingTranslator.consumeSharedText();
    if (sharedText?.trim()) {
      router.push({ pathname: "/feature/translation", params: { sharedText } } as never);
    }
  }, [router]);

  const isEnglish = preferences.appLanguage === "en";
  const greeting = useMemo(() => isEnglish ? "Where beginnings are made" : "حيث تُصنع البدايات", [isEnglish]);

  const openFeature = (id: string) => {
    if (Platform.OS !== "web") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    router.push(`/feature/${id}` as never);
  };

  const toggleBubble = (value: boolean) => {
    if (Platform.OS !== "web") {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    }
    void syncNativeBubble(value);
  };

  return (
    <ScreenContainer edges={["top", "left", "right"]} containerClassName="bg-[#0B132B]">
      <StatusBar style="light" />
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        <View style={styles.page}>
          <View style={styles.hero}>
            <View style={[styles.logoHalo, { borderColor: palette.cyan, backgroundColor: "#112440", shadowColor: palette.cyan }]}>
              <Image
                source={require("../../assets/images/legacy-scorpion-hero.jpeg")}
                contentFit="cover"
                style={styles.heroImage}
                accessibilityLabel="شعار العقرب الملكي"
              />
            </View>
            <Text style={[styles.brand, { color: palette.cyan, fontWeight: "900", letterSpacing: 1 }]}>{isEnglish ? "Mirror Scorpion v4" : "ميرور سكربيون v4"}</Text>
            <Text style={[styles.tagline, { color: colors.muted }]}>{greeting}</Text>
          </View>

          <Pressable
            accessibilityRole="switch"
            accessibilityLabel={isEnglish ? "Enable floating translator" : "تفعيل الفقاعة العائمة"}
            accessibilityState={{ checked: bubbleEnabled }}
            onPress={() => toggleBubble(!bubbleEnabled)}
            style={({ pressed }) => [
              styles.bubbleRow,
              { borderColor: bubbleEnabled ? colors.primary : colors.border },
              pressed && styles.pressed,
            ]}
          >
            <View style={styles.bubbleLabelRow}>
              <Text style={[styles.bubbleGlyph, { color: colors.muted }]}>••</Text>
              <Text style={[styles.bubbleLabel, { color: colors.foreground }]}>{isEnglish ? "Enable floating translator" : "تفعيل الفقاعة العائمة"}</Text>
            </View>
            <Switch
              value={bubbleEnabled}
              onValueChange={toggleBubble}
              trackColor={{ false: "#4B5566", true: colors.primary }}
              thumbColor={bubbleEnabled ? "#FFFFFF" : "#D4DBE7"}
              ios_backgroundColor="#4B5566"
            />
          </Pressable>
          {bubbleNotice ? <Text style={[styles.bubbleNotice, { color: colors.muted }]}>{bubbleNotice}</Text> : null}

          <View style={styles.grid}>
            {features.map((item) => (
              <Pressable
                key={item.id}
                accessibilityRole="button"
                accessibilityLabel={isEnglish ? item.titleEn : item.title}
                onPress={() => openFeature(item.id)}
                onPressIn={() => setPressedId(item.id)}
                onPressOut={() => setPressedId(null)}
                style={({ pressed }) => [
                  styles.card,
                  {
                    backgroundColor: colors.surface,
                    borderColor: item.accent,
                    shadowColor: item.accent,
                  },
                  (pressed || pressedId === item.id) && styles.cardPressed,
                ]}
              >
                <View style={{ flex: 1, paddingRight: 12 }}>
                  <Text style={[styles.cardTitle, { color: item.accent }]}>{isEnglish ? item.titleEn : item.title}</Text>
                  <Text style={[styles.cardSubtitle, { color: colors.muted }]}>{isEnglish ? item.subtitleEn : item.subtitle}</Text>
                </View>
                <View style={[styles.iconBadge, { backgroundColor: item.glow }]}>
                  <Text style={[styles.icon, { color: item.accent }]}>{item.icon}</Text>
                </View>
              </Pressable>
            ))}
          </View>

          <Text style={[styles.version, { color: colors.muted }]}>v4.0.0  •  {isEnglish ? "Build ready" : "جاهز للبناء"}</Text>
        </View>
      </ScrollView>
      <TranslationBubble visible={shouldShowInAppTranslationBubble({ enabled: bubbleEnabled, platform: Platform.OS, hasNativeOverlay: Boolean(nativeFloatingTranslator) })} colors={colors} />
    </ScreenContainer>
  );
}

function TranslationBubble({ visible, colors }: { visible: boolean; colors: ReturnType<typeof useColors> }) {
  const [open, setOpen] = useState(false);
  const [text, setText] = useState("");
  const [result, setResult] = useState("");
  const [preferences, setPreferences] = useState<LanguagePreferences>(() => defaultLanguagePreferences());
  const mutation = trpc.translation.text.useMutation();
  const translateAsync = mutation.mutateAsync;

  useEffect(() => {
    void loadLanguagePreferences().then(setPreferences);
  }, []);

  useEffect(() => {
    const value = text.trim();
    if (!open || !value) {
      setResult("");
      return;
    }
    const timer = setTimeout(() => {
      void translateAsync({
        text: value,
        sourceLanguage: preferences.sourceLanguage,
        targetLanguage: preferences.targetLanguage,
      }).then((response) => setResult(response.translatedText)).catch(() => setResult("تعذر إتمام الترجمة حالياً."));
    }, 650);
    return () => clearTimeout(timer);
  }, [open, preferences.sourceLanguage, preferences.targetLanguage, text, translateAsync]);

  if (!visible) return null;

  return (
    <>
      <Pressable accessibilityRole="button" accessibilityLabel="فتح فقاعة الترجمة" onPress={() => setOpen(true)} style={({ pressed }) => [styles.floatingBubble, { backgroundColor: colors.primary }, pressed && styles.pressed]}>
        <Text style={styles.floatingBubbleText}>文</Text>
      </Pressable>
      <Modal visible={open} animationType="slide" transparent onRequestClose={() => setOpen(false)}>
        <View style={styles.modalBackdrop}>
          <View style={[styles.bubbleSheet, { backgroundColor: colors.surface, borderColor: colors.primary }]}>
            <View style={styles.sheetHeader}>
              <Text style={[styles.sheetTitle, { color: colors.foreground }]}>ترجمة سريعة</Text>
              <Pressable accessibilityRole="button" accessibilityLabel="إغلاق فقاعة الترجمة" onPress={() => setOpen(false)} style={styles.sheetClose}><Text style={[styles.sheetCloseText, { color: colors.muted }]}>×</Text></Pressable>
            </View>
            <Text style={[styles.sheetHint, { color: colors.muted }]}>انسخ النص من أي منصة، ألصقه هنا، وستظهر الترجمة تلقائياً.</Text>
            <TextInput value={text} onChangeText={setText} multiline placeholder="ألصق النص هنا…" placeholderTextColor={colors.muted} textAlign="right" style={[styles.sheetInput, { color: colors.foreground, borderColor: colors.border, backgroundColor: "#111D33" }]} />
            <View style={[styles.sheetResult, { borderColor: colors.border }]}><Text style={[styles.resultLabel, { color: colors.muted }]}>النتيجة</Text><Text style={[styles.resultText, { color: colors.foreground }]}>{result || "ستظهر هنا تلقائياً"}</Text></View>
            <Pressable accessibilityRole="button" accessibilityLabel="مشاركة الترجمة" disabled={!result} onPress={() => void Share.share({ message: result })} style={({ pressed }) => [styles.shareButton, { backgroundColor: result ? colors.primary : colors.border }, pressed && styles.pressed]}><Text style={styles.shareButtonText}>مشاركة الترجمة</Text></Pressable>
          </View>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  scrollContent: {
    paddingBottom: 36,
  },
  page: {
    flex: 1,
    paddingHorizontal: 18,
    paddingTop: 20,
  },
  hero: {
    alignItems: "center",
    paddingTop: 8,
    paddingBottom: 22,
  },
  logoHalo: {
    width: 126,
    height: 126,
    borderRadius: 63,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#102A4D",
    borderWidth: 1,
    borderColor: "#2E7CD9",
    shadowColor: "#27C7FF",
    shadowOpacity: 0.3,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 8 },
    elevation: 8,
    overflow: "hidden",
    marginBottom: 14,
  },
  heroImage: {
    width: 124,
    height: 124,
    borderRadius: 62,
  },
  brand: {
    fontSize: 31,
    lineHeight: 42,
    fontWeight: "800",
    letterSpacing: 0.3,
  },
  tagline: {
    fontSize: 16,
    lineHeight: 24,
    marginTop: 2,
  },
  bubbleRow: {
    minHeight: 72,
    borderWidth: 1,
    borderRadius: 38,
    paddingHorizontal: 18,
    marginBottom: 24,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "#111D33",
  },
  bubbleLabelRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  bubbleGlyph: {
    fontSize: 22,
    letterSpacing: -3,
  },
  bubbleLabel: {
    fontSize: 18,
    lineHeight: 25,
    fontWeight: "700",
  },
  bubbleNotice: {
    fontSize: 12,
    lineHeight: 19,
    textAlign: "right",
    marginTop: -14,
    marginBottom: 18,
    paddingHorizontal: 8,
  },
  grid: {
    gap: 14,
  },
  card: {
    width: "100%",
    minHeight: 110,
    borderWidth: 1,
    borderRadius: 22,
    paddingHorizontal: 20,
    paddingVertical: 18,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    shadowOpacity: 0.18,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
    elevation: 3,
  },
  cardPressed: {
    opacity: 0.72,
    transform: [{ scale: 0.98 }],
  },
  iconBadge: {
    width: 52,
    height: 52,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
  },
  icon: {
    fontSize: 26,
    lineHeight: 30,
    fontWeight: "800",
  },
  cardTitle: {
    textAlign: "right",
    fontSize: 18,
    lineHeight: 24,
    fontWeight: "800",
  },
  cardSubtitle: {
    textAlign: "right",
    fontSize: 12,
    lineHeight: 18,
    marginTop: 2,
  },
  version: {
    textAlign: "center",
    fontSize: 12,
    lineHeight: 18,
    marginTop: 22,
  },
  floatingBubble: { position: "absolute", right: 22, bottom: 24, width: 58, height: 58, borderRadius: 29, alignItems: "center", justifyContent: "center", shadowColor: "#55D6FF", shadowOpacity: 0.35, shadowRadius: 12, shadowOffset: { width: 0, height: 6 }, elevation: 8 },
  floatingBubbleText: { color: "#06111F", fontSize: 25, fontWeight: "900" },
  modalBackdrop: { flex: 1, justifyContent: "flex-end", backgroundColor: "rgba(1, 8, 20, 0.72)" },
  bubbleSheet: { borderTopWidth: 1, borderTopLeftRadius: 26, borderTopRightRadius: 26, padding: 20, gap: 12 },
  sheetHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  sheetTitle: { fontSize: 21, lineHeight: 28, fontWeight: "800" },
  sheetClose: { width: 36, height: 36, borderRadius: 18, alignItems: "center", justifyContent: "center", backgroundColor: "#14233A" },
  sheetCloseText: { fontSize: 28, lineHeight: 30 },
  sheetHint: { fontSize: 13, lineHeight: 20, textAlign: "right" },
  sheetInput: { minHeight: 110, borderWidth: 1, borderRadius: 16, padding: 14, fontSize: 15, lineHeight: 23, textAlignVertical: "top" },
  sheetResult: { minHeight: 84, borderWidth: 1, borderRadius: 16, padding: 14, gap: 6 },
  resultLabel: { fontSize: 12, lineHeight: 18, fontWeight: "700" },
  resultText: { fontSize: 16, lineHeight: 24, fontWeight: "700" },
  shareButton: { minHeight: 48, borderRadius: 16, alignItems: "center", justifyContent: "center" },
  shareButtonText: { color: "#06111F", fontSize: 14, fontWeight: "800" },
  pressed: {
    opacity: 0.86,
  },
});
