import ScreenRecordingDetectorIosModule from "./src/ScreenRecordingDetectorIosModule";

export function addScreenRecordingListener(
  callback: (isCaptured: boolean) => void
) {
  return ScreenRecordingDetectorIosModule.addListener(
    "onScreenRecordingChanged",
    (payload: { isCaptured: boolean }) => {
      callback(payload.isCaptured);
    }
  );
}

export function addScreenshotListener(callback: () => void) {
  return ScreenRecordingDetectorIosModule.addListener(
    "onScreenshotTaken",
    () => {
      callback();
    }
  );
}

export async function getCapturedStatus(): Promise<boolean> {
  return await ScreenRecordingDetectorIosModule.getCapturedStatus();
}

export function setProtectionEnabled(enabled: boolean): void {
  ScreenRecordingDetectorIosModule.setProtectionEnabled(enabled);
}

export { default as ScreenRecordingDetectorIosModule } from "./src/ScreenRecordingDetectorIosModule";
