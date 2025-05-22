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

// 画像にぼかし効果を適用するための拡張
extension UIImage {
  func applyLightEffect() -> UIImage? {
    return self.applyBlur(radius: 30, tintColor: UIColor(white: 1.0, alpha: 0.3), saturationDeltaFactor: 1.8)
  }
  
  // 以下は Apple の UIImage+ImageEffects 実装をコピペ
  func applyBlur(radius blurRadius: CGFloat, tintColor: UIColor?, saturationDeltaFactor: CGFloat) -> UIImage? {
    guard let cgImage = self.cgImage else { return nil }
    let imageRect = CGRect(origin: .zero, size: size)
    var effectImage = self
    
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }
    
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    context.scaleBy(x: 1.0, y: -1.0)
    context.translateBy(x: 0, y: -size.height)
    context.draw(cgImage, in: imageRect)
    
    if let tintColor = tintColor {
      context.setFillColor(tintColor.cgColor)
      context.fill(imageRect)
    }
    
    if blurRadius > 0 {
      let inputImage = CIImage(image: effectImage)
      let filter = CIFilter(name: "CIGaussianBlur")
      filter?.setValue(inputImage, forKey: kCIInputImageKey)
      filter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
      if let outputImage = filter?.outputImage {
        effectImage = UIImage(ciImage: outputImage)
        effectImage.draw(in: imageRect)
      }
    }
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

public class ScreenRecordingDetectorIosModule: Module {
  private var obfuscatingView: UIImageView?
  private var protectionEnabled = false
  private var secureField: UITextField?

  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    Events("onScreenRecordingChanged", "onScreenshotTaken")

    OnCreate {
      let initial = UIScreen.main.isCaptured
      self.sendEvent("onScreenRecordingChanged", ["isCaptured": initial])
      self.scheduleDelayedChecks(initialCaptured: initial, attempts: 3, interval: 5.0)
    }

    OnStartObserving {
      NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil, queue: .main) { [weak self] _ in
          guard let self = self else { return }
          let current = UIScreen.main.isCaptured
          self.sendEvent("onScreenRecordingChanged", ["isCaptured": current])
      }
      NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil, queue: .main) { [weak self] _ in
          guard let self = self else { return }
          self.sendEvent("onScreenshotTaken", [:])
          self.handleScreenshotBlur()
      }
      NotificationCenter.default.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil, queue: .main) { [weak self] _ in
          guard let self = self else { return }
          self.handleAppResignBlur()
      }
      NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil, queue: .main) { [weak self] _ in
          guard let self = self else { return }
          self.removeBlur()
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
      if !enabled { self.removeBlur() }
    }
    Function("enableSecureView") { () in
      guard let window = UIApplication.shared.activeWindow else { return }
      DispatchQueue.main.async {
        let tf = UITextField(frame: window.bounds)
        tf.isSecureTextEntry = true
        tf.backgroundColor = .black
        tf.isUserInteractionEnabled = false
        window.addSubview(tf)
        self.secureField = tf
      }
    }
    Function("disableSecureView") { () in
      DispatchQueue.main.async {
        self.secureField?.removeFromSuperview()
        self.secureField = nil
      }
    }
  }

  private func scheduleDelayedChecks(initialCaptured: Bool, attempts: Int, interval: TimeInterval) {
    guard attempts > 0 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now()+interval) {
      let current = UIScreen.main.isCaptured
      if current != initialCaptured {
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": current])
      }
      self.scheduleDelayedChecks(initialCaptured: initialCaptured, attempts: attempts-1, interval: interval)
    }
  }

  private func handleAppResignBlur() {
    guard protectionEnabled, let window = UIApplication.shared.activeWindow else { return }
    UIGraphicsBeginImageContext(window.bounds.size)
    window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
    let snapshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    guard let image = snapshot?.applyLightEffect() else { return }
    let iv = UIImageView(frame: window.bounds)
    iv.image = image
    iv.tag = 8888
    window.addSubview(iv)
    obfuscatingView = iv
  }

  private func handleScreenshotBlur() {
    guard protectionEnabled, let window = UIApplication.shared.activeWindow else { return }
    // 同様にぼかし
    handleAppResignBlur()
    // 数秒後に解除
    DispatchQueue.main.asyncAfter(deadline: .now()+2.0) {
      self.removeBlur()
    }
  }

  private func removeBlur() {
    DispatchQueue.main.async {
      if let iv = self.obfuscatingView { iv.removeFromSuperview(); self.obfuscatingView = nil }
    }
  }
}
