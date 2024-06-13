// Use this for all internal notifications where objects can have a weak reference.
// NotificationCenter should only be used when objects are completely decoupled (unaware of each other).
//
// Closures, unlike delegates, are not equatable. This means there is no easy
// way to know if a closure has already been added, and thus cannot be removed.
// We work around this by requiring the caller to associate a unique string ID
// for each closure
public class multiClosure<T> {
   private lazy var closures = [String:T]()
   
   public init() {
   }
   
   public func add(_ closure: T, id: String ) {
      closures[id] = closure
   }
   public func remove(_ id: String) {
      closures.removeValue(forKey: id)
   }
   public func invoke( _ invoker: ((T) ->()) ) {
      let closuresCopy = closures
      for (_, closure) in closuresCopy {
         invoker(closure)
      }
   }
}

public func += <T>(lhs: multiClosure<T>, rhs: (String,T)) {
   lhs.add(rhs.1, id: rhs.0)
}
public func -= <T>(lhs: multiClosure<T>, rhs: String) {
   lhs.remove(rhs)
}
