// Interface for using SceneKit or RealityKit.
// Add `REALITY_KIT' to your project settings for RealityKit, otherwise defaults to SceneKit

/// ----------------------------------
/// COMMON TO BOTH
import ARKit

/// ----------------------------------
/// SPECIFIC TO REALITY KIT
#if REALITY_KIT

import RealityKit

public typealias qEntity = RealityKit.Entity
public typealias qModelEntity = RealityKit.ModelEntity
public typealias qRootEntity = RealityKit.AnchorEntity
public typealias qARView = RealityKit.ARView
public typealias qHasModel = RealityKit.HasModel
public typealias qHasCollision = RealityKit.HasCollision
public typealias qMeshResource = RealityKit.MeshResource
public typealias qMeshDescriptor = RealityKit.MeshDescriptor
public typealias qModelComponent = RealityKit.ModelComponent
public typealias qTransform = RealityKit.Transform
public typealias qMaterial = RealityKit.Material
public typealias qUnlitMaterial = RealityKit.UnlitMaterial
public typealias qSimpleMaterial = RealityKit.SimpleMaterial
public typealias qOcclusionMaterial = RealityKit.OcclusionMaterial
public typealias qTextureResource = RealityKit.TextureResource
public typealias qVector3 = SIMD3<Float>
public typealias qVector4 = SIMD4<Float>
public typealias qQuaternion = simd_quatf
public typealias qCollisionComponent = RealityKit.CollisionComponent
public typealias qShapeResource = RealityKit.ShapeResource
public typealias qBoundingBox = RealityKit.BoundingBox
public typealias qPhysicallyBasedMaterial = RealityKit.PhysicallyBasedMaterial
public typealias qEntityGestureRecognizer = EntityGestureRecognizer
public typealias qEntityTranslationGestureRecognizer = EntityTranslationGestureRecognizer
public typealias qEntityScaleGestureRecognizer = EntityScaleGestureRecognizer

public extension qARView {
   func showDebugInfo(show: Bool) {
      if show {
         self.debugOptions = [
            .showStatistics
         ]
      } else {
         self.debugOptions = [
         ]
      }
   }
   
   var cameraTransformMatrix: float4x4 {
      get {
         return self.cameraTransform.matrix
      }
   }
   
   func start(enableMicrophone: Bool) {
      // Begin the AR session, determining whether or not we need microphone access
      let configuration = ARWorldTrackingConfiguration()
      configuration.providesAudioData = enableMicrophone
      self.session.run(configuration)
   }
   func getTappedEntity(tapLocation: CGPoint, maxRange: Float) -> qEntity? {
      guard let rayResult = self.ray(through: tapLocation) else { return nil }
      let results = self.scene.raycast(origin: rayResult.origin,
                                                          direction: rayResult.direction,
                                                          length: maxRange,
                                                          query: .nearest)
      
      if let firstResult = results.first {
         return firstResult.entity
      }
      return nil
   }
   func enableAntialiasing( _ v : Bool ) { /* TODO: RealityKit does not have support for this - antialiasing is automatically enabled */ }
}

public extension qEntity {

   func setBillboardConstraints(arView: qARView, rootEntity: qEntity) {
      updateSubscription = arView?.scene.subscribe(to: SceneEvents.Update.self) {[weak self] _ in
         guard let self = self else{return}
         // TODO: Include billboard logic.
      }
   }
}

public extension qModelEntity {
   func updateMaterials(materials: [qMaterial]) {
      self.model?.materials = materials
   }
   func getMaxBounds() -> qVector3? {
      return self.model?.mesh.bounds.max
   }
   func getMinBounds() -> qVector3? {
      return self.model?.mesh.bounds.min
   }
   func updateChildNodePosition(withName name: String, xPosition: Float, yPosition: Float, zPosition: Float) {
      for child in self.children {
         child.position.x = child.position.x + xPosition
         child.position.y = child.position.y + yPosition
         child.position.z = child.position.z + zPosition
      }
   }
   // RealityKit text positioning is... I don't even know. Strange.
   // This helped:
   //   https://github.com/maxxfrazer/RealityUI/blob/main/Sources/RealityUI/RUIText.swift
   // ... but not completely.
   // The solution is to adjust the position so that x0 and y0 are as expected; however,
   // this may have undesired consequences if the text model has children.
   //
   // 1. Offset by the reported center offset
   // 2. Offset by the descender so that y0 is along the baseline of the text.
   //    The height of text includes both an ascender and descender. You would think that the model extents would
   //    include the bounds of only the text we are drawing, but it turns out the model extents include any text
   //    we could draw (think lower-case 'g'), regardless of whether or not we actually draw those characters.
   func setPositionForText(_ position: SIMD3<Float>, relativeTo: qEntity?, withFont font: UIFont, align: CTTextAlignment = .center ) {
      if let model = self.model {
         let yOffset = getTextCenterYAdjustment(withFont: font)
         switch align {
            case .left:
               self.setPosition(SIMD3<Float>(position.x,
                  yOffset + position.y,
                  position.z),
                  relativeTo: relativeTo)
            default:
               self.setPosition(SIMD3<Float>(-model.mesh.bounds.center.x + position.x,
                  yOffset + position.y,
                  position.z),
                  relativeTo: relativeTo)
         }
      }
   }
   func getTextCenterYAdjustment(withFont font: UIFont) -> Float {
      guard let model = self.model else { return 0 }
      let fontHeight = font.ascender + font.descender
      let descenderPercentage: Float = Float(font.descender / fontHeight)
      let yFontAdjustment = (model.mesh.bounds.extents.y * descenderPercentage) / 2
      return -model.mesh.bounds.center.y + yFontAdjustment
   }
}

