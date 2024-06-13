import Foundation
import propsyncSwift

public class basketballData: sportData {

   // sportData interface
   public private(set) var config: sportDataConfig
   public private(set) var isDataSynced = false
   public var configUpdated: ((sportDataConfig) ->())? = nil
   public var liveSynced: ((sportData) ->())? = nil
   public var threadSafety = DispatchQueue(label: "sportData", attributes: .concurrent)
   
   // basketballData stuff
   public private(set) var homeTeam: basketballTeam? = nil
   public private(set) var awayTeam: basketballTeam? = nil
   public private(set) var sportDataPropsync: propsync?
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
         if let gamesData = try platformApis.callGamesApi(entrypoint: entrypointUrl,
            lid: lid,
            gid: gid) {
            
            try parseGamesApi(gamesData)
         }
         
         // Players API is called from each team, not here
         
         // gameChronicles API
         do {
            if let gameChroniclesData = try platformApis.callGameChroniclesApi(entrypoint: entrypointUrl,
               lid: lid,
               gid: gid) {

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
            self.deferredNotificationTimer = Timer.scheduledTimer(timeInterval: 3,
               target: self,
               selector: #selector(self.onDeferredNotifications),
               userInfo: nil,
               repeats: true)
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
      
      // Merge this archived data into our primary sport data dictionary
      var gamesDataRoot = gamesData.extractRoot()
      try self.sportDataPropsync?.upsert("", p: &gamesDataRoot, policy: .MERGE_KEEP_NEW)
      
      // Create home and away teams
      if let teamsArray = self.sportDataPropsync?.find( "/*/teams" ) {
         for teamProps in teamsArray {
            if let isHome: Int = teamProps["isHome"]?.get() {
               if isHome == 1 && self.awayTeam == nil { self.homeTeam = .init( sportData: self, teamProps: teamProps, config: self.config) }
               else if self.awayTeam == nil { self.awayTeam = .init( sportData: self, teamProps: teamProps, config: self.config) }
            }
            else { self.homeTeam = .init( sportData: self, teamProps: teamProps, config: self.config) }
         }
      }
   }
   private func parseGameChroniclesApi( _ gamesChroniclesData: propsync ) throws {
      
      // Merge this archived data into our primary sport data dictionary
      var gameChroniclesRoot = gamesChroniclesData.extractRoot()
      try self.sportDataPropsync?.upsert("", p: &gameChroniclesRoot, policy: .MERGE_KEEP_NEW)
      
      // Helpful log if we don't have event data yet
      if let ht = self.homeTeam,
         let at = self.awayTeam {
         
         if ht.leaders.count == 0 &&
            at.leaders.count == 0 &&
            ht.players.first(where: {$0.shots.count > 0}) == nil &&
            at.players.first(where: {$0.shots.count > 0}) == nil {
            
            log.instance.push(.INFO, msg: "No event data, probably the beginning of the game", userInfo: nil)
         }
      } else {
         log.instance.push(.ERROR, msg: "Missing home and/or away teams", userInfo: nil)
      }
   }
   private func onRootChanged( newRoot: property ) {
      newRoot.childAdded = onChildAdded
   }
   private func onChildAdded( xpath: String, p: property ) {
      switch ( p.key ) {
         case "shots":
            p.childAdded = onShotAdded;
         case "leaderboard":
            p.childAdded = onLeaderboardAdded;
         default: break
      }
   }
   private func onShotAdded( xpath: String, shotProperty: property ) {
      if let tid: Int = shotProperty["tid"]?.get(),
         let pid: Int = shotProperty["pid"]?.get(),
         let eid: Int = shotProperty["eid"]?.get() {
         
         // Find the team
         var team: basketballTeam? = nil
         if let t = self.homeTeam, t.tid == tid { team = self.homeTeam }
         else if let t = self.awayTeam, t.tid == tid { team = self.awayTeam }
         
         // Find player, then add the shot
         if let t = team {
            if let player = t.players.first( where: { $0.pid == pid } ) {
               player.updateShot(withShotProps: shotProperty)
            } else {
               log.instance.push(.ERROR, msg: "Found matching team but could not find matching player \(pid) for shot \(eid)")
            }
         } else {
            log.instance.push(.ERROR, msg: "Could not find matching team \(tid) for shot \(eid): have teams \(self.homeTeam?.tid ?? 0) && \(self.awayTeam?.tid ?? 0)")
         }
      } else {
         log.instance.push(.ERROR, msg: "Shot is missing one of: 'pid', 'tid', 'eid'")
      }
   }
   private func onLeaderboardAdded( xpath: String, lbProperty: property ) {
      if let tid: Int = lbProperty["tid"]?.get(),
         let leadersProps = lbProperty["teamLeaders"] {
         
         // Find the team
         var team: basketballTeam? = nil
         if let t = self.homeTeam, t.tid == tid { team = self.homeTeam }
         else if let t = self.awayTeam, t.tid == tid { team = self.awayTeam }
         
         // Add the leaderboard, if not already set
         if let t = team, t.leadersProps == nil {
            t.update(withLeadersProps: leadersProps)
         }
      } else {
         log.instance.push(.ERROR, msg: "Team leaders is missing one of: 'tid', 'teamLeaders'")
      }
   }
   private func onSynced() {
      self.isDataSynced = true

      // Trigger a callback
      if let callback = self.liveSynced {
         callback(self)
      }
   }
   @objc private func onDeferredNotifications() {
      DispatchQueue.main.async {
         for notification in self.deferredNotifications {
            self.notificationCenter.post(notification)
         }
      }
   }
}
