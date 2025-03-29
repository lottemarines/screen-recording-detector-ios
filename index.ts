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

export { default as ScreenRecordingDetectorIosModule } from "./src/ScreenRecordingDetectorIosModule";
