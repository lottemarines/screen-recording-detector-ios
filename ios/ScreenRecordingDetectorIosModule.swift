import ExpoModulesCore
import UIKit

public class ScreenRecordingDetectorIosModule: Module {
  
  private var obfuscatingView: UIView?
  private var protectionEnabled = false
  
  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    Events("onScreenRecordingChanged", "onScreenshotTaken")
    
    // デフォルトで初回のキャプチャ状態を通知
    OnCreate {
      let initialCaptured = UIScreen.main.isCaptured
      self.sendEvent("onScreenRecordingChanged", ["isCaptured": initialCaptured])
      self.scheduleDelayedChecks(initialCaptured: initialCaptured, attempts: 3, interval: 5.0)
    }
    
    // リスナー開始時に通知登録
    OnStartObserving {
      NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        let current = UIScreen.main.isCaptured
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": current])
      }
      
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        self.sendEvent("onScreenshotTaken", [:])
        self.handleScreenshotIfNeeded()
      }
      
      NotificationCenter.default.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        self.handleAppWillResignActiveIfNeeded()
      }
      
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self = self else { return }
        self.handleAppDidBecomeActiveIfNeeded()
        let current = UIScreen.main.isCaptured
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": current])
      }
    }
    
    OnStopObserving {
      NotificationCenter.default.removeObserver(self)
    }
    
    Function("getCapturedStatus") { () -> Bool in
      UIScreen.main.isCaptured
    }
    
    Function("setProtectionEnabled") { (enabled: Bool) in
      self.protectionEnabled = enabled
      if !enabled {
        self.removeObfuscatingView()
      }
    }
  }
  
  private func scheduleDelayedChecks(initialCaptured: Bool, attempts: Int, interval: TimeInterval) {
    guard attempts > 0 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
      let current = UIScreen.main.isCaptured
      if current != initialCaptured {
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": current])
      }
      self.scheduleDelayedChecks(initialCaptured: initialCaptured, attempts: attempts - 1, interval: interval)
    }
  }
  
  private func handleAppWillResignActiveIfNeeded() {
    guard protectionEnabled else { return }
    guard let window = UIApplication.shared.keyWindow else { return }
    
    // バックグラウンド遷移時にスクリーンを黒塗り
    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = UIColor.black
    overlay.alpha = 1.0
    overlay.tag = 9999
    window.addSubview(overlay)
    obfuscatingView = overlay
  }
  
  private func handleAppDidBecomeActiveIfNeeded() {
    // アクティブ復帰時に黒塗りをフェードアウトで削除
    guard let overlay = obfuscatingView else { return }
    UIView.animate(withDuration: 0.3, animations: {
      overlay.alpha = 0
    }) { _ in
      overlay.removeFromSuperview()
      self.obfuscatingView = nil
    }
  }
  
  private func handleScreenshotIfNeeded() {
    guard protectionEnabled else { return }
    guard let window = UIApplication.shared.keyWindow else { return }
    
    // スクショ後すぐに黒塗りオーバーレイ
    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = UIColor.black
    overlay.alpha = 1.0
    overlay.tag = 9999
    window.addSubview(overlay)
    obfuscatingView = overlay
    
    // 数秒後に解除
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.handleAppDidBecomeActiveIfNeeded()
    }
  }
  
  private func removeObfuscatingView() {
    if let overlay = obfuscatingView {
      overlay.removeFromSuperview()
      obfuscatingView = nil
    }
  }
}
