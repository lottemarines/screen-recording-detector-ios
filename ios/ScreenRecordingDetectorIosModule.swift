import ExpoModulesCore
import UIKit

extension UIApplication {
  /// iOS13+ でも keyWindow の代わりにアクティブな window を安全に取得
  var activeWindow: UIWindow? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}

// UIKit のブラーエフェクトを簡易に適用する拡張
extension UIImage {
  func applyLightEffect() -> UIImage? {
    return applyBlur(radius: 20,
                     tintColor: UIColor(white: 1.0, alpha: 0.3),
                     saturationDeltaFactor: 1.8)
  }
  private func applyBlur(radius blurRadius: CGFloat,
                         tintColor: UIColor?,
                         saturationDeltaFactor: CGFloat) -> UIImage? {
    guard let cgImage = cgImage else { return nil }
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
  private var obfuscatingView: UIImageView?
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
      let nc = NotificationCenter.default
      // 録画状態
      nc.addObserver(forName: UIScreen.capturedDidChangeNotification,
                     object: nil, queue: .main) { [weak self] _ in
        guard let self = self else { return }
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": UIScreen.main.isCaptured])
      }
      // スクリーンショット
      nc.addObserver(forName: UIApplication.userDidTakeScreenshotNotification,
                     object: nil, queue: .main) { [weak self] _ in
        guard let self = self, let window = UIApplication.shared.activeWindow else { return }
        self.sendEvent("onScreenshotTaken", [:])
        // フルスクリーン SecureTextField
        let tf = UITextField(frame: window.bounds)
        tf.isSecureTextEntry = true
        tf.backgroundColor = .black
        tf.isUserInteractionEnabled = false
        window.addSubview(tf)
        self.secureField = tf
        // ブラーオーバーレイ
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let blurred = snapshot?.applyLightEffect() {
          let iv = UIImageView(frame: window.bounds)
          iv.image = blurred
          window.addSubview(iv)
          self.obfuscatingView = iv
        }
        // 2秒後に解除
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          self.secureField?.removeFromSuperview()
          self.secureField = nil
          self.obfuscatingView?.removeFromSuperview()
          self.obfuscatingView = nil
        }
      }
      // バックグラウンド
      nc.addObserver(forName: UIApplication.willResignActiveNotification,
                     object: nil, queue: .main) { [weak self] _ in
        self?.applyBlurOverlay()
      }
      // フォアグラウンド復帰
      nc.addObserver(forName: UIApplication.didBecomeActiveNotification,
                     object: nil, queue: .main) { [weak self] _ in
        self?.removeBlurOverlay()
        self?.sendEvent("onScreenRecordingChanged", ["isCaptured": UIScreen.main.isCaptured])
      }
    }

    OnStopObserving {
      NotificationCenter.default.removeObserver(self)
      self.secureField?.removeFromSuperview()
      self.obfuscatingView?.removeFromSuperview()
    }

    Function("getCapturedStatus") { () -> Bool in
      UIScreen.main.isCaptured
    }
    Function("enableSecureView") { [weak self] in
      guard let window = UIApplication.shared.activeWindow else { return }
      let tf = UITextField(frame: window.bounds)
      tf.isSecureTextEntry = true
      tf.backgroundColor = .black
      tf.isUserInteractionEnabled = false
      window.addSubview(tf)
      self?.secureField = tf
    }
    Function("disableSecureView") { [weak self] in
      self?.secureField?.removeFromSuperview()
      self?.secureField = nil
    }
  }

  private func scheduleDelayedChecks(initialCaptured: Bool,
                                     attempts: Int,
                                     interval: TimeInterval) {
    guard attempts > 0 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
      let current = UIScreen.main.isCaptured
      if current != initialCaptured {
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": current])
      }
      self.scheduleDelayedChecks(initialCaptured: initialCaptured,
                                 attempts: attempts - 1,
                                 interval: interval)
    }
  }

  private func applyBlurOverlay() {
    guard let window = UIApplication.shared.activeWindow else { return }
    DispatchQueue.main.async {
      UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
      let snapshot = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      if let blurred = snapshot?.applyLightEffect() {
        let iv = UIImageView(frame: window.bounds)
        iv.image = blurred
        window.addSubview(iv)
        self.obfuscatingView = iv
      }
    }
  }

  private func removeBlurOverlay() {
    DispatchQueue.main.async {
      self.obfuscatingView?.removeFromSuperview()
      self.obfuscatingView = nil
    }
  }
}
