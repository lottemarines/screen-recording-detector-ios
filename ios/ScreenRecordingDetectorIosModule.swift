import ExpoModulesCore
import UIKit
import AudioToolbox  // AudioToolbox をインポート

public class ScreenRecordingDetectorIosModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    Events("onScreenRecordingChanged", "onScreenshotTaken")
    
    // アプリ起動時に初期状態を送信
    OnCreate {
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
        if isCaptured {
          self.playAlertSound()  // 録画状態ならアラート音を再生
        }
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
        self.playAlertSound()  // スクリーンショット時もアラート音を再生
        self.sendEvent("onScreenshotTaken", [:])
      }
      
      // アプリがフォアグラウンドに復帰したときに状態を再チェック
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let isCaptured = UIScreen.main.isCaptured
        print("[ScreenRecordingDetectorIosModule] didBecomeActiveNotification fired. isCaptured = \(isCaptured)")
        if isCaptured {
          self.playAlertSound()
        }
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

extension ScreenRecordingDetectorIosModule {
  /// システムサウンドを再生するヘルパー（アラート的な音声）
  func playAlertSound() {
    // ここではシステムサウンドID 1007（一般的な警告音の一例）を使用
    AudioServicesPlaySystemSound(1007)
  }
}