public extension qEntity {
   func removeAllChildren() {
      self.children.removeAll()
   }
   func qOrientation(angle:Float ,axis: SIMD3<Float> ) -> simd_quatf{
       return simd_quatf(angle: angle, axis: axis)
   }
   // Use the built-in Entity.ComponentSet to attach any custom object to an entity
   class customComponent_t<T> : Component {
      var object: T
      init( _ o: T ) { object = o }
   }
   var customComponent: Any? {
      get {
         if let component = self.components[ customComponent_t<Any>.self ] {
            return (component as! customComponent_t).object
         } else {
            return nil
         }
      }
      set {
         self.components[ customComponent_t<Any>.self ] = customComponent_t(newValue)
      }
   }
   func setRecursive( withObject: Any )
   {
      self.customComponent = withObject
      for child in self.children {
         child.setRecursive( withObject: withObject)
     }
   }
   func forceName(_ name: String, recursive: Bool = false) {
      self.name = name
      if recursive{
         for child in self.children {
            child.forceName(name, recursive: true)
         }
      }
   }
   func update( mesh: qMeshResource? = nil, materials: [qMaterial]? = nil) {
      if self.components[ModelComponent.self] == nil, let me = mesh, let ma = materials {
         // Insert model components
         self.components.set(ModelComponent(mesh: me, materials: ma))
      }
      else if var modelGuts = self.components[ModelComponent.self] as? ModelComponent, modelGuts.materials.count > 0 {
         if let m = mesh { modelGuts.mesh = m }
         if let m = materials { modelGuts.materials = m }
         self.components.set(modelGuts)
      } else {
         // TODO: error handling here
      }
   }
}

extension qTransform {
   mutating func rotate(quat: simd_quatf) -> qTransform {
      self.rotation = quat
      return self
   }
}

public extension qMeshResource {
   static func generate( triangleVertices: [SIMD3<Float>],
      indices: [UInt32],
      normals: [SIMD3<Float>]? = nil,
      uvs: [SIMD2<Float>]? = nil) -> qMeshResource? {
      
      var meshDescriptor = MeshDescriptor()
      meshDescriptor.positions = .init(triangleVertices)
      meshDescriptor.primitives = .triangles(indices)
      
      if let n = normals {
         meshDescriptor.normals = .init(n)
      }
      if let u = uvs {
         meshDescriptor.textureCoordinates = .init(u)
      }
      
      do {
         return try MeshResource.generate(from: [meshDescriptor])
      } catch {
         return nil
      }
   }
   
   static func generate( hexagonVertices: [SIMD3<Float>],
      indices: [UInt32] ) -> qMeshResource? {
      
      var meshDescriptor = MeshDescriptor(name: "hexagon")
      meshDescriptor.positions = .init(hexagonVertices)
      meshDescriptor.primitives = .polygons([6], indices)
      
      do {
         return try MeshResource.generate(from: [meshDescriptor])
      } catch {
         return nil
      }
   }
}

/// ----------------------------------
/// SPECIFIC TO SCENE KIT
#else

import SceneKit
import Metal
import Metal.MTLDevice
import MetalKit

public typealias qRootEntity = qEntity
public typealias qTransform = SCNMatrix4
public typealias qMaterial = SCNMaterial
public typealias qPhysicallyBasedMaterial = SCNMaterial // TODO: Probably not going to work
public typealias qVector3 = SCNVector3
public typealias qVector4 = SCNVector4
public typealias qMeshResource = SCNGeometry
public typealias qQuaternion = SCNQuaternion
public typealias qSimpleMaterial = qUnlitMaterial

public protocol qHasModel {
   var model: qModelComponent? { get set }
}
public protocol HasTransform : qEntity {
}

public protocol qHasPhysics : qHasPhysicsBody {
}

/// Provides a rigid body which is simulated by the physics simulation.
public protocol qHasPhysicsBody : qHasCollision {
}

extension qVector3: Decodable {
   public init(from decoder: Decoder) throws {
      var container = try decoder.unkeyedContainer()
      let x = try container.decode(Float.self)
      let y = try container.decode(Float.self)
      let z = try container.decode(Float.self)
      self.init(x, y, z)
   }
}

