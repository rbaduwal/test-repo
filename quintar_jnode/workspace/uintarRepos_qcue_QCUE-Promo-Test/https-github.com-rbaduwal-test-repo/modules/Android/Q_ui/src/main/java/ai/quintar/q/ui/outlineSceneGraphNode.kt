package ai.quintar.q.ui

import ai.quintar.q.config.outlines
import android.graphics.Color
import com.viro.core.Material
import com.viro.core.Node
import com.viro.core.Polyline
import com.viro.core.Vector
import java.util.*

@Suppress("ClassName") class outlineSceneGraphNode(points: ArrayList<Vector>,
   private var outline: outlines) : Node() {
   private var points: ArrayList<Vector> = ArrayList()
   lateinit var polyline: Polyline

   init {
      this.points = points
      createLine()
   }

   private fun createLine() {
      polyline = Polyline(points, outline.radius.toFloat())
      val material = Material()
      material.diffuseColor = Color.parseColor(outline.color)
      material.transparencyMode = Material.TransparencyMode.A_ONE
      material.lightingModel = Material.LightingModel.PHONG
      material.blendMode = Material.BlendMode.ALPHA
      material.cullMode = Material.CullMode.BACK
      polyline.materials = Arrays.asList(material)
      val polylineNode = Node()
      polylineNode.geometry = polyline
      polylineNode.opacity = outline.opacity.toFloat()
      this.addChildNode(polylineNode)
   }
}
