# screen-recording-detector-ios

**screen-recording-detector-ios** は Expo Modules API を使ったカスタムネイティブモジュールです。 iOS 上での画面録画／ミラーリング状態の変化とスクリーンショットイベントを検知し、JavaScript 側に通知します。 さらに、アプリ起動時に遅延チェックを行うことで、バックグラウンドからの再開時にも最新状態を取得できます。

## 主な機能

- **画面録画検知**

  - `UIScreen.capturedDidChangeNotification` を監視して録画／ミラーリング開始・終了を検出
  - アプリがフォアグラウンド復帰 (`didBecomeActiveNotification`) した際にも状態を再チェック
  - 起動直後に遅延チェック（5 秒間隔で合計 3 回）を行い、アプリ終了時の状態をフォローアップ

- **スクリーンショット検知**

  - `UIApplication.userDidTakeScreenshotNotification` を監視してスクリーンショットを検出

- **オーバーレイによる画面保護**

  - `setProtectionEnabled(true)` でバックグラウンド移行時／スクショ検知時に全画面を黒塗りオーバーレイ
  - フラグを `false` に戻すとオーバーレイを削除

## インストール

```bash
yarn add screen-recording-detector-ios
```

## 使い方

```ts
import { useEffect } from "react";
import {
  addScreenRecordingListener,
  addScreenshotListener,
  getCapturedStatus,
  setProtectionEnabled,
} from "screen-recording-detector-ios";

export function useSecureScreen() {
  useEffect(() => {
    // 画面保護（オーバーレイ）を有効化
    setProtectionEnabled(true);

    // 録画検知
    const recSub = addScreenRecordingListener(({ isCaptured }) => {
      console.log("Screen recording state:", isCaptured);
    });

    // スクショ検知
    const shotSub = addScreenshotListener(() => {
      console.log("Screenshot taken.");
    });

    // 初期状態も取得可能
    (async () => {
      const status = await getCapturedStatus();
      console.log("Initial recording status:", status);
    })();

    return () => {
      // 後片付け
      recSub.remove();
      shotSub.remove();
      setProtectionEnabled(false);
    };
  }, []);
}
```

## ネイティブ実装（Swift）概要

- **OnCreate**:

  - アプリ起動時に初期録画状態を通知
  - 遅延チェックをスケジュール

- **OnStartObserving**:

  - `capturedDidChangeNotification` で録画状態の変化を監視
  - `userDidTakeScreenshotNotification` でスクショ検知 & オーバーレイ表示
  - `willResignActiveNotification` でバックグラウンド移行時にオーバーレイ表示
  - `didBecomeActiveNotification` でフォアグラウンド復帰時にオーバーレイ解除 & 状態通知

- **OnStopObserving**:

  - すべての通知監視を解除

- **公開メソッド**:

  - `getCapturedStatus(): Promise<boolean>`
  - `setProtectionEnabled(enabled: boolean): void`

## License

MIT