extension HasTransform {
   public func look(at target: qVector3, from position: qVector3, upVector: qVector3 = qVector3(0, 1, 0), relativeTo referenceEntity: qEntity?) {
      // TODO: implementation of lookAt function.
   }
   public func visualBounds(recursive: Bool = true, relativeTo referenceEntity: qEntity?, excludeInactive: Bool = false) -> qBoundingBox {
      return self.model?.mesh.bounds ?? qBoundingBox(min: qVector3(0, 0, 0), max: qVector3(0, 0, 0))
   }
   public func position(relativeTo referenceEntity: qEntity?) -> qVector3 {
      return self.convertPosition(self.position, to: referenceEntity)
   }
   public func convert(position: SCNVector3, from referenceEntity: qEntity?) -> SCNVector3 {
      return self.convertPosition(position, from: referenceEntity)
   }
   public func setScale(_ scale: SCNVector3, relativeTo referenceEntity: qEntity?) {
      self.transform.scale = scale
      // TODO: write set scale realtive to entity for scenekit
   }
   public func setPosition(_ position: qVector3, relativeTo referenceEntity: SCNNode?) {
      self.position = position
   }
   
}

public protocol qEntityGestureRecognizer : UIGestureRecognizer {

    /// The entity the receiver is associated with
    var entity: qHasCollision? { get set }

    /// Returns the unprojected location of the gesture represented by the receiver in the space of the given entity.
    ///
    /// - Parameters:
    ///     - entity: An entity in whose space the location is computed.
    ///               A `nil` entity will result in world space.
    ///
    /// - Returns: The 3D position identifying the location of the gesture in the space specified.
    ///
    /// The location is typically the result of a centroid of touches for a gesture, unprojected onto the associated `entity`, and then
    /// converted into the space of the entity passed in, or world space if `nil` is passed in.
    func location(in entity: qEntity?) -> qVector3?
}

@objc open class qEntityRotationGestureRecognizer : UIRotationGestureRecognizer, qEntityGestureRecognizer {
   public func location(in entity: qEntity?) -> qVector3? {
      return qVector3(0, 0, 0)
   }
   

   public var entity: qHasCollision?

   @objc override dynamic open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
   }

   @objc override dynamic open func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
      return false
   }
   
   @objc override dynamic public init(target: Any?, action: Selector?) {
      super.init(target: target, action: action)
   }
   
}

@objc open class qEntityScaleGestureRecognizer : UIPinchGestureRecognizer, qEntityGestureRecognizer {
   public func location(in entity: qEntity?) -> qVector3? {
      return qVector3(0, 0, 0)
   }
   
   public var entity: qHasCollision?
   
   @objc override dynamic open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
   }
   
   @objc override dynamic open func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
      return false
   }
   
   @objc override dynamic public init(target: Any?, action: Selector?) {
      super.init(target: target, action: action)
   }
}

@objc open class qEntityTranslationGestureRecognizer : UIGestureRecognizer, qEntityGestureRecognizer {
   
   public var entity: qHasCollision?
   
   @objc override dynamic open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
   }
   
   @objc override dynamic open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
   }
   
   @objc override dynamic open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
   }
   
   @objc override dynamic open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
   }
   
   @objc override dynamic open func reset() {
   }
   
   @objc override dynamic open func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
      return false
   }
   
   open func translation(in entity: qEntity?) -> qVector3? {
      return qVector3(0, 0, 0)
   }
   
   open func setTranslation(_ translation: qVector3, in entity: qEntity?) {
   }
   
   open func velocity(in entity: qEntity?) -> qVector3 {
      return qVector3(0, 0, 0)
   }
   
   public func location(in entity: qEntity?) -> qVector3? {
      return qVector3(0, 0, 0)
   }
   
   @objc override dynamic public init(target: Any?, action: Selector?) {
      super.init(target: target, action: action)
   }
}

public protocol qHasCollision : HasTransform {
}

extension qHasCollision {

    /// Defines the shape and settings for collision detection.
   var collision: qCollisionComponent? {
      get {
         // TODO: IMPLEMENT
         return qCollisionComponent(shapes: [])
      }
   }
}

open class qEntity: SCNNode, HasTransform {
   var qModel: qModelComponent? = nil
   var distanceToCameraChanged: ((Float)->qVector3)? = nil

   public var isEnabled:Bool {
      get {return !self.isHidden}
      set(enabled) {
         self.isHidden = !enabled
      }
   }
   public var model: qModelComponent? {
      get {
         if let model = qModel {
            return model
         } else {
            return qModelComponent(mesh: qMeshResource.generateBox(size: qVector3(self.boundingBox.max.x - self.boundingBox.min.x, self.boundingBox.max.y - self.boundingBox.min.y, self.boundingBox.max.z - self.boundingBox.min.z)), materials: [qUnlitMaterial()])
         }
      }
      set(model) {
         self.qModel = model
         // Insert model components
         if let mesh = model?.mesh, let materials = model?.materials {
            self.components.set(qModelComponent(mesh: mesh, materials: materials))
         }
         self.qModel?.mesh.materials = model?.materials ?? [qUnlitMaterial()]
         // Change the renderingOrder to -1 so that it's drawn before any other node in the scene. This will make this node write in the depth buffer before any other object, preventing them from being drawn if they are behind this node.
         // https://stackoverflow.com/questions/44893320/arkit-hide-objects-behind-walls
         if let _ = model?.materials as? [qOcclusionMaterial] {
            self.renderingOrder = -1
         }
         self.geometry = qModel?.mesh
      }
   }
   public var components: ComponentSet = ComponentSet()
   
