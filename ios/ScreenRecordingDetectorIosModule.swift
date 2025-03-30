import ExpoModulesCore
import UIKit

public class ScreenRecordingDetectorIosModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    // JS側で利用可能なイベント名を定義
    Events("onScreenRecordingChanged", "onScreenshotTaken")
    
    // OnCreate で初回状態を送信し、3秒後に再チェックする
    OnCreate {
      let initialCaptured = UIScreen.main.isCaptured
      print("[ScreenRecordingDetectorIosModule] OnCreate: isCaptured = \(initialCaptured)")
      self.sendEvent("onScreenRecordingChanged", ["isCaptured": initialCaptured])
      
      // 遅延チェック（例: 3秒後）
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        let delayedCaptured = UIScreen.main.isCaptured
        print("[ScreenRecordingDetectorIosModule] Delayed OnCreate check: isCaptured = \(delayedCaptured)")
        if delayedCaptured != initialCaptured {
          self.sendEvent("onScreenRecordingChanged", ["isCaptured": delayedCaptured])
        }
      }
    }
    
    OnStartObserving {
      print("[ScreenRecordingDetectorIosModule] OnStartObserving called!")
      
      // 画面録画（またはミラーリング）の変化を検知
      NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let currentCaptured = UIScreen.main.isCaptured
        print("[ScreenRecordingDetectorIosModule] capturedDidChangeNotification fired. isCaptured = \(currentCaptured)")
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": currentCaptured])
      }
      
      // スクリーンショットの検知
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        print("[ScreenRecordingDetectorIosModule] userDidTakeScreenshotNotification fired.")
        self.sendEvent("onScreenshotTaken", [:])
      }
      
      // アプリがフォアグラウンドに復帰したときに、現在の状態を再チェック
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let activeCaptured = UIScreen.main.isCaptured
        print("[ScreenRecordingDetectorIosModule] didBecomeActiveNotification fired. isCaptured = \(activeCaptured)")
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": activeCaptured])
      }
    }
    
    OnStopObserving {
      print("[ScreenRecordingDetectorIosModule] OnStopObserving called!")
      NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
      NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
      NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
  }
}
