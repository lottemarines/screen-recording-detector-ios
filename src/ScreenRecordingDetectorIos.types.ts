// modules/screen-recording-detector-ios/src/ScreenRecordingDetectorIos.types.ts

/**
 * イベント名と、そのイベントで受け取る関数のシグネチャを定義します。
 * 例:
 *   onScreenRecordingChanged → (payload: { isCaptured: boolean }) => void
 *   onScreenshotTaken        → () => void
 */
export type ScreenRecordingDetectorIosEvents = {
  onScreenRecordingChanged: (payload: { isCaptured: boolean }) => void;
  onScreenshotTaken: () => void;
};

/**
 * Viewコンポーネント用のProps定義（必要な場合のみ）
 */
export interface ScreenRecordingDetectorIosViewProps {
  url: string;
  onLoad: (event: { nativeEvent: { url: string } }) => void;
}