   // Use the built-in Entity.ComponentSet to attach any custom object to an entity
   class customComponent_t<T> : Component {
      var object: T
      init( _ o: T ) { object = o }
   }
   var customComponent: Any? {
      get {
         if let component = self.components[ customComponent_t<Any>.self ] {
            return (component as! customComponent_t).object
         } else {
            return nil
         }
      }
      set {
         if let v = newValue {
            self.components[ customComponent_t<Any>.self ] = customComponent_t(v)
         }
      }
   }
   func setRecursive( withObject: Any )
   {
      self.customComponent = withObject
      for child in self.children {
         child.setRecursive( withObject: withObject)
     }
   }
   func forceName(_ name: String, recursive: Bool = false) {
      self.name = name
      if recursive{
         for child in self.children {
            child.forceName(name, recursive: true)
         }
      }
   }
   // This function moves an entity, animating if @TimeInterfval > 0
   func move( to: qTransform, relativeTo: SCNNode? = nil, duration: TimeInterval ) {
      CATransaction.begin()
      let from = self.transform
      let animation = CABasicAnimation(keyPath: "transform")
      animation.fromValue = from
      animation.toValue = to
      animation.duration = duration
      animation.fillMode = .forwards
      // Callback function
      CATransaction.setCompletionBlock {
         self.transform = to
      }
      self.addAnimation(animation, forKey: "transform")
      CATransaction.commit()
   }
   
   public var children: [qEntity] {
      get {
         return self.childNodes as? [qEntity] ?? []}
   }
   
   public override init() {
      super.init()
   }
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) will not been implemented")
   }
   public convenience init(world: qVector3) {
      self.init()
      // TODO: Initialize at location provided by 'world'
   }
   public convenience init(_ target: qAnchoringComponent.Target) {
      self.init()
      switch target {
         case .camera: break // TODO: Initialize to always point to to camera
         case .world(let transform):
            _ = transform
            break//TODO: Initialize to world location defined by transform
      }
   }
   public static func loadModel(contentsOf: URL) throws -> qModelEntity {
      let virtualObjectScene = try SCNScene(url: contentsOf as URL, options: nil)
      let wrapperNode = qModelEntity()
      
      for child in virtualObjectScene.rootNode.childNodes {
          child.geometry?.firstMaterial?.lightingModel = .constant
          child.geometry?.firstMaterial?.isDoubleSided = true
          child.movabilityHint = .movable
          wrapperNode.addChildNode(child)
      }
      return wrapperNode
   }
   public static func loadModel(named name: String, in bundle: Bundle? = nil) throws -> qModelEntity {
      let filename: NSString = name as NSString
      let pathExtention = filename.pathExtension
      let pathPrefix = filename.deletingPathExtension
      var path: String? = nil
      if let bundle = bundle {
         path = bundle.path(forResource: pathPrefix, ofType: pathExtention)
      } else {
         path = Bundle.main.path(forResource: pathPrefix, ofType: pathExtention)
      }
      guard let path = path else{
         return qModelEntity()
      }
      let url = NSURL(fileURLWithPath: path)
      let virtualObjectScene = try SCNScene(url: url as URL, options: nil)
      let wrapperNode = qModelEntity()
      
      for child in virtualObjectScene.rootNode.childNodes {
          child.geometry?.firstMaterial?.lightingModel = .constant
          child.geometry?.firstMaterial?.isDoubleSided = true
          child.movabilityHint = .movable
          wrapperNode.addChildNode(child)
      }
      return wrapperNode
   }
   public func addChild(_ child: qEntity) {
      self.addChildNode(child)
   }
   public func removeFromParent() {
      self.removeFromParentNode()
   }
   public func removeAllChildren() {
      self.enumerateChildNodes { (node, stop) in
          node.removeFromParentNode()
      }
   }
   public func setBillboardConstraints(arView: qARView, rootEntity: qEntity) {

      let transformConstraint = SCNTransformConstraint(inWorldSpace: false) { (node, transform) -> SCNMatrix4 in
         guard let POVPosition = arView.pointOfView?.worldPosition else { return transform}
         
         let cameraPosition = vector_float3(POVPosition)
         let currentPosition = vector_float3(node.worldPosition)
         let distanceToCamera = simd_distance(currentPosition, cameraPosition)
         if let callback = self.distanceToCameraChanged {
            let scaleFactor = callback(distanceToCamera)
            let scaleMatrix = SCNMatrix4MakeScale(scaleFactor.x, scaleFactor.y, scaleFactor.z)
            return SCNMatrix4Mult(scaleMatrix, node.transform)
         }
         return node.transform
      }
      transformConstraint.isIncremental = false
      let billboardConstraint = SCNBillboardConstraint()
      billboardConstraint.freeAxes = .init(arrayLiteral: [.Y])
      self.constraints = [transformConstraint, billboardConstraint]
   }
   public func getMaxBounds() -> qVector3? {
      return self.geometry?.boundingBox.max
   }
   public func getMinBounds() -> qVector3? {
      return self.geometry?.boundingBox.min
   }
   public func generateCollisionShapes(recursive: Bool){
      // TODO:
   }
   public func qOrientation(angle:Float ,axis: SIMD3<Float> ) -> SCNQuaternion{
      return SCNQuaternion(simd_quatf(angle: angle, axis: axis).vector)
   }
   func update( mesh: qMeshResource? = nil, materials: [qMaterial]? = nil) {
      if self.components[qModelComponent.self] == nil, let me = mesh, let ma = materials {
         self.model = qModelComponent(mesh: me, materials: ma)
         // Insert model components
         self.components.set(qModelComponent(mesh: me, materials: ma))
      }
      else if var modelGuts = self.components[qModelComponent.self], modelGuts.materials.count > 0 {
         if let m = mesh {
            modelGuts.mesh = m
            self.model?.mesh = m
         }
         if let m = materials {
            modelGuts.materials = m
            self.model?.materials = m
         }
         self.components.set(modelGuts)
      } else {
         // TODO: error handling here
      }
      // TODO: Implement this
   }
   /// Stores a set of `Component`s.
   public struct ComponentSet {
      
      var component: [Component] = []
      
      /// Gets or sets the component of the specified type.
      public subscript<T>(componentType: T.Type) -> T? where T : Component {
         get {
            return self.component.filter {
               type(of: $0) == componentType
            }.first as? T
         }
         set {
            self.component.append(newValue!)
         }
      }
      
      public mutating func set<T>(_ component: T) where T : Component {
         self.component.append(component)
      }
      
      /// Removes all components from the collection.
      public mutating func removeAll() {
         self.component.removeAll()
      }
   }
}

public protocol Component {
}

extension Component {

    /// Registers a new component type.
   public static func registerComponent() {
   }
}

open class qModelEntity: qEntity, qHasModel, qHasPhysics {
   public var collision: qCollisionComponent?
   
   public override init() {
      super.init()
   }
   public init(mesh: qMeshResource, materials: [SCNMaterial]) {
      super.init()
      self.model = qModelComponent( mesh: mesh, materials: materials )
   }
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) will not been implemented")
   }
   func updateChildNodePosition(withName name: String, xPosition: Float, yPosition: Float, zPosition: Float) {
      self.enumerateChildNodes { (node, stop) in
         if(node.name == name) {
            node.position.x = node.position.x + xPosition
            node.position.y = node.position.y + yPosition
            node.position.z = node.position.z + zPosition
         }
      }
   }
   func updateMaterials(materials: [qMaterial]) {
      self.model?.materials = materials
   }
   func setPositionForText(_ position: SIMD3<Float>, relativeTo: SCNNode? = nil, withFont font: UIFont, align: CTTextAlignment = .center ) {
      if let model = self.model {
         let yOffset = getTextCenterYAdjustment(withFont: font)
         switch align {
            case .left:
               self.setPosition(qVector3(position.x,
                                         yOffset + position.y,
                  position.z),
                  relativeTo: relativeTo)
            default:
               self.setPosition(qVector3(-model.mesh.bounds.center.x + position.x,
                                          yOffset + position.y,
                  position.z),
                  relativeTo: relativeTo)
         }
      }
   }
   
   func getTextCenterYAdjustment(withFont font: UIFont) -> Float {
      guard let model = self.model else { return 0 }
      return -model.mesh.bounds.center.y
   }
}

open class qARView: ARSCNView {
//   public private(set) var scene: Scene = Scene()
//   public private(set) var currentFrame: ARFrame
   public var cameraMode: CameraMode = .ar
   public enum CameraMode {
      case ar
      case nonAR
   }
   
   public var renderOptions: [RenderOptions] = []
   public enum RenderOptions {
      case disableAREnvironmentLighting
      case disableMotionBlur
      case disableDepthOfField
   }
   
   var cameraTransformMatrix: simd_float4x4 {
      get {
         return self.session.currentFrame?.camera.transform ?? simd_float4x4()
      }
   }
   
   public var automaticallyConfigureSession: Bool = true
   
   func showDebugInfo(show: Bool) {
      self.showsStatistics = show
   }
   func start(enableMicrophone: Bool) {
      let configuration  = ARWorldTrackingConfiguration()
      configuration.providesAudioData = enableMicrophone
      self.session.run(configuration)
   }
   func getTappedEntity(tapLocation: CGPoint, maxRange: Float) -> qEntity? {
      let hitTestResults = self.hitTest(tapLocation, options: nil)
      return (hitTestResults.first?.node as? qEntity)
   }
   public func installGestures(_ gestures: qARView.qEntityGestures = .all, for entity: qHasCollision) -> [qEntityGestureRecognizer] {
      return []
   }
   
   public struct qEntityGestures : OptionSet {

       public let rawValue: Int

      public init(rawValue: Int) {
         self.rawValue = rawValue
      }

       /// A single touch drag gesture, to move entities along their anchoring plane
       public static let translation: qARView.qEntityGestures = qARView.qEntityGestures(rawValue: 1 << 0)

       /// A multitouch rotate gesture, to perform yaw rotation
       public static let rotation: qARView.qEntityGestures = qARView.qEntityGestures(rawValue: 1 << 1)

