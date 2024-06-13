package ai.quintar.q.ui.basketball

import ai.quintar.q.config.bbConfig
import ai.quintar.q.config.colors
import ai.quintar.q.connect.trackingUpdate
import ai.quintar.q.sportData.basketball.basketballGameChronicles
import ai.quintar.q.sportData.basketball.basketballGameChronicles.heatmaps
import ai.quintar.q.sportData.basketballData
import ai.quintar.q.ui.arUiViewController
import ai.quintar.q.ui.basketball.basketballCourtsideBoard.LOCATION.COURTSIDE
import ai.quintar.q.ui.basketball.basketballCourtsideBoard.LOCATION.USER
import ai.quintar.q.ui.constants
import ai.quintar.q.ui.entities.Baketball.basketballTracesSceneGraphNode
import ai.quintar.q.ui.venue
import ai.quintar.q.utility.ERROR
import ai.quintar.q.utility.errorConditions
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import com.google.gson.Gson
import com.viro.core.AsyncObject3DListener
import com.viro.core.ClickListener
import com.viro.core.ClickState
import com.viro.core.Node
import com.viro.core.Object3D
import com.viro.core.Polyline
import com.viro.core.Vector
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.math.RoundingMode
import java.util.*
import kotlin.concurrent.timer
import kotlin.math.atan2

