import { EventEmitter } from "expo-modules-core";

export type ScreenRecordingDetectorIosEvents = {
  onScreenRecordingChanged: (payload: { isCaptured: boolean }) => void;
  onScreenshotTaken: () => void;
};
export interface ScreenRecordingDetectorIosModuleInterface
  extends InstanceType<typeof EventEmitter> {
  getCapturedStatus(): Promise<boolean>;
  setProtectionEnabled(enabled: boolean): void;
  enableSecureView(): void;
  disableSecureView(): void;
}
