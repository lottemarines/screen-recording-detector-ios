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

// UIKit のブラーエフェクトを簡易に適用する拡張
extension UIImage {
  /// LightEffect（淡いぼかし）を適用
  func applyLightEffect() -> UIImage? {
    return self.applyBlur(radius: 20, tintColor: UIColor(white: 1.0, alpha: 0.3), saturationDeltaFactor: 1.8)
  }
  
  /// Apple サンプルをベースにした GaussianBlur + Saturation
  private func applyBlur(radius blurRadius: CGFloat, tintColor: UIColor?, saturationDeltaFactor: CGFloat) -> UIImage? {
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

    if blurRadius > 0, let inputImage = CIImage(image: effectImage) {
      let filter = CIFilter(name: "CIGaussianBlur")
      filter?.setValue(inputImage, forKey: kCIInputImageKey)
      filter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
      if let outputImage = filter?.outputImage {
        let cropped = outputImage.cropped(to: inputImage.extent)
        effectImage = UIImage(ciImage: cropped)
        effectImage.draw(in: imageRect)
      }
    }

    return UIGraphicsGetImageFromCurrentImageContext()
  }
}

public class ScreenRecordingDetectorIosModule: Module {
  // MARK: - Properties
  private var obfuscatingView: UIImageView?
  private var protectionEnabled = false
  private var secureField: UITextField?

  public func definition() -> ModuleDefinition {
    Name("ScreenRecordingDetectorIos")
    Events("onScreenRecordingChanged", "onScreenshotTaken")

    // 初回ステータス通知＋遅延チェック
    OnCreate {
      let initial = UIScreen.main.isCaptured
      self.sendEvent("onScreenRecordingChanged", ["isCaptured": initial])
      self.scheduleDelayedChecks(initialCaptured: initial, attempts: 3, interval: 5.0)
    }

    // 通知登録
    OnStartObserving {
      let nc = NotificationCenter.default
      nc.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
        guard let self = self else { return }
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": UIScreen.main.isCaptured])
      }
      nc.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main) { [weak self] _ in
        guard let self = self else { return }
        self.sendEvent("onScreenshotTaken", [:])
        self.applyBlurOverlay()
      }
      nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
        self?.applyBlurOverlay()
      }
      nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
        self?.removeBlurOverlay()
        self?.sendEvent("onScreenRecordingChanged", ["isCaptured": UIScreen.main.isCaptured])
      }
    }

    OnStopObserving {
      NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API
    Function("getCapturedStatus") { () -> Bool in
      UIScreen.main.isCaptured
    }
    Function("setProtectionEnabled") { (enabled: Bool) in
      self.protectionEnabled = enabled
      if !enabled { self.removeBlurOverlay() }
    }
    Function("enableSecureView") {
      // Secure TextField ハック：スクショ撮影時に画面を隠蔽
      guard let window = UIApplication.shared.activeWindow else { return }
      DispatchQueue.main.async {
        let tf = UITextField(frame: window.bounds)
        tf.isSecureTextEntry = true
        tf.backgroundColor = .clear  // 透明のままにして、見た目は変えない
        tf.isUserInteractionEnabled = false
        window.addSubview(tf)
        self.secureField = tf
      }
    }
    Function("disableSecureView") {
      DispatchQueue.main.async {
        self.secureField?.removeFromSuperview()
        self.secureField = nil
      }
    }
  }

  // MARK: - Private Helpers
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

  private func applyBlurOverlay() {
    guard protectionEnabled, let window = UIApplication.shared.activeWindow else { return }
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
    window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
    let snapshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    guard let blurred = snapshot?.applyLightEffect() else { return }
    let iv = UIImageView(frame: window.bounds)
    iv.image = blurred
    iv.tag = 0xB10B
    window.addSubview(iv)
    obfuscatingView = iv
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.removeBlurOverlay()
    }
  }

  private func removeBlurOverlay() {
    DispatchQueue.main.async {
      self.obfuscatingView?.removeFromSuperview()
      self.obfuscatingView = nil
    }
  }
}