@Suppress("ClassName")
class basketballVenue(arViewController: arUiViewController, context: AppCompatActivity) :
   venue(arViewController) {
   private var teamLeaderBoard: basketballTeamLeaderBoardNode? = null
   private var playerCard: basketballPlayerCardBoardNode? = null
   private var playerId: Int? = 0
   private var playerName: String? = null
   private var playerImage: String? = null
   private var context: AppCompatActivity? = null
   private var team: Int? = null
   private var tracesInitialized = false
   private var shotType: String? = null

   //   private var basketballDataValue: basketballData? = null
   private var gameChroniclesValue: basketballGameChronicles? = null
   private var bbShots: basketballShots = basketballShots()
   private var basketBallConfig: bbConfig? = null
   private var isHomeTeam: Boolean = true
   private var shotTrailsRootEntity: Node? = null
   private var heatmapRootEntity: Node? = null

   //boardflags are created to avoid updating of team leader board and player card
   //in each frame. If boardflag is 0 new team leader board/player card will create
   //if 1 board will be on point A side and if it is 2 then board is in point B
   private var boardflag = 0
   private var teamChangeFlag = false
   private var rounds: ArrayList<Int>? = null
   private var heatmapSceneGraphNode: basketballHeatMapSceneGraphNode? = null
   private var legendBoardNode: Node? = null
   private var teamLeaderBoardNode: Node? = null
   private var playerCardNode: Node? = null
   private var legendBoardPositionA: Vector = Vector(0f, 0f, 0f)
   private var legendBoardPositionB: Vector = Vector(0f, 0f, 0f)
   private val mainHandler = Handler(Looper.getMainLooper())
   private var apiCallDelay: Long = 5000
   private var oldJson: JSONObject = JSONObject()
   private var teamLeaderBoardView: View? = null
   private var playerCardView: View? = null
   lateinit var viewModel: basketballViewModel
   private var boardLocation: basketballCourtsideBoard.LOCATION = COURTSIDE
   private var isTapped = false

   enum class QUADRANT(val quadrant: Int) { _0(0), _90(1), _180(2), _270(3) }

   //receiving broadcast receiver when registration is completed to initialize traces
   private val mMessageReceiver: BroadcastReceiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context?, intent: Intent) {
         when (intent.action)
         {
            Q_NOTIFICATION_ON_TRACKING_UPDATED -> {
                val result = intent.getSerializableExtra("result") as trackingUpdate
         if (result.error == ERROR.NONE) {
            if (!tracesInitialized) {
               shotTrailsRootEntity = Node()
               heatmapRootEntity = Node()
               legendBoardNode = Node()
               teamLeaderBoardNode = Node()
               playerCardNode = Node()
               worldRootEntity?.addChildNode(legendBoardNode)
               worldRootEntity?.addChildNode(shotTrailsRootEntity)
               worldRootEntity?.addChildNode(teamLeaderBoardNode)
               worldRootEntity?.addChildNode(playerCardNode)
               tracesInitialized = !tracesInitialized
               updateShotTrails()
//                    createHeatmapEntity()
               addCourt3dModel()
               if (playerId == -1) {
                  addTeamLeaderBoard()
               } else {
                  addPlayerCard()
               }
            }
         } else if (result.error == ERROR.ERROR_CONDITION) {
            //checking out of the arena and phone in pocket condition and show the toast
            // if registration values matching conditions
            val gson = Gson()
            val errorCondition = gson.fromJson(
               result.errorBody, errorConditions::class.java
            )
            if ((errorCondition?.errorCode?.equals(constants.insufficientFeatureMatches) == true) && (errorCondition.numberOfMatches == 0)) {
               if (context?.resources?.configuration?.orientation == 2) {
                  Toast.makeText(context, constants.outOfTheArena, Toast.LENGTH_SHORT).show()
               }
            } else if ((errorCondition.numberOfFeatures == 0) && (errorCondition.errorCode?.equals(
                  constants.insufficientFeatureMatches) == true)) {
               Toast.makeText(context, constants.phoneInPocket, Toast.LENGTH_SHORT).show()
            }
         }
            }
         }
      }
   }

   // Function used for adding the 3d model to worldRootEntity.
   private fun addCourt3dModel() {
      val courtNode = Node()
      val courtModel = Object3D()
      val filepath = "file:///android_asset/"
      courtModel.setScale(Vector(.032f, .032f, .032f))
      courtModel.setRotation(Vector(Math.PI / 2, 0.0, 0.0))
      courtModel.setPosition(
         Vector(
            courtModel.positionRealtime.x,
            courtModel.positionRealtime.y,
            courtModel.positionRealtime.z - 0.3f
         )
      )
      arViewController.arView?.let {
         courtModel.loadModel(it.viroContext,
            Uri.parse("${filepath}court_model.gltf"),
            Object3D.Type.GLTF,
            object : AsyncObject3DListener {
               override fun onObject3DFailed(error: String) {
               }
               override fun onObject3DLoaded(`object`: Object3D, type: Object3D.Type) {
               }
            })
         courtNode.addChildNode(courtModel)
         worldRootEntity?.addChildNode(courtNode)
      }
   }

   init {
      viewModel = ViewModelProvider(context)[basketballViewModel::class.java]
      onViewModelUpdated(context)
      basketBallConfig = arViewController.arUiConfig.arConfig
      basketBallConfig?.courtsideBoardDistanceFromCamera?.let {
         constants.courtsideBoardDistanceFromCamera = it.toFloat()
      }

      basketBallConfig?.zoomAnimationDelay?.let {
         constants.courtsideBoardAnimationSpeed = it
      }
      getBasketballData(arViewController.arUiConfig.getGameDataUrl().toString())
      arViewController.arUiConfig.sportconfig?.sportDataConfigData?.apiCallFrequency?.let {
         apiCallDelay = (it * 1000).toLong()
      }
      getGameChroniclesData(
         arViewController.arUiConfig.getGameChronicleDataUrl().toString() + "?eid=0"
      )
      continuousGameChronicleDataFetch()
   }

   fun appResumed() {
      this.worldRootEntity?.removeAllChildNodes()
      tracesInitialized = false
   }

   fun stopTracking() {
      arViewController.tracker?.stopTracking()
   }

   private fun onViewModelUpdated(context: AppCompatActivity) {
      Handler(Looper.getMainLooper()).post {
         viewModel.teamId.observe(context ){
            this.team = it
            this.isHomeTeam = viewModel.isHomeTeam
            teamChangeFlag = true
            if (tracesInitialized) {
               updateShotTrails()
            }
            boardflag = 0
            addTeamLeaderBoard()
         }
         viewModel.playerId.observe(context ){
            this.playerId = it
            this.playerName = viewModel.playerName
            this.playerImage = viewModel.playerHs
            if (tracesInitialized) {
               updateShotTrails()
            }
            boardflag = 0
            if (playerId == -1) {
               addTeamLeaderBoard()
            } else {
               addPlayerCard()
            }
         }
         viewModel.shotType.observe(context ){
            this.shotType = it
            if (shotType == "per") {
               teamChangeFlag = true
            }
            if (tracesInitialized) {
               updateShotTrails()
            }
            boardflag = 0
            if (playerId != -1) {
               addPlayerCard()
            }
         }
         viewModel.rounds.observe(context ){
            this.rounds = it
            if (tracesInitialized) {
               updateShotTrails()
            }
         }
         viewModel.gameChroniclesData.observe(context ){
            if (playerId == -1) {
               addTeamLeaderBoard()
            } else {
               addPlayerCard()
            }
         }
      }
   }

   //for getting game chronicle data every n seconds(n configurable)
   private fun continuousGameChronicleDataFetch() {
      mainHandler.post(object : Runnable {
         override fun run() {
            getGameChroniclesData(
               arViewController.arUiConfig.getGameChronicleDataUrl()
                  .toString() + "?eid=" + viewModel.gameChroniclesData.value?.lastEventID
            )
            boardflag = 0
            if (!tracesInitialized) {
               if (playerId == -1) {
                  addTeamLeaderBoard()
               } else {
                  addPlayerCard()
               }
            }
            mainHandler.postDelayed(this, apiCallDelay)
         }
      })
   }

   //initialize broadcast receiver to get registration completion status
   override fun initialize(context: AppCompatActivity) {
      super.initialize(context)
      this.context = context
      context.registerReceiver(
         mMessageReceiver, IntentFilter(Q_NOTIFICATION_ON_TRACKING_UPDATED)
      )
   }

   //api call to get basketballdata
   private fun getBasketballData(
      basketballDataUrl: String
   ) {
      val downloadResult = arViewController.arUiConfig.downloader?.getJson(basketballDataUrl)
      val gson = Gson()
      if (downloadResult?.error == ERROR.NONE) {
         val basketballData = gson.fromJson(
            downloadResult.result.toString(), basketballData::class.java
         )
         viewModel.updateSportsData(basketballData)
      }
   }

   //api call to get gameChronicles
   private fun getGameChroniclesData(
      gameChroniclesDataUrl: String
   ) {
      arViewController.arUiConfig.downloader?.getJsonAsync(gameChroniclesDataUrl) {
         val gson = Gson()
         if (it.error == ERROR.NONE) {
            if (oldJson.toString() != it.result.toString()) {
               oldJson = it.result
               var gameChronicle = JSONArray()
               if (viewModel.gameChroniclesData.value?.getShots != null) {
                  gameChronicle =
                     JSONArray(gson.toJson(viewModel.gameChroniclesData.value?.getShots))
               }
               val newShots = it.result.optJSONArray("shots")
               newShots?.let { shot ->
                  for (shotIndex in 0 until shot.length()) {
                     gameChronicle.put(shot[shotIndex])
                  }
               }
               it.result.put("shots", gameChronicle)
               val gameChroniclesData = gson.fromJson(
                  it.result.toString(), basketballGameChronicles::class.java
               )
               Handler(Looper.getMainLooper()).post {
                  viewModel.updateGameChronicles(gameChroniclesData)
               }
            }
         }
      }
   }

   private fun startAnimation(shotTraces: Polyline, traces: ArrayList<Vector>) {
      basketBallConfig?.shotTrailAnimationDelay?.let {
         val delayBetweenEachPoint = (it.times(1000)).toLong()
         var counter = 1
         var animationTimer: Timer? = null
         animationTimer =
            timer("TraceAnimation", false, delayBetweenEachPoint, delayBetweenEachPoint) {
               if (counter < traces.size) {
                  shotTraces.appendPoint(traces[counter])
                  counter++
               } else {
                  animationTimer?.cancel()
               }
            }
      }
   }

   //function to draw and update shot trails
   fun updateShotTrails() {
      if (shotTrailsRootEntity?.childNodes?.size != 0) {
         shotTrailsRootEntity?.removeAllChildNodes()
      }
      val shots = viewModel.gameChroniclesData.value?.getShots
      shots?.let {
         for (shot in shots) {
            if (this.team == shot.tid) {
               //player id -1 means all player shots need to show
               if (this.playerId == shot.pid || this.playerId == -1) {
                  //tot need to show all shots of that player
                  if (this.shotType == shot.st || this.shotType == "tot") {
                     //checks the selected round is enabled or not and fetch traces if it is enabled
                     shot.pe?.let {
                        if (rounds?.contains(it) == true) {
                           val traces = bbShots.convertFromServerFormat(shot.trace)
                           addShotTrail(traces, shot.ma)
                        }
                     }
                  }
               }
            }
         }
      }
      //updateHeatmap()
   }

   private fun addPlayerCard() {
      teamLeaderBoardNode?.isVisible = false
      playerCardNode?.isVisible = true
      basketBallConfig?.arUiView?.experiences?.get(0)?.playerCardConfigurables?.let {
            playerCardConfigurables ->
         if (playerCardNode?.childNodes?.size == 0) {
            playerCardView = createPlayerCardView(context)
         }
         viewModel.sportsData?.getTeams?.let {
            val teamIndex = if (isHomeTeam) {
               0
            } else {
               1
            }
            updatePlayerCardView(
               playerCardView,
               playerCardConfigurables,
               isHomeTeam,
               it[teamIndex],
               this.playerId,
               this.playerName,
               this.shotType,
               this.playerImage,
               viewModel.gameChroniclesData.value
            )
            playerCardNode?.highAccuracyEvents = true
            playerCardNode?.clickListener = object : ClickListener {
               override fun onClick(i: Int, node: Node, vector: Vector) {
                  // Toggle the board location
                  boardLocation = if (boardLocation == USER) {
                     COURTSIDE
                  } else {
                     USER
                  }
                  playerCard?.animation(
                     boardLocation, arViewController.tracker?.viewPosition, true
                  )
               }

               override fun onClickState(
                  i: Int, node: Node, clickState: ClickState, vector: Vector
               ) {
               }
            }
            playerCardView?.let { teamLeaderBoardView ->
               if (playerCardNode?.childNodes?.size == 0) {
                  playerCard = basketballPlayerCardBoardNode(
                     teamLeaderBoardView, arViewController
                  )
                  playerCardNode?.addChildNode(
                     playerCard
                  )
               }
               playerCard?.animation(
                  boardLocation, arViewController.tracker?.viewPosition, isTapped
               )
            }
         }
      }
   }

   private fun addTeamLeaderBoard() {
      teamLeaderBoardNode?.isVisible = true
      playerCardNode?.isVisible = false
      basketBallConfig?.arUiView?.experiences?.get(0)?.leaderBoardConfigurables?.let {
            leaderBoardConfigurables ->
         if (teamLeaderBoardNode?.childNodes?.size == 0) {
            teamLeaderBoardView = createLeaderBoardView(context)
         }
         viewModel.sportsData?.getTeams?.let {
            val teamIndex = if (isHomeTeam) {
               0
            } else {
               1
            }
            updateTeamLeaderBoardView(
               teamLeaderBoardView,
               leaderBoardConfigurables,
               viewModel.gameChroniclesData.value,
               it[teamIndex],
               isHomeTeam,
               context
            )
            teamLeaderBoardNode?.highAccuracyEvents = true
            teamLeaderBoardNode?.clickListener = object : ClickListener {
               override fun onClick(i: Int, node: Node, vector: Vector) {
                  // Toggle the board location
                  boardLocation = if (boardLocation == USER) {
                     COURTSIDE
                  } else {
                     USER
                  }
                  teamLeaderBoard?.animation(
                     boardLocation, arViewController.tracker?.viewPosition, true
                  )
               }

               override fun onClickState(
                  i: Int, node: Node, clickState: ClickState, vector: Vector
               ) {
               }
            }
            teamLeaderBoardView?.let { teamLeaderBoardView ->
               if (teamLeaderBoardNode?.childNodes?.size == 0) {
                  teamLeaderBoard = basketballTeamLeaderBoardNode(
                     teamLeaderBoardView, arViewController
                  )
                  teamLeaderBoardNode?.addChildNode(
                     teamLeaderBoard
                  )
               }
               teamLeaderBoard?.animation(
                  boardLocation, arViewController.tracker?.viewPosition, isTapped
               )
            }
         }
      }
   }

   fun updateHeatmap() {
      if (shotType == "per") {
         //getting heatmap config
         val heatmapConfig = basketBallConfig?.heatmapConfig
         if (heatmapSceneGraphNode?.rootTextEntity?.childNodes?.size != 0) {
            heatmapSceneGraphNode?.rootTextEntity?.removeAllChildNodes()
         }
         heatmapConfig?.let { heatmapConfigArray ->
            CoroutineScope(Dispatchers.IO).launch(Dispatchers.IO) {
               val heatmapsPercentageValues: ArrayList<heatmaps> = arrayListOf()

               //getting heatmap array from basketball data
               val heatmapsData = viewModel.gameChroniclesData.value?.getHeatmaps
               heatmapsData?.let { heatmapDataArray ->

                  // If a player is selected (selectedPlayerID != -1) then show players heat map
                  // info
                  // If a team is selected (self.selectedPlayerID == -1) then show teams heat map
                  // info. Heat map info of the team will have pid = 0
                  for (heatmaps in heatmapDataArray) {
                     val teamId = heatmaps.tid?.toInt()
                     if (teamId == team) {
                        if (((playerId != -1) && (heatmaps.pid == playerId)) || ((playerId == -1) && (heatmaps.pid == 0))) {
                           heatmapsPercentageValues.add(heatmaps)
                        }
                     }
                  }

                  //iterating selected heatmaps for selected pid
                  for (heatmapPercentage in heatmapsPercentageValues) {
                     var heatmapOpacity: Float? = null
                     var heatmapColor: String? = null

                     //getting opasity and color of each zones by comparing heatmap config and heatmap data
                     //from basketball data
                     for (heatmapConfigItem in heatmapConfigArray) {
                        if (heatmapConfigItem.percentage >= heatmapPercentage.pct.toInt()) {
                           heatmapOpacity = heatmapConfigItem.opacity?.toFloat()
                           heatmapColor = heatmapConfigItem.color
                           break
                        }
                     }

                     //setting opacity and colour of each heatmap node based on zone index
                     heatmapPercentage.ci?.let { zoneIndex ->
                        if (zoneIndex <= 13) {
                           heatmapSceneGraphNode?.setZoneColor(
                              zoneIndex, heatmapOpacity, heatmapColor
                           )
                           heatmapSceneGraphNode?.createTextEntity(
                              heatmapPercentage.pct.toInt()
                           )
                        }
                     }
                  }
                  //callback function to get camera position changes
                  arViewController.arView?.setCameraListener { position, rotation, forward ->
                     heatmapSceneGraphNode?.setHeatmapTextNodeHeight(
                        position, heatmapsPercentageValues
                     ) { textEntityPlaced ->
                        if (textEntityPlaced) {
                           addHeatmapBoardEntity(
                              basketBallConfig?.heatmapConfig, position
                           )
                        }
                     }
                  }
               }
            }
         }
         //heatmap only for half court so if hometeam is selected need to rotate
         // heatmapRootEntity to Pi angle else no rotation needed
         if (isHomeTeam) {
            heatmapRootEntity?.setRotation(Vector(0.0, 0.0, Math.PI))
         } else {
            heatmapRootEntity?.setRotation(Vector(0f, 0f, 0f))
         }
         heatmapRootEntity?.isVisible = true
      } else {
         legendBoardNode?.removeAllChildNodes()
         heatmapRootEntity?.isVisible = false
      }
   }

   private fun addHeatmapBoardEntity(heatmapConfig: ArrayList<colors>?, position: Vector) {

      //getting heatmap board positions from basketball data
      val positionA = basketBallConfig?.heatmapBoardPositionA
      val positionB = basketBallConfig?.heatmapBoardPositionB
      positionA?.let { A ->
         positionB?.let { B ->
            legendBoardPositionA = Vector(A[0], A[1], A[2])
            legendBoardPositionB = Vector(B[0], B[1], B[2])
         }
      }

      //converting camera position to local coordinate system
      val camLocalPosition = worldRootEntity?.convertWorldPositionToLocalSpace(position)

      viewModel.sportsData?.let { basketballData ->
         //calculating distance between camera and both heatmap board positions
         camLocalPosition?.let {
            val distancebetweenCamAndPointA = it.distance(legendBoardPositionA)
            val distancebetweenCamAndPointB = it.distance(legendBoardPositionB)

            //comparing distance between points and camera positions
            // heatmap board will show at point with grater distance
            distancebetweenCamAndPointA.let { pointADistance ->
               distancebetweenCamAndPointB.let { pointBDistance ->
                  if (pointADistance > pointBDistance) {
                     if (boardflag != 1 || teamChangeFlag) {
                        teamChangeFlag = false
                        boardflag = 1
                        legendBoardNode?.removeAllChildNodes()
                        val heatmapBoardNode = basketballLegendBoardNode(
                           arViewController.arView,
                           heatmapConfig,
                           basketballData.getTeams,
                           isHomeTeam,
                           context as AppCompatActivity
                        )
                        legendBoardNode?.setPosition(
                           heatmapBoardNode.getSurfaceWidth()?.let { surfaceWidth ->
                                 //legendboard x position = (width of the quad * scale)/2
                                 Vector(
                                    legendBoardPositionA.x + ((surfaceWidth * 30) / 2).toDouble(),
                                    legendBoardPositionA.y.toDouble(),
                                    legendBoardPositionA.z.toDouble()
                                 )
                              })
                        legendBoardNode?.setRotation(Vector(Math.PI / 2, 0.0, 0.0))
                        legendBoardNode?.addChildNode(heatmapBoardNode)
                     } else {
                     }
                  } else {
                     if (boardflag != 2 || teamChangeFlag) {
                        teamChangeFlag = false
                        boardflag = 2
                        legendBoardNode?.removeAllChildNodes()
                        val heatmapBoardNode = basketballLegendBoardNode(
                           arViewController.arView,
                           heatmapConfig,
                           basketballData.getTeams,
                           isHomeTeam,
                           context as AppCompatActivity
                        )
                        legendBoardNode?.setPosition(heatmapBoardNode.getSurfaceWidth()?.let { surfaceWidth ->
                                 //legendboard x position = (width of the quad * scale)/2
                                 Vector(
                                    legendBoardPositionB.x - ((surfaceWidth * 30) / 2).toDouble(),
                                    legendBoardPositionB.y.toDouble(),
                                    legendBoardPositionB.z.toDouble()
                                 )
                              })
                        legendBoardNode?.setRotation(Vector(Math.PI / 2, Math.PI, 0.0))
                        heatmapBoardNode.transformBehaviors =
                           EnumSet.of(Node.TransformBehavior.BILLBOARD_X)
                        legendBoardNode?.addChildNode(heatmapBoardNode)
                     } else {
                     }
                  }
               }
            }
         }
      }
   }

   private fun createHeatmapEntity() {
      CoroutineScope(Dispatchers.IO).launch(Dispatchers.IO) {
         heatmapRootEntity?.isVisible = false
         worldRootEntity?.addChildNode(heatmapRootEntity)
         val heatmapModelFiles = arrayOf(
            "One",
            "Two",
            "Three",
            "Four",
            "Five",
            "Six",
            "Seven",
            "Eight",
            "Nine",
            "Ten",
            "Eleven",
            "Twelve",
            "Thirteen",
            "Forteen"
         )

         //loading heatmap models
         arViewController.arView?.let {
            heatmapSceneGraphNode = basketballHeatMapSceneGraphNode(it.viroContext)
            heatmapSceneGraphNode?.loadModel(heatmapModelFiles)
         }
         //reducing z value by 0.1F to avoid flickering
         heatmapSceneGraphNode?.rootHeatmapEntity?.positionRealtime?.let {
            heatmapSceneGraphNode?.rootHeatmapEntity?.setPosition(
               Vector(
                  it.x, it.y, it.z - 0.1F
               )
            )
         }

         //attaching heatmap node and percentage text node to root heatmap node
         heatmapRootEntity?.addChildNode(heatmapSceneGraphNode?.rootHeatmapEntity)
         heatmapRootEntity?.addChildNode(heatmapSceneGraphNode?.rootTextEntity)
      }
   }

   private fun addShotTrail(traces: ArrayList<Vector>, shotSuccessStatus: Int?) {
      if (this.playerId == -1 || shotSuccessStatus == 1) {
         val traceNode = basketballTracesSceneGraphNode(
            traces, isHomeTeam, basketBallConfig
         )
         val floorTileNode = basketballFloorTileSceneGraphNode(
            traces[0], isHomeTeam, basketBallConfig, shotSuccessStatus
         )
         traceNode.addChildNode(floorTileNode)
         shotTrailsRootEntity?.addChildNode(traceNode)
         startAnimation(traceNode.polyline, traces)
      }
   }

   companion object {
      var Q_NOTIFICATION_ON_TRACKING_UPDATED = "Q_NOTIFICATION_ON_TRACKING_UPDATED"
      var Q_NOTIFICATION_ON_READY_FOR_TRACKING =  "Q_NOTIFICATION_ON_READY_FOR_TRACKING"
   }
}

fun getQuadrant(userLocationVector: Vector): basketballVenue.QUADRANT {
   val _2pi = 2.0 * Math.PI

   // Create a vector from center court to the user's position, project along the x/y plane, normalize to a unit vector
   var userVec = userLocationVector
   userVec.z = 0f
   userVec = userVec.normalize()

   // Find the angle between 0,0, in radians. atan2 will return the absolute angle as +/-pi, but I want between zero and 2*pi
   val theta = (atan2(userVec.y, userVec.x) + _2pi) % _2pi

   // Quantize the angle into an integer in the set [0-3]
   val quadrantInt =
      (((theta + Math.PI / 4) / (Math.PI / 2)).toBigDecimal().setScale(1, RoundingMode.DOWN)
         .toInt()) % 4

   val sample = basketballVenue.QUADRANT.values()[quadrantInt]
   // Return the quadrant (should always succeed)
   return basketballVenue.QUADRANT.values()[quadrantInt]
}
