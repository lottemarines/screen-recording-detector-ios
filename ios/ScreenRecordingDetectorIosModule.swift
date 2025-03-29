import ExpoModulesCore
import UIKit

public class ScreenRecordingDetectorIosModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    Events("onScreenRecordingChanged", "onScreenshotTaken")
    
    OnCreate {
      // アプリ起動時に一度現在の録画状態をチェックして送信する
      let isCaptured = UIScreen.main.isCaptured
      print("[ScreenRecordingDetectorIosModule] OnCreate: isCaptured = \(isCaptured)")
      self.sendEvent("onScreenRecordingChanged", ["isCaptured": isCaptured])
    }
    
    OnStartObserving {
      print("[ScreenRecordingDetectorIosModule] OnStartObserving called!")
      
      // 画面録画（またはミラーリング）の検知
      NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let isCaptured = UIScreen.main.isCaptured
        print("[ScreenRecordingDetectorIosModule] UIScreen.capturedDidChangeNotification fired. isCaptured = \(isCaptured)")
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": isCaptured])
      }
      
      // スクリーンショット検知
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        print("[ScreenRecordingDetectorIosModule] UIApplication.userDidTakeScreenshotNotification fired.")
        self.sendEvent("onScreenshotTaken", [:])
      }
      
      // アプリがフォアグラウンドに復帰したときに状態を再チェックする
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let isCaptured = UIScreen.main.isCaptured
        print("[ScreenRecordingDetectorIosModule] didBecomeActiveNotification fired. isCaptured = \(isCaptured)")
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": isCaptured])
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
