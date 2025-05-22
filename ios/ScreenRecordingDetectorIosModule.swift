import ExpoModulesCore
import UIKit

extension UIApplication {
  /// iOS13+ でも keyWindow の代わりにアクティブな window を安全に取得
  var activeWindow: UIWindow? {
    return connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}

public class ScreenRecordingDetectorIosModule: Module {
  
  // MARK: - プロパティ
  private var obfuscatingView: UIView?
  private var protectionEnabled = false
  private var secureField: UITextField?
  
  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    Events("onScreenRecordingChanged", "onScreenshotTaken")
    
    OnCreate {
      let initialCaptured = UIScreen.main.isCaptured
      self.sendEvent("onScreenRecordingChanged", ["isCaptured": initialCaptured])
      self.scheduleDelayedChecks(initialCaptured: initialCaptured, attempts: 3, interval: 5.0)
    }
    
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
    
    // MARK: - 公開メソッド
    Function("getCapturedStatus") { () -> Bool in
      UIScreen.main.isCaptured
    }
    
    Function("setProtectionEnabled") { (enabled: Bool) in
      self.protectionEnabled = enabled
      if !enabled {
        self.removeObfuscatingView()
      }
    }
    
    // MARK: - Secure TextField Hack
    Function("enableSecureView") { () -> Void in
      guard let window = UIApplication.shared.activeWindow else { return }
      DispatchQueue.main.async {
        let tf = UITextField(frame: window.bounds)
        tf.isSecureTextEntry = true
        tf.backgroundColor = .clear
        tf.isUserInteractionEnabled = false
        window.addSubview(tf)
        self.secureField = tf
      }
    }
    
    Function("disableSecureView") { () -> Void in
      DispatchQueue.main.async {
        self.secureField?.removeFromSuperview()
        self.secureField = nil
      }
    }
  }
  
  // MARK: - 遅延チェック
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
  
  // MARK: - オーバーレイ
  private func handleAppWillResignActiveIfNeeded() {
    guard protectionEnabled, let window = UIApplication.shared.activeWindow else { return }
    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = .black
    overlay.alpha = 1.0
    overlay.tag = 9999
    DispatchQueue.main.async {
      window.addSubview(overlay)
      self.obfuscatingView = overlay
    }
  }
  
  private func handleAppDidBecomeActiveIfNeeded() {
    guard let overlay = obfuscatingView else { return }
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.3, animations: {
        overlay.alpha = 0
      }) { _ in
        overlay.removeFromSuperview()
        self.obfuscatingView = nil
      }
    }
  }
  
  private func handleScreenshotIfNeeded() {
    guard protectionEnabled, let window = UIApplication.shared.activeWindow else { return }
    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = .black
    overlay.alpha = 1.0
    overlay.tag = 9999
    DispatchQueue.main.async {
      window.addSubview(overlay)
      self.obfuscatingView = overlay
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.handleAppDidBecomeActiveIfNeeded()
      }
    }
  }
  
  private func removeObfuscatingView() {
    if let overlay = obfuscatingView {
      DispatchQueue.main.async {
        overlay.removeFromSuperview()
        self.obfuscatingView = nil
      }
    }
  }
}