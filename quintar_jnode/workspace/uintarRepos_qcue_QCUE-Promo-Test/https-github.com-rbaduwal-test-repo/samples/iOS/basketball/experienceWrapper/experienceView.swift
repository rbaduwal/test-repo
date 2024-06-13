import UIKit
import AVFoundation

public class experienceView: UIView {
   
   @IBOutlet weak var bottomDashboardView: bottomDashboardView!
   @IBOutlet weak var tapBeginView: UIView!
   @IBOutlet weak var tapToBeginButton: UIButton!
   @IBOutlet weak var debugLogLabel: UILabel!
   @IBOutlet weak var exposureControlSlider: UISlider!
   @IBOutlet weak var exposureModeLabel: UILabel!
   
   public var defaultExposureBias: Float? = nil
   public var enableDebugLabel: Bool = false {
      didSet {
         if enableDebugLabel {
            debugLogLabel.isHidden = false
         } else {
            debugLogLabel.isHidden = true
         }
      }
   }
   
   var minIso: Float = 0
   var maxIso: Float = 0
   var captureDevice: AVCaptureDevice?
   
   public override func layoutSubviews() {
      exposureControlSlider.setThumbImage(UIImage(named: "SliderThumbImg"), for: .normal)
      exposureControlSlider.setThumbImage(UIImage(named: "SliderThumbImg"), for: .highlighted)
      captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
      exposureControlSlider.minimumValue = captureDevice?.minExposureTargetBias ?? 0
      exposureControlSlider.maximumValue = captureDevice?.maxExposureTargetBias ?? 0
      exposureControlSlider.value = captureDevice?.exposureTargetBias ?? 0
      debugLogLabel.isHidden = true
   }
   public func updateDebugLabel() {
      if let device = self.captureDevice {
         self.debugLogLabel.text = """
            Bias: \(device.exposureTargetBias)
            ISO: \(device.iso)
            LensAperture: \(device.lensAperture)
            ExposureDurationValue: \(device.exposureDuration.value)
            ExposureDurationTimeScale: \(device.exposureDuration.timescale)
            """
      }
   }
   public func enableAutoExposure(_ enabled: Bool )
   {
      if enabled {
         exposureControlSlider.isHidden = true
         do {
            try captureDevice?.lockForConfiguration()
            captureDevice?.exposureMode = .continuousAutoExposure
            updateExposureBias(to: defaultExposureBias ?? 0)
            captureDevice?.unlockForConfiguration()
         } catch {}
      } else {
         exposureControlSlider.isHidden = false
         exposureControlSlider.setThumbImage(UIImage(named: "SliderThumbImg"), for: .normal)
         exposureControlSlider.setThumbImage(UIImage(named: "SliderThumbImg"), for: .highlighted)
         let maxExposureBias = captureDevice?.maxExposureTargetBias ?? 0
         let minExposureBias = captureDevice?.minExposureTargetBias ?? 0
         exposureControlSlider.minimumValue = minExposureBias
         exposureControlSlider.maximumValue = maxExposureBias
         let defaultBias = defaultExposureBias ?? 0
         if minExposureBias...maxExposureBias ~= defaultBias {
            exposureControlSlider.value = defaultBias
         } else {
            exposureControlSlider.value = captureDevice?.exposureTargetBias ?? 0
         }
         
         updateExposureBias(to: exposureControlSlider.value)
      }
   }

   private func updateExposureBias(to expBias: Float) {
      if let device = captureDevice {
         do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(expBias)
            defaultExposureBias = expBias
            device.unlockForConfiguration()
         } catch {}
      }
   }
   
   @IBAction func onExposureSliderChanged(_ sender: UISlider) {
      updateExposureBias( to: sender.value )
   }
}

public extension UINib {
   static func fromSdkBundle(_ nibName: String) -> UINib? {
   
      // grab the appropriate bundle. If the app uses the QSDK frameworks
      // directly then our resources are in the app's bundle, otherwise
      // they are in the special 'module' bundle.
#if NO_SPM
      let bundle = Bundle.main
      // let bundle = Bundle(for: experienceView.self)
#else
      let bundle = Bundle.module
#endif
      return UINib(nibName: nibName, bundle: bundle)
   }
}
   
// Use this when loading icons and images from the SDK or experience wrapper
public extension UIImage {
   static func fromSdkBundle(named assetName: String) -> UIImage? {
   
      // grab the appropriate bundle. If the app uses the QSDK frameworks
      // directly then our resources are in the app's bundle, otherwise
      // they are in the special 'module' bundle.
#if NO_SPM
      let bundle = Bundle.main
      // let bundle = Bundle(for: experienceView.self)
#else
      let bundle = Bundle.module
#endif
      return UIImage(named: assetName, in: bundle, with: nil)
   }
}
