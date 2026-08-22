import { Tabs } from "expo-router";
import { Platform } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { HapticTab } from "@/components/haptic-tab";
import { IconSymbol } from "@/components/ui/icon-symbol";

export default function TabLayout() {
  const insets = useSafeAreaInsets();
  const bottomPadding = Platform.OS === "web" ? 10 : Math.max(insets.bottom, 8);
  const tabBarHeight = 58 + bottomPadding;

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarButton: HapticTab,
        tabBarActiveTintColor: "#55D6FF",
        tabBarInactiveTintColor: "#6E8198",
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: "700",
          lineHeight: 15,
        },
        tabBarStyle: {
          height: tabBarHeight,
          paddingTop: 7,
          paddingBottom: bottomPadding,
          backgroundColor: "#0B132B",
          borderTopColor: "#223754",
          borderTopWidth: 0.5,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "الرئيسية",
          tabBarIcon: ({ color }) => <IconSymbol size={27} name="house.fill" color={color} />,
        }}
      />
    </Tabs>
  );
}
