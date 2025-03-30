import ExpoModulesCore
import UIKit

public class ScreenRecordingDetectorIosModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    // JS側で利用可能なイベント名を定義
    Events("onScreenRecordingChanged", "onScreenshotTaken")
    
    // アプリ起動時に初回の録画状態を送信し、遅延チェックをスケジュールする
    OnCreate {
      let initialCaptured = UIScreen.main.isCaptured
      print("[ScreenRecordingDetectorIosModule] OnCreate: initial isCaptured = \(initialCaptured)")
      self.sendEvent("onScreenRecordingChanged", ["isCaptured": initialCaptured])
      
      // 例えば、5秒ごとに3回の遅延チェックを実施
      self.scheduleDelayedChecks(initialCaptured: initialCaptured, attempts: 3, interval: 5.0)
    }
    
    OnStartObserving {
      print("[ScreenRecordingDetectorIosModule] OnStartObserving called!")
      
      // 画面録画（またはミラーリング）の状態変化を検知
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
      
      // スクリーンショット検知
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        print("[ScreenRecordingDetectorIosModule] userDidTakeScreenshotNotification fired.")
        self.sendEvent("onScreenshotTaken", [:])
      }
      
      // アプリがフォアグラウンドに復帰したときに状態を再チェックする
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
  
  /// 遅延チェックを繰り返すヘルパー
  func scheduleDelayedChecks(initialCaptured: Bool, attempts: Int, interval: TimeInterval) {
    guard attempts > 0 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
      let currentCaptured = UIScreen.main.isCaptured
      print("[ScreenRecordingDetectorIosModule] Delayed check: isCaptured = \(currentCaptured)")
      if currentCaptured != initialCaptured {
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": currentCaptured])
      }
      // 次回のチェックをスケジュール
      self.scheduleDelayedChecks(initialCaptured: initialCaptured, attempts: attempts - 1, interval: interval)
    }
  }
}
