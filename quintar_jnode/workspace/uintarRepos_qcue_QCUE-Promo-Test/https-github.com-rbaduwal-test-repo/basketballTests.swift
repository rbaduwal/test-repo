import XCTest
import simd
import Q

let arUiViewConfigUrl = "https://quintardatalakedev.blob.core.windows.net/mba/sdk/phobos_slam/qrealityBasketball_test3.json"

class basketballTests: XCTestCase {
   func testCourtQuadrant() {
   
      // Generate some positions
      let numPositions = 36
      let thetaIncrement: Double = (360.0/Double(numPositions))
      for i in (0...numPositions) {
         
         let theta = Double(i) * thetaIncrement
      
         // Rotation and unit vector
         let rot = simd_quatd( angle: theta * .pi / 180, axis: [0,0,1])
         let vec = simd_act(rot, SIMD3<Double>(1, 0, 0))
         
         // Predetermine our quadrant as the 90 degrees centered around the x or y axis
         var quadrant: basketballVenue.QUADRANT = .UNKNOWN
         if      theta >=     0  && theta <   45.0 { quadrant = ._0 }
         else if theta >=  45.0  && theta <  135.0 { quadrant = ._90 }
         else if theta >= 135.0  && theta <  225.0 { quadrant = ._180 }
         else if theta >= 225.0  && theta <  315.0 { quadrant = ._270 }
         else if theta >= 315.0  && theta <= 360.0 { quadrant = ._0 }
         else { XCTFail( "Unknown quadrant encountered" ) }
         
         let result = basketballVenue.getQuadrant(userPosition: vec)
         XCTAssertEqual(quadrant, result, "theta: \(theta), vec: \(vec), expected \(quadrant) but got \(result)")
      }
   }
   
   func testSportData() {
       
      var config: sportDataConfig? = nil
      do {
         if let aruvc = try testHelper.createArUiViewConfigSynchronous(URL: arUiViewConfigUrl) {
            config = aruvc.sportDataConfig
         }
      } catch let e {
         XCTFail(e.localizedDescription)
      }
      XCTAssertNotNil(config)
      
      var bbSportData: basketballData? = nil
      do {
         let data = try arUiViewController.createSportData(sport: .BASKETBALL, config: config!)
         bbSportData = data as? basketballData
      } catch let e {
         XCTFail(e.localizedDescription)
      }
      XCTAssertNotNil(bbSportData)
      XCTAssertNotNil(bbSportData!.homeTeam)
      XCTAssertNotNil(bbSportData!.awayTeam)
      XCTAssertNotNil(bbSportData?.isDataSynced)
      XCTAssertNotNil(bbSportData?.config)
   }
    
    
   func testExperience() {
      var config: arUiViewConfig? = nil
      do {
         config = try testHelper.createArUiViewConfigSynchronous(URL: arUiViewConfigUrl)
      } catch let e {
         XCTFail(e.localizedDescription)
      }
      XCTAssertNotNil(config)
      
      var auvc: arUiViewController? = nil
      let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
      arUiViewController.create( type: basketballVenue.self, config: config! ) { result in
         switch result.error {
         case .NONE:
            auvc = result.controller
         default:
            XCTFail(result.errorMsg)
         }
         semaphore.signal()
      }
      semaphore.wait()
      XCTAssertNotNil(auvc)
      
      // Get the experience
      let bbExperience = auvc?.sportExperience as? basketballVenue
      XCTAssertNotNil(bbExperience)
      
      // Assert selected players start empty, can be changed, and that the callback is made
      XCTAssertEqual(bbExperience?.selectedPlayers.count, 0)
      var callbackPlayersCount = 0
      bbExperience?.playersSelected = { selectedPlayers in
         callbackPlayersCount = selectedPlayers.count
      }
      if let hometeam = bbExperience?.sportData.homeTeam {
         bbExperience?.selectedPlayers = Array(hometeam.players[0...4])
      } else {
         XCTFail("No home team")
      }
      XCTAssertEqual(bbExperience?.selectedPlayers.count, 5)
      XCTAssertEqual(callbackPlayersCount, 5)
      
      // Assert selected teams starts nil, can be changed, and that the callback is made
      XCTAssertEqual(bbExperience?.selectedTeam, nil)
      var callbackSelectedTeam : basketballTeam?  = nil
      
      bbExperience?.teamSelected = { SelectedTeam in
         callbackSelectedTeam = SelectedTeam
      }
      
      if let hometeam = bbExperience?.sportData.homeTeam {
         bbExperience?.selectedTeam = hometeam
      } else {
         XCTFail("No home team")
      }
      
      XCTAssertEqual(callbackSelectedTeam ,bbExperience?.sportData.homeTeam )
      
      
      // Assert selected shot type starts UNKNOWN, can be changed, and that the callback is made
      XCTAssertEqual(bbExperience?.selectedShotType, basketballShot.SHOT_TYPE.UNKNOWN)
      var callbackShotType : basketballShot.SHOT_TYPE = .UNKNOWN
      
      bbExperience?.shotTypeSelected = { ShotType in
         callbackShotType = ShotType
      }
      
      bbExperience?.selectedShotType = basketballShot.SHOT_TYPE.THREE_PTR
      XCTAssertEqual(callbackShotType, bbExperience?.selectedShotType)
      
      bbExperience?.selectedShotType = basketballShot.SHOT_TYPE.FIELD_GOAL
      XCTAssertEqual(callbackShotType, bbExperience?.selectedShotType)
      
      bbExperience?.selectedShotType = basketballShot.SHOT_TYPE.TOTAL
      XCTAssertEqual(callbackShotType, bbExperience?.selectedShotType)
      
      bbExperience?.selectedShotType = basketballShot.SHOT_TYPE.PERIOD
      XCTAssertEqual(callbackShotType, bbExperience?.selectedShotType)
      
      
      // Assert selected period starts empty, can be changed, and that the callback is made
      XCTAssertEqual(bbExperience?.selectedPeriods.count, 0)
      var callbackPeriodsCount = 0
      
      bbExperience?.periodSelected = { Period in
         callbackPeriodsCount = Period.count
      }
      
      bbExperience?.selectedPeriods = [1,2,3]
      XCTAssertEqual(bbExperience?.selectedPeriods.count, 3)
      XCTAssertEqual(callbackPeriodsCount, 3)
   }
   
}


