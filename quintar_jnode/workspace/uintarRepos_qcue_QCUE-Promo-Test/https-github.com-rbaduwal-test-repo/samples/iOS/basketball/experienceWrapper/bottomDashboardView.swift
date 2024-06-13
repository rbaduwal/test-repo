import UIKit
import Q_ui

public class bottomDashboardView: UIView {
   @IBInspectable public var centerButtonColor: UIColor?
   @IBInspectable public var centerButtonHeight: CGFloat = 75.0
   @IBInspectable public var padding: CGFloat = 2.0
   @IBInspectable public var centerButton: UIButton?
   @IBInspectable public var viewTabColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
   weak var bottomControlPanel: bottomControlPanel?
   
   // Event for when the button is pressed
   public var buttonPressed: (()-> ()) = {}
   
   public var viewModel: basketballViewModel? {
      didSet {
         self.bottomControlPanel?.viewModel = viewModel
      }
   }
   
   private var shapeLayer: CALayer?
   private let topOffset: CGFloat = 20
   private var animation = CABasicAnimation()
   
   // Programatically load any custom child NIBs here. Do NOT load custom child NIBs implicitely by defining them inside a
   // parent NIB. Loading custom child views that are defined in code-only is fine. Loading custom views as nested NIBs is
   // "swimming against the current" and can have issues loading (especially if nested in framework or swift package):
   //    https://stackoverflow.com/questions/73116846/does-ios-support-nested-custom-subviews-created-with-independent-xib-files
   public override func awakeFromNib() {
         
      // bottomControlPanel
      if let nib = UINib.fromSdkBundle( "bottomControlPanel" ),
         let subview = nib.instantiate(withOwner: nil, options: nil).first as? bottomControlPanel {

         // Programatically set the constraints
         self.addSubview( subview )
         subview.frame = bounds
         subview.contentMode = .scaleToFill
         subview.backgroundColor = UIColor(white: 0, alpha: 0)
         subview.translatesAutoresizingMaskIntoConstraints = false
         let topConstraint = NSLayoutConstraint( item: subview,
            attribute:  .top,
            relatedBy:  .equal,
            toItem:     self,
            attribute:  .top,
            multiplier: 1,
            constant:   3 )
         let leadingConstraint = NSLayoutConstraint( item: subview,
            attribute:  .leading,
            relatedBy:  .equal,
            toItem:     self,
            attribute:  .leading,
            multiplier: 1,
            constant:   0 )
         let bottomConstraint = NSLayoutConstraint( item: self,
            attribute:  .bottom,
            relatedBy:  .equal,
            toItem:     subview,
            attribute:  .bottom,
            multiplier: 1,
            constant:   0 )
         let trailingConstraint = NSLayoutConstraint( item: self,
            attribute:  .trailing,
            relatedBy:  .equal,
            toItem:     subview,
            attribute:  .trailing,
            multiplier: 1,
            constant:   0 )
         self.addConstraints([topConstraint, leadingConstraint, bottomConstraint, trailingConstraint])
         self.bottomControlPanel = subview
      }
   }
   
   public override func draw(_ rect: CGRect) {
      self.addShape()
   }
   public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
      guard  !clipsToBounds && !isHidden && alpha > 0 else {
         return nil
      }
      for member in subviews.reversed() {
         let subPoint = member.convert(point, from: self)
         guard let result = member.hitTest(subPoint, with: event) else {continue}
         return result
      }
      return nil
   }
   public func setupMiddleButton() {
      if self.centerButton == nil {
         self.centerButton = UIButton(frame: CGRect(x: (self.bounds.width / 2)-(centerButtonHeight/2), y: -35 + topOffset, width: centerButtonHeight, height: centerButtonHeight))
         self.centerButton?.layer.cornerRadius = (centerButton?.frame.size.width)! / 2.0
         self.centerButton?.setBackgroundImage(UIImage(named: "BallOutline"),for: .normal)
         self.centerButton?.backgroundColor =  self.centerButtonColor
         self.centerButton?.tintColor = UIColor.white
         
         self.addSubview( self.centerButton!)
         self.centerButton?.addTarget(self, action: #selector(self.connectButtonAction), for: .touchUpInside)
      }
   }
   
   private func createPath() -> CGPath {
      let f = CGFloat(centerButtonHeight / 2.0) + padding
      let h = frame.height+2
      let w = frame.width+2
      let halfW = frame.width/2.0
      let r = CGFloat(8)
      let path = UIBezierPath()
      
      path.move(to: CGPoint(x: 0, y: topOffset))
      
      path.addLine(to: CGPoint(x: halfW-f-(r/2.0), y: topOffset))
      
      path.addQuadCurve(to: CGPoint(x: halfW-f, y: (r/2.0) + topOffset), controlPoint: CGPoint(x: halfW-f, y: topOffset))
      
      path.addArc(withCenter: CGPoint(x: halfW, y: (r/2.0) + topOffset), radius: f, startAngle: .pi, endAngle: 0, clockwise: false)
      
      path.addQuadCurve(to: CGPoint(x: halfW+f+(r/2.0), y: topOffset), controlPoint: CGPoint(x: halfW+f, y: topOffset))
      
      path.addLine(to: CGPoint(x: w, y: topOffset))
      path.addLine(to: CGPoint(x: w, y: h))
      path.addLine(to: CGPoint(x: 0.0, y: h))
      
      return path.cgPath
   }
   private func addShape() {
      let shapeLayer = CAShapeLayer()
      shapeLayer.path = createPath()
      shapeLayer.strokeColor = UIColor.white.cgColor
      shapeLayer.fillColor = viewTabColor.cgColor
      shapeLayer.lineWidth = 1
      
      if let oldShapeLayer = self.shapeLayer {
         self.layer.replaceSublayer(oldShapeLayer, with: shapeLayer)
      } else {
         self.layer.insertSublayer(shapeLayer, at: 0)
      }
      self.shapeLayer = shapeLayer
      self.tintColor = centerButtonColor
      self.setupMiddleButton()
   }
   @objc private func connectButtonAction(sender: UIButton) {
      self.buttonPressed()
   }
   public func beginAnimate() {
      animation = CABasicAnimation(keyPath: "opacity")
      animation.fromValue = 0
      animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      animation.toValue = 1
      animation.repeatCount = .infinity
      animation.autoreverses = true
      animation.duration = 0.5
      self.centerButton?.layer.add(animation, forKey: "StartBasketballAnimation")
   }
   public func endAnimate( _ success: Bool ) {
      self.centerButton?.layer.removeAnimation(forKey: "StartBasketballAnimation")
      animation = CABasicAnimation(keyPath: "opacity")
      animation.toValue = 1
      animation.duration = 0.5
      animation.isRemovedOnCompletion = false
      self.centerButton?.layer.add(animation, forKey: "FinishBasketballAnimation")
      if success {
         self.centerButton?.setBackgroundImage(UIImage(named: "BallFullImg"),for: .normal)
      } else {
         self.centerButton?.setBackgroundImage(UIImage(named: "BallOutline"),for: .normal)
      }
   }
}
