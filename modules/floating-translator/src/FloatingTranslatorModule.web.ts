import { registerWebModule, NativeModule } from "expo";

import type { FloatingTranslatorModuleEvents, FloatingTranslatorState } from "./FloatingTranslator.types";

class FloatingTranslatorModule extends NativeModule<FloatingTranslatorModuleEvents> {
  private enabled = false;
  private x = 24;
  private y = 180;

  isSupported() {
    return false;
  }

  canDrawOverlays() {
    return false;
  }

  requestOverlayPermission() {
    // Browser pages cannot draw a system overlay. The in-app bubble remains available.
  }

  async start(x = this.x, y = this.y) {
    this.enabled = true;
    this.x = x;
    this.y = y;
    return false;
  }

  stop() {
    this.enabled = false;
  }

  isRunning() {
    return this.enabled;
  }

  setPosition(x: number, y: number) {
    this.x = x;
    this.y = y;
  }

  getState(): FloatingTranslatorState {
    return {
      supported: false,
      permissionGranted: false,
      running: this.enabled,
      x: this.x,
      y: this.y,
    };
  }

  consumeSharedText() {
    return null;
  }
}

export default registerWebModule(FloatingTranslatorModule, "FloatingTranslator");
