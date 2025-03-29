import ScreenRecordingDetectorIosModule from "./src/ScreenRecordingDetectorIosModule";
/**
 * 画面録画の開始／停止を検知
 */
export function addScreenRecordingListener(
  callback: (isCaptured: boolean) => void
) {
  // ネイティブモジュール自身の addListener を呼ぶ
  // "onScreenRecordingChanged" イベントのペイロードが { isCaptured: boolean } である想定
  return ScreenRecordingDetectorIosModule.addListener(
    "onScreenRecordingChanged",
    (payload: { isCaptured: boolean }) => {
      callback(payload.isCaptured);
    }
  );
}

/**
 * スクリーンショットを検知
 */
export function addScreenshotListener(callback: () => void) {
  return ScreenRecordingDetectorIosModule.addListener(
    "onScreenshotTaken",
    () => {
      callback();
    }
  );
}

export { default as ScreenRecordingDetectorIosModule } from "./src/ScreenRecordingDetectorIosModule";