       /// A multitouch pinch gesture, to scale entities
       public static let scale: qARView.qEntityGestures = qARView.qEntityGestures(rawValue: 1 << 2)

       /// All gesture types
      public static let all: qARView.qEntityGestures = [.translation, .rotation, .scale]
      
       /// The type of the elements of an array literal.
       public typealias ArrayLiteralElement = qARView.qEntityGestures

       public typealias Element = qARView.qEntityGestures

       public typealias RawValue = Int
   }
   func ray(through: CGPoint) -> (origin: SIMD3<Float>, direction: SIMD3<Float>)? {
      // TODO: This is my guess at the proper parameters, needs attention and testing
      let result: ARRaycastQuery? = raycastQuery(from: through, allowing: .existingPlaneGeometry, alignment: .any)
      if let r = result {
         return (r.origin, r.direction)
      } else {
         return nil
      }
   }
   func enableAntialiasing( _ v : Bool ) {
      if v {
         self.antialiasingMode = .multisampling4X
      } else {
         self.antialiasingMode = .none
      }
   }
}

class qText: SCNText {
   public init(string: String, extrusionDepth: Float = 0.25, alignmentMode: CTTextAlignment, lineBreakMode: CTLineBreakMode = .byTruncatingTail, font: UIFont, containerFrame: CGRect = CGRect.zero) {
      super.init()
      
      self.string = string
      self.extrusionDepth = CGFloat(extrusionDepth)
      self.font = font
      if containerFrame != CGRect.zero {
         self.containerFrame.size = CGSize(width: containerFrame.maxX, height: containerFrame.maxY)
      }
      
      switch alignmentMode {
      case .center: self.alignmentMode = CATextLayerAlignmentMode.center.rawValue
      case .right: self.alignmentMode = CATextLayerAlignmentMode.right.rawValue
      case .left: self.alignmentMode = CATextLayerAlignmentMode.left.rawValue
      case .justified: self.alignmentMode = CATextLayerAlignmentMode.justified.rawValue
      case .natural: self.alignmentMode = CATextLayerAlignmentMode.natural.rawValue
      default: self.alignmentMode = CATextLayerAlignmentMode.left.rawValue
      }
      
      switch lineBreakMode {
      case .byTruncatingHead:
         self.truncationMode = CATextLayerTruncationMode.start.rawValue
      case .byTruncatingTail:
         self.truncationMode = CATextLayerTruncationMode.end.rawValue
      case .byTruncatingMiddle:
         self.truncationMode = CATextLayerTruncationMode.middle.rawValue
      default:
         self.truncationMode = CATextLayerTruncationMode.end.rawValue
      }
   }
   public override init() {
      super.init()
   }
   required init?(coder: NSCoder) {
      fatalError("init(coder:) will not been implemented")
   }
}

public struct qModelComponent: Component {
   public var mesh: qMeshResource
   public var materials: [SCNMaterial]
   
   public init(mesh: qMeshResource, materials: [SCNMaterial]) {
      self.mesh = mesh
      self.materials = materials
      // TODO: Any SceneKit Init here relating the mesh with the material?
   }
}

public class qUnlitMaterial: qMaterial {
   
   public struct MaterialParameters {
      struct Texture {
         let resource: qTextureResource
         init(_ resource: qTextureResource) {
            self.resource = resource
         }
      }
   }
   public struct BaseColor {
      var texture: MaterialParameters.Texture?
      var tint: UIColor?
      init( tint: UIColor = UIColor.white, texture: MaterialParameters.Texture? = nil ) {
         self.texture = texture
         self.tint = tint
      }
   }
   public struct Opacity: ExpressibleByFloatLiteral {
      var scale: Float
      var opacityThreshold: Float?
      public init(floatLiteral value: Float) {
         self.scale = value
      }
   }
   public enum Blending {
      case opaque
      case transparent(opacity: Opacity)
   }

   public var color: BaseColor = BaseColor() {
      didSet {
         self.diffuse.contents = color.texture?.resource.qTexture ?? color.tint
         // TODO: update the "color" here, which is almost certainly a texture
      }
   }
   public var blending: Blending = .opaque
   public var opacityThreshold: Float?
   
   public init(color: UIColor) {
      super.init()
      self.lightingModel = .constant
      self.diffuse.contents = color
      self.locksAmbientWithDiffuse = true
   }
   public override init() {
      super.init()
      self.lightingModel = .constant
      self.locksAmbientWithDiffuse = true
   }
   required init?(coder: NSCoder) {
      fatalError("init(coder:) will not been implemented")
   }
}

public extension UIColor {
   convenience init(tint: UIColor) {
      self.init()
   }
}

public class qOcclusionMaterial: qMaterial {
   public override init() {
      super.init()
      self.colorBufferWriteMask = []
      self.lightingModel = LightingModel.constant
      self.writesToDepthBuffer = true
   }
   
   required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
}

public struct qAnchoringComponent {
   public enum Target {
      case camera
      case world(transform: float4x4)
   }
}

public class qShapeResource {
   public static func generateBox(size: qVector3) -> qShapeResource {
      // TODO: Generate a box shape centered at the origin of size widthX, widthY, widthZ
      return qShapeResource()
   }
   public func offsetBy(rotation: simd_quatf) -> qShapeResource {
      // TODO: Apply rotation.
      return qShapeResource()
   }

}

public struct qCollisionComponent {
   public var shapes: [qShapeResource]
   public init(shapes: [qShapeResource]) {
      self.shapes = shapes
   }
}

public struct qBoundingBox {
   var min: qVector3
   var max: qVector3
   init() {
      min = qVector3(0,0,0)
      max = qVector3(1,1,1)
   }
   init( min: qVector3, max: qVector3 ) {
      self.min = min
      self.max = max
   }
   var center: qVector3 {
      get {
         return qVector3((abs(max.x) + abs(min.x)) / 2.0, (abs(max.y) + abs(min.y)) / 2.0, (abs(max.z) + abs(min.z)) / 2.0)
      }
   }
   var extents: qVector3 {
      get {
         return qVector3(((max.x) - (min.x)), ((max.y) - (min.y)), ((max.z) - (min.z)))
      }
   }
}

public class qTextureResource: qResource {
   var qTexture: MTLTexture?

   public enum Semantic {
      case none
   }
   public enum MipmapsMode {
       case none
   }
   public struct CreateOptions {
      init( semantic: Semantic ) {}
   }
   
   public init(texture: MTLTexture) {
      self.qTexture = texture
   }
   
   public static func generate(from cgImage: CGImage, withName resourceName: String? = nil, options: qTextureResource.CreateOptions) throws -> qTextureResource {
      let data = UIImage(cgImage: cgImage).pngData()

      // Create the texture from the device by using the descriptor
      guard let device = MTLCreateSystemDefaultDevice() else
      {
         fatalError("GPU not available")
      }
      let textureLoader = MTKTextureLoader(device: device)
      let texture: MTLTexture = try textureLoader.newTexture(data: data!, options: nil)//newTexture(cgImage: cgImage, options: options)
      return qTextureResource(texture: texture)
   }
}

public protocol qResource {
}

extension SCNHitTestResult {
   var entity: qEntity? {
      get {
         return node as? qEntity
      }
   }
}

extension qTransform {
   init() {
      self.init(matrix_identity_float4x4)
   }
   init( matrix: float4x4 ) {
      self.init(matrix)
   }
   var matrix: float4x4 { get { return float4x4(self) } }
   var translation: SIMD3<Float> {
      get { return SIMD3<Float>(self.m41, self.m42, self.m43) }
      set {
         // Translation, Rotation and scale should be applied in this order T * R * S.
         self = SCNMatrix4Mult(SCNMatrix4MakeScale(self.scale.x, self.scale.y, self.scale.z), SCNMatrix4Mult(SCNMatrix4MakeRotation(self.rotation.angle, self.rotation.axis.x, self.rotation.axis.y, self.rotation.axis.z), SCNMatrix4MakeTranslation(newValue.x, newValue.y, newValue.z)))
      }
   }
   var scale: qVector3 {
      get {
         let scaleMatrix = self
         return qVector3(sqrt(scaleMatrix.m11*scaleMatrix.m11 + scaleMatrix.m12*scaleMatrix.m12 + scaleMatrix.m13*scaleMatrix.m13), sqrt(scaleMatrix.m21*scaleMatrix.m21 + scaleMatrix.m22*scaleMatrix.m22 + scaleMatrix.m23*scaleMatrix.m23), sqrt(scaleMatrix.m31*scaleMatrix.m31 + scaleMatrix.m32*scaleMatrix.m32 + scaleMatrix.m33*scaleMatrix.m33))
      }
      set(newValue) {
         // Translation, Rotation and scale should be applied in this order T * R * S.
         self = SCNMatrix4Mult(SCNMatrix4MakeScale(newValue.x, newValue.y, newValue.z), SCNMatrix4Mult(SCNMatrix4MakeRotation(self.rotation.angle, self.rotation.axis.x, self.rotation.axis.y, self.rotation.axis.z), SCNMatrix4MakeTranslation(self.translation.x, self.translation.y, self.translation.z)))
      }
   }
   var rotation: simd_quatf {
      get {
         let rotationMatrix = SCNMatrix4Mult(SCNMatrix4MakeScale(self.scale.x, self.scale.y, self.scale.z).invert(), SCNMatrix4Mult(self, SCNMatrix4MakeTranslation(self.translation.x, self.translation.y, self.translation.z).invert()))
         var rotationAngle = simd_quatf(rotationMatrix.matrix)
         if(rotationAngle.imag == [0, 0, 0]) {
            rotationAngle = simd_quatf(vector: [1, 0, 0, 0])
         }
         return rotationAngle
      }
      set {
         // Translation, Rotation and scale should be applied in this order T * R * S.
         self = SCNMatrix4Mult(SCNMatrix4MakeScale(self.scale.x, self.scale.y, self.scale.z), SCNMatrix4Mult(SCNMatrix4MakeRotation(newValue.angle, newValue.axis.x, newValue.axis.y, newValue.axis.z), SCNMatrix4MakeTranslation(self.translation.x, self.translation.y, self.translation.z)))
      }
   }
   var identity: qTransform {
      get { return SCNMatrix4(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 1, m34: 0, m41: 0, m42: 0, m43: 0, m44: 1)}
   }
//   mutating func rotate(quat: qQuaternion) -> qTransform {
//      var rotationMatrix: SCNMatrix4 = self
//      rotationMatrix = SCNMatrix4Mult(rotationMatrix, SCNMatrix4MakeRotation(quat.angle, quat.axis.x, quat.axis.y, quat.axis.z))
//      return rotationMatrix
//   }
   func invert() -> qTransform {
      return SCNMatrix4Invert(self)
   }
//   mutating func translate(vector: qVector3) -> qTransform {
//      return SCNMatrix4MakeTranslation(vector.x, vector.y, vector.z)
//   }
   func multiply(matrix: qTransform) -> qTransform {
      return SCNMatrix4Mult(self, matrix)
   }
}
extension SCNScene {
   public enum CollisionCastQueryType {
      case nearest
      case all
      case any
   }
   public struct CollisionCastHit {
      var entity: qEntity
      var position: SIMD3<Float>
      var normal: SIMD3<Float>
      var distance: Float
   }
   
   public var anchors: SCNNode {
      get { return rootNode }
   }
   public func addAnchor(_ entity: SCNNode) {
      rootNode.addChildNode(entity)
   }
   public func raycast(origin: SIMD3<Float>,
      direction: SIMD3<Float>,
      length: Float = 100,
      query: CollisionCastQueryType) -> [CollisionCastHit] {
      // TODO: Implement this!
      return []
   }
}
extension SCNNode {
   public func append(_ entity: qEntity) {
      self.addChildNode( entity )
   }
   public func convert(transform: qTransform, to referenceEntity: qEntity?) -> qTransform {
      // TODO: Implement for scenekit to match RealityKit.Entity.convert
      return self.convertTransform(transform, to: referenceEntity)
   }
}
extension qMeshResource {
   public typealias Font = UIFont
   var bounds: qBoundingBox {
      get {
         let (bbMin, bbMax) = self.boundingBox
         return qBoundingBox( min: bbMin, max: bbMax )
      }
   }

   static func generate( triangleVertices: [SIMD3<Float>],
      indices: [UInt32],
      normals: [SIMD3<Float>]? = nil,
      uvs: [SIMD2<Float>]? = nil ) -> qMeshResource? {
      var sources: [SCNGeometrySource] = []
      
      // Convert from SIMD3 to SCNVector, then add the vertices
      sources.append( SCNGeometrySource(vertices: triangleVertices.map { SCNVector3($0) }) )
      
      if let n = normals {
         sources.append( SCNGeometrySource(normals: n.map { SCNVector3($0) }) )
      }
//      if let u = uvs {
//         let sv: [SCNVector2] = u.map { qVector3($0) }
//         sources.append( SCNGeometrySource(uvs: sv) )
//      }

      let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
      return SCNGeometry(sources: sources, elements: [element])
   }
   static func generate( hexagonVertices: [qVector3],
      indices: [UInt32] ) -> qMeshResource? {
      var qIndices = indices
      var sources: [SCNGeometrySource] = []
      qIndices.insert(6, at: 0)
      sources.append( SCNGeometrySource(vertices: hexagonVertices) )

      let indexData = Data(bytes: qIndices, count: qIndices.count * MemoryLayout<Int32>.size)
      let element = SCNGeometryElement(data: indexData, primitiveType: .polygon, primitiveCount: 1, bytesPerIndex: MemoryLayout<Int32>.size)

      return SCNGeometry(sources: sources, elements: [element])
   }
   static func generateBox( width: Float, height: Float, depth: Float, cornerRadius: Float = 0.0 ) -> qMeshResource {
      return SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(depth), chamferRadius: CGFloat(cornerRadius))
   }
   static func generateSphere( radius: Float ) -> qMeshResource {
      return SCNSphere(radius: CGFloat(radius))
   }
   static func generateBox( size: qVector3, cornerRadius: Float = 0.0 ) -> qMeshResource {
      return SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: CGFloat(cornerRadius))
   }
   static func generateText(_ string: String, extrusionDepth: Float = 0.25, font: UIFont, containerFrame: CGRect = CGRect.zero, alignment: CTTextAlignment = .left, lineBreakMode: CTLineBreakMode = .byTruncatingTail) -> qMeshResource {
      let text = qText(string: string, extrusionDepth: extrusionDepth, alignmentMode: alignment, lineBreakMode: lineBreakMode, font: font, containerFrame: containerFrame)
      text.flatness = 0.1
      return text
   }
   static func generatePlane(width: Float, height: Float, cornerRadius: Float = 0) -> qMeshResource {
      let plane = SCNPlane(width: CGFloat(width), height: CGFloat(width))
      plane.cornerRadius = CGFloat(cornerRadius)
      return plane
   }
}
extension SIMD4 where Scalar == Float {
   init(_ vec: SCNVector3, _ w: Scalar) {
      self.init(SIMD3<Float>(vec), w)
   }
}

#endif
