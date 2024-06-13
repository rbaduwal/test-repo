import Foundation
import propsyncSwift

public class golfData: sportData {
   
   // sportData interface
   public private(set) var config: sportDataConfig
   public private(set) var isDataSynced = false
   public var configUpdated: ((sportDataConfig) ->())? = nil
   public var liveSynced: ((sportData) ->())? = nil
   public var threadSafety = DispatchQueue(label: "sportData", attributes: .concurrent)

   // golfData stuff
   public var gid: String { self.sportDataPropsync?["gid"]?.get() ?? "" }
   public var isLive: Bool { self.sportDataPropsync?["isLive"]?.get() ?? false }
   public private(set) var sportDataPropsync: propsync?
   public private(set) var currentRound: golfRound? = nil
   public private(set) var rounds: [golfRound] = []
   public var activeRounds: [golfRound] {
      if let currentRoundNumber = currentRound?.num {
         if ( self.rounds.count >= currentRoundNumber ) {
            return Array(self.rounds[0 ..< currentRoundNumber])
         } else {
            return self.rounds
         }
      } else {
         return []
      }
   }
   public private(set) var currentCourse: golfCourse? = nil
   public private(set) var courses: [golfCourse] = []
   private var deferredNotificationTimer: Timer? = nil
   private var deferredNotifications: [Notification] = []
   private var notificationCenter = NotificationCenter.default
   
   public required init(config: sportDataConfig) throws {
      self.config = config

      // Do this once for the entire app
      propsyncApi.initialize()
   
      // Create our sport data dictionary. We can open/close as needed later.
      if let sportDataPropsyncUrl = config.decodedData?.liveDataUrl {
         sportDataPropsync = try .init( fromUrl: sportDataPropsyncUrl )
      } else {
         sportDataPropsync = try .init()
      }
      
      // Setup event handlers for sport data, which will apply to both live and archived
      if let sdp = sportDataPropsync {
         sdp.rootChanged = onRootChanged
         sdp.synced = onSynced
         onRootChanged(newRoot: sdp.root)
      }
      
      // Grab archived data
      if let entrypointUrl = config.decodedData?.apiEntrypointUrl,
         let lid = config.decodedData?.lid,
         let gid = config.decodedData?.gid {
            
         // games API
         if let gamesData = try platformApis.callGamesApi( entrypoint: entrypointUrl,
            lid: lid,
            gid: gid) {
            
            try self.parseGamesApi( gamesData )
         }
         
         // players API
         // TODO: start using players API; for now, everything is in games API
         //if let playersData = try platformApis.callPlayersApi(entrypoint: entrypointUrl,
         //   lid: lid) {
         //
         //   try self.parsePlayersApi( playersData )
         //}
         
// TODO: Remove these two lines when game chronicles is functional
let entrypointUrlTemp = "https://quintardatalakedev.blob.core.windows.net/"
let gidTemp = gid + ".json"
         // gameChronicles API
         // Okay if this fails because we may be at the beginning of a tournament
         do {
            if let gameChroniclesData = try platformApis.callGameChroniclesApi(entrypoint: entrypointUrlTemp,
               lid: lid,
               gid: gidTemp) {

               try parseGameChroniclesApi(gameChroniclesData)
            }
         } catch {
            log.instance.push(.WARNING, msg: "No game chronicles for \(gid), assuming all data will be live")
         }
      }
   }
   deinit {
      // Do this once
      propsyncApi.uninitialize()
   }
   
