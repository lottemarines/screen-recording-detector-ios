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
  /// LightEffect（淡いぼかし）を適用
  func applyLightEffect() -> UIImage? {
    return applyBlur(radius: 20,
                     tintColor: UIColor(white: 1.0, alpha: 0.3),
                     saturationDeltaFactor: 1.8)
  }

  /// Apple サンプルをベースにした GaussianBlur + Saturation
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
  // MARK: - Properties
  private var obfuscatingView: UIImageView?
  private var secureFields: [UITextField] = []

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
      // 画面録画検知
      nc.addObserver(forName: UIScreen.capturedDidChangeNotification,
                     object: nil, queue: .main) { [weak self] _ in
        guard let self = self else { return }
        self.sendEvent("onScreenRecordingChanged", ["isCaptured": UIScreen.main.isCaptured])
      }
      // スクリーンショット検知
      nc.addObserver(forName: UIApplication.userDidTakeScreenshotNotification,
                     object: nil, queue: .main) { [weak self] _ in
        guard let self = self else { return }
        self.sendEvent("onScreenshotTaken", [:])
        // 1. 全サブビューに SecureTextField を貼る
        self.protectViewsWithSecureTextField()
        // 2. ブラーオーバーレイを貼る
        self.applyBlurOverlay()
        // 3. 数秒後に解除
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          self.removeAllSecureTextFields()
          self.removeBlurOverlay()
        }
      }
      // アプリがバックグラウンドへ
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
    }

    // MARK: - Public API
    Function("getCapturedStatus") { () -> Bool in
      UIScreen.main.isCaptured
    }
    Function("setProtectionEnabled") { (_: Bool) in
      // バックグラウンド時のブラー用。不要なら空実装でも可
    }
    Function("enableSecureView") { [weak self] in
      self?.protectViewsWithSecureTextField()
    }
    Function("disableSecureView") { [weak self] in
      self?.removeAllSecureTextFields()
    }
  }

  // MARK: - Private Helpers
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

  /// 全サブビュー再帰的に UITextField.secureTextEntry を貼る
  private func protectViewsWithSecureTextField() {
    guard let window = UIApplication.shared.activeWindow else { return }
    // 直前キャプチャ→ぼかし画像
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
    window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
    let snapshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    let blurred = snapshot?.applyLightEffect()

    func addSecure(to view: UIView) {
      let tf = UITextField(frame: view.bounds)
      tf.isSecureTextEntry = true
      if let bg = blurred {
        tf.backgroundColor = UIColor(patternImage: bg)
      } else {
        tf.backgroundColor = .black
      }
      tf.isUserInteractionEnabled = false
      view.addSubview(tf)
      secureFields.append(tf)
      view.subviews.forEach(addSecure)
    }

    window.subviews.forEach(addSecure)
  }

  /// 貼ったすべての SecureTextField を削除
  private func removeAllSecureTextFields() {
    secureFields.forEach { $0.removeFromSuperview() }
    secureFields.removeAll()
  }

  /// 画面をキャプチャしてブラーオーバーレイを表示
  private func applyBlurOverlay() {
    guard let window = UIApplication.shared.activeWindow else { return }
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
  }

  /// ブラーオーバーレイを削除
  private func removeBlurOverlay() {
    DispatchQueue.main.async {
      self.obfuscatingView?.removeFromSuperview()
      self.obfuscatingView = nil
    }
  }
}
