package ai.quintar.q.ui.basketball

import com.viro.core.Vector

class basketballShots() {
   fun convertFromServerFormat(points: ArrayList<Double>): ArrayList<Vector> {
      val traces: ArrayList<Vector> = ArrayList()

      // Check whether count is multiple of 3 (X,Y,Z)
      if (points.size % 3 != 0) {
         return traces
      }
      val numPoints = points.size / 3

      // Points are in the order all X, then Y and Z after that
      // [X0, X1, X2,.....,XN, Y0, Y1, Y2,.....,YN, Z0, Z1, Z2,.....,ZN]
      for (index in 0 until numPoints) {
         val traceVector = Vector()
         val yIndex = index + numPoints
         val zIndex = index + (2 * numPoints)
         traceVector.set(
            points[index].toFloat(),
            points[yIndex].toFloat(),
            points[zIndex].toFloat()
         )
         traces.add(traceVector)
      }
      return traces
   }
}