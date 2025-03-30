import type { EventEmitter } from "expo-modules-core";
import { requireNativeModule } from "expo-modules-core";
import { ScreenRecordingDetectorIosEvents } from "./ScreenRecordingDetectorIos.types";

declare class ScreenRecordingDetectorIosModule extends EventEmitter<ScreenRecordingDetectorIosEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
  getCapturedStatus(): Promise<boolean>;
}

export default requireNativeModule<ScreenRecordingDetectorIosModule>(
  "ScreenRecordingDetectorIos"
);