   // sportData interface
   public func queryArchive(query: String) {
   }
   public func startLive() {
      if let ld = sportDataPropsync,
         !ld.isOpen {
         
         do {
            try sportDataPropsync?.open()
            
            // Start our deferred notification timer
            //Added the timer to background threads run loop.
            DispatchQueue.global(qos: .background).async {
               self.deferredNotificationTimer = Timer(timeInterval: 3, target: self, selector: #selector(self.onDeferredNotifications), userInfo: nil, repeats: true)
               let runLoop = RunLoop.current
               runLoop.add(self.deferredNotificationTimer!, forMode: .default)
               runLoop.run()
            }
         } catch let e {
            log.instance.push(.ERROR, msg: "\(e)" )
            retryServerConnection()
         }
      }
   }
   public func stopLive() {
      if let ld = sportDataPropsync,
         ld.isOpen {
         
         self.deferredNotificationTimer = nil
         ld.close()
      }
      isDataSynced = false
   }
   public func postNotification(name: String, object: Any?, userInfo: [AnyHashable:Any]? = nil, canDefer: Bool = true) {
      // Don't post any notifications until we are initialized AND synchronized
      if self.isDataSynced {
         DispatchQueue.main.async {
            // TODO: Replace these notifications with an observer pattern:
            //  https://www.swiftbysundell.com/articles/observers-in-swift-part-1/
            let newNotification = Notification(name: Notification.Name(rawValue: name), object: object, userInfo: userInfo)
            if canDefer {
               self.deferredNotifications.append(newNotification)
            } else {
              self.notificationCenter.post(newNotification)
            }
         }
      }
   }
   
   private func retryServerConnection() {
      DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Double(config.decodedData?.retryConnectionInterval ?? defaults.liveDataTimeout)) {
         if self.sportDataPropsync == nil || (!self.sportDataPropsync!.isOpen && !self.sportDataPropsync!.isOpening) {
            self.startLive()
         }
      }
   }
   private func parseGamesApi( _ gamesData: propsync ) throws {
      // TODO: This hack is due to a discrepency between live data and the current gamesAPI.
      // TODO: Normalize these in the data to avoid this hack
      do {
         let eventData = try gamesData["rounds"]?.extract()
         if var ed = eventData {
            try gamesData.upsert("event/rounds", p: &ed)
         }
      }
   
      // Merge this archived data into our primary sport data dictionary
      var gamesDataRoot = gamesData.extractRoot()
      try self.sportDataPropsync?.upsert("", p: &gamesDataRoot, policy: .MERGE_KEEP_NEW)

      currentCourse = self.courses.first
   }
   private func parsePlayersApi( _ data: propsync ) throws {
      // TODO: This function will need to be updated when the actual players API is used
   }
   private func parseGameChroniclesApi( _ gamesChroniclesData: propsync ) throws {
      // Merge this archived data into our primary sport data dictionary
      var gameChroniclesRoot = gamesChroniclesData.extractRoot()
      try self.sportDataPropsync?.upsert("", p: &gameChroniclesRoot, policy: .MERGE_KEEP_NEW)
   }
   private func onRootChanged( newRoot: property ) {
     newRoot.childAdded = { (xpath, p) in
         switch ( p.key ) {
            case "courses":
               p.childAdded = self.onCourseAdded
            case "event" :
               p.childAdded = self.onEventAdded
            default: break
         }
      }
   }
   private func onSynced() {
      // Set the current round if necessary
      if ( self.currentRound == nil ) {
         self.currentRound = self.rounds.last
      }
      if let currentRound = self.currentRound {
         // Log a useful message
         if let sportDataPropsyncUrl = config.decodedData?.liveDataUrl {
            log.instance.push(.INFO, msg: "Live data synced to \"\(sportDataPropsyncUrl)\", current round is \(currentRound.num)")
         }
      } else {
         log.instance.push(.ERROR, msg: "No rounds")
      }
      
      self.isDataSynced = true

      // Trigger a callback and notification
      if let callback = self.liveSynced {
         callback(self)
      }
      postNotification(name: constants.onSportsDataLoadingCompletedNotification, object: self)
   }
   private func onCourseAdded( xpath: String, courseProps: property ) {
      if let courseNum: Int = courseProps["num"]?.get() {
         if !self.courses.contains(where: { $0.num == courseNum }) {
            let newGolfCourse = golfCourse(sportData: self, courseProps: courseProps)
            self.courses.append( newGolfCourse )
         }
      }
   }
   private func onEventAdded( xpath: String, eventProps: property ) {
      switch ( eventProps.key ) {
         case "rounds":
            eventProps.childAdded = self.onRoundAdded
         case "currentRound":
            eventProps.valueChanged = self.onCurrentRoundChanged
         default: break
      }
   }
   private func onRoundAdded( xpath: String, roundProps: property ) {
      if let roundNum: Int = roundProps["num"]?.get() {
         if !self.rounds.contains(where: { $0.num == roundNum }) {
            let newRound = golfRound(sportData: self, roundProps: roundProps)
            self.rounds.append( newRound )
         }
      }
   }
   private func onCurrentRoundChanged( xpath: String, p: property ) {
      if let roundNum: Int = p.get() {
         // When a tie happens we will get round value as 401, 402 etc. Ignore those values
         if roundNum <= 4 && roundNum <= self.rounds.count {
            self.currentRound = self.rounds[ roundNum - 1]
         } else if self.currentRound == nil && self.rounds.count > 0{
            self.currentRound = self.rounds.first
         }
      }
   }
   @objc private func onDeferredNotifications() {
      DispatchQueue.main.async {
         for notification in self.deferredNotifications {
            self.notificationCenter.post(notification)
         }
         //Cleared the array so as to prevent the same notifications from being posted after every 3 sec.
         self.deferredNotifications = []
      }
   }
}
