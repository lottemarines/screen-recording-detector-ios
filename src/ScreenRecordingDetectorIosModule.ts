import { EventEmitter, requireNativeModule } from "expo-modules-core";
import { ScreenRecordingDetectorIosEvents } from "./ScreenRecordingDetectorIos.types";

/**
 * iOSネイティブ側(@objc(ScreenRecordingDetectorIos) class で RCTEventEmitterを継承)と対応するクラス。
 * "onScreenRecordingChanged" / "onScreenshotTaken" などのイベントを emit できる。
 *
 * ここで extends EventEmitter<ScreenRecordingDetectorIosEvents> として、
 * TypeScript に「このモジュールは特定のイベント名と引数型を持つ EventEmitter」だと認識させます。
 */
declare class ScreenRecordingDetectorIosModule extends EventEmitter<ScreenRecordingDetectorIosEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// "ScreenRecordingDetectorIos" は Swift/Objective-C 側で @objc(ScreenRecordingDetectorIos) と定義したクラス名
export default requireNativeModule<ScreenRecordingDetectorIosModule>(
  "ScreenRecordingDetectorIos"
);
