import { NativeModule, requireOptionalNativeModule } from "expo";

import type { FloatingTranslatorModuleEvents, FloatingTranslatorState } from "./FloatingTranslator.types";

declare class FloatingTranslatorModule extends NativeModule<FloatingTranslatorModuleEvents> {
  isSupported(): boolean;
  canDrawOverlays(): boolean;
  requestOverlayPermission(): void;
  start(x?: number, y?: number): Promise<boolean>;
  stop(): void;
  isRunning(): boolean;
  setPosition(x: number, y: number): void;
  getState(): FloatingTranslatorState;
  consumeSharedText(): string | null;
}

export const nativeFloatingTranslator = requireOptionalNativeModule<FloatingTranslatorModule>("FloatingTranslator");
