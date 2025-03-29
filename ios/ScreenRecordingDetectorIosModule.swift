import ExpoModulesCore
import UIKit

public class ScreenRecordingDetectorIosModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    Events("onScreenRecordingChanged", "onScreenshotTaken")
    
    OnStartObserving {
      NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let isCaptured = UIScreen.main.isCaptured
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": isCaptured])
      }
      
      // スクリーンショット検知
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        self.sendEvent("onScreenshotTaken", [:])
      }
      
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let isCaptured = UIScreen.main.isCaptured
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": isCaptured])
      }
    }
    
    OnStopObserving {
      NotificationCenter.default.removeObserver(
        self,
        name: UIScreen.capturedDidChangeNotification,
        object: nil
      )
      NotificationCenter.default.removeObserver(
        self,
        name: UIApplication.userDidTakeScreenshotNotification,
        object: nil
      )
      NotificationCenter.default.removeObserver(
        self,
        name: UIApplication.didBecomeActiveNotification,
        object: nil
      )
    }
  }
}
