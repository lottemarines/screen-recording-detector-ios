import { EventEmitter, requireNativeModule } from "expo-modules-core";
import { ScreenRecordingDetectorIosEvents } from "./ScreenRecordingDetectorIos.types";

declare class ScreenRecordingDetectorIosModule extends EventEmitter<ScreenRecordingDetectorIosEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

export default requireNativeModule<ScreenRecordingDetectorIosModule>(
  "ScreenRecordingDetectorIos"
);
