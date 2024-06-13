package ai.quintar.q.utility

import com.google.gson.annotations.SerializedName

@Suppress("ClassName") data class trackingUpdateModel(
   @SerializedName("cam_extrinsics") val cam_extrinsics: List<Double>? = listOf(),
   @SerializedName("camera_model") val cameraModel: String? = "",
   @SerializedName("camera_params") val cameraParams: List<Double>? = listOf(),
   @SerializedName("model_to_world") val model_to_world: List<Double>? = listOf(),
   @SerializedName("model_pose") val model_pose: List<Double>? = listOf(),
   @SerializedName("magnetic_field") val magnetic_field: List<Double>? = listOf(),
   @SerializedName("confidence") val confidence: Double? = 0.0,
   @SerializedName("correction") val correction: List<Double>? = listOf(),
   @SerializedName("debug") val debug: Debug? = Debug(),
   @SerializedName("gravity") val gravity: List<Double>? = listOf(),
   @SerializedName("img_height") val imgHeight: Int? = 0,
   @SerializedName("img_width") val imgWidth: Int? = 0,
   @SerializedName("world_position") val world_position: List<Float>? = listOf(),
   @SerializedName("world_view_direction") val world_view_direction: List<Float>? = listOf())

data class Debug(@SerializedName("childreg") val childreg: Double? = 0.0,
   @SerializedName("db") val db: Double? = 0.0,
   @SerializedName("farDistanceCount") val farDistanceCount: Double? = 0.0,
   @SerializedName("farDistanceThreshold") val farDistanceThreshold: Double? = 0.0,
   @SerializedName("feat") val feat: Double? = 0.0,
   @SerializedName("match") val match: Double? = 0.0,
   @SerializedName("nearDistanceCount") val nearDistanceCount: Double? = 0.0,
   @SerializedName("nearDistanceThreshold") val nearDistanceThreshold: Double? = 0.0,
   @SerializedName("NumObservations") val numObservations: Double? = 0.0,
   @SerializedName("NumVisible3DPoints3D") val numVisible3DPoints3D: Double? = 0.0,
   @SerializedName("recon") val recon: Double? = 0.0,
   @SerializedName("reg") val reg: Double? = 0.0,
   @SerializedName("setup") val setup: Double? = 0.0)