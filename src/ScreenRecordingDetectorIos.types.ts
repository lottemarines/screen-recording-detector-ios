import { EventEmitter } from "expo-modules-core";

/**
 * ネイティブモジュールから発行されるイベントの型定義
 */
export type ScreenRecordingDetectorIosEvents = {
  /**
   * 画面録画状態が変化したときに送信されるイベント
   * payload には { isCaptured: boolean } が含まれる
   */
  onScreenRecordingChanged: (payload: { isCaptured: boolean }) => void;
  /**
   * スクリーンショットが撮られたときに送信されるイベント
   */
  onScreenshotTaken: () => void;
};

/**
 * ScreenRecordingDetectorIosModuleInterface は、Expo Modules API を利用した
 * ネイティブモジュールのインターフェースです。
 * このインターフェースは、EventEmitter クラスのインスタンス型を利用しており、
 * getCapturedStatus() メソッドを追加しています。
 */
export interface ScreenRecordingDetectorIosModuleInterface
  extends InstanceType<typeof EventEmitter> {
  /**
   * 現在の録画状態を取得するメソッド
   * @returns Promise<boolean> で現在の UIScreen.main.isCaptured の状態を返します
   */
  getCapturedStatus(): Promise<boolean>;
}

/**
 * （必要に応じて）View コンポーネントのプロパティの型定義
 */
export interface ScreenRecordingDetectorIosViewProps {
  url: string;
  onLoad: (event: { nativeEvent: { url: string } }) => void;
}
