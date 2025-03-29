export type ScreenRecordingDetectorIosEvents = {
  onScreenRecordingChanged: (payload: { isCaptured: boolean }) => void;
  onScreenshotTaken: () => void;
};

export interface ScreenRecordingDetectorIosViewProps {
  url: string;
  onLoad: (event: { nativeEvent: { url: string } }) => void;
}
