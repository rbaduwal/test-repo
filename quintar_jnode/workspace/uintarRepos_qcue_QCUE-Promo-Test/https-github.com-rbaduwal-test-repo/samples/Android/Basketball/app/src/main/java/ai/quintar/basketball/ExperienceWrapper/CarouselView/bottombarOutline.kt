package ai.quintar.basketball.ExperienceWrapper

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.util.TypedValue
import android.view.View

class bottombarView @JvmOverloads constructor(
   context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

   @SuppressLint("DrawAllocation")
   override fun onDraw(canvas: Canvas?) {
      super.onDraw(canvas)
      val paint = Paint()
      val widthhalf = width / 2
      val radius = 42
      val radiusindp = radius.dpToPixels(this)
      paint.color = Color.BLACK
      paint.alpha = 180
      val oval = RectF((widthhalf - radiusindp), -radiusindp, (widthhalf + radiusindp), radiusindp)
      val backgroundPath = Path().apply {
         moveTo(0f, 0f)
         lineTo((widthhalf - radiusindp), 0f)
         arcTo(oval, 180f, -180f, false)
         lineTo(width.toFloat(), 0f)
         lineTo(width.toFloat(), height.toFloat())
         lineTo(0f, height.toFloat())
         close()
      }
      canvas?.drawPath(backgroundPath, paint)
      val borderpaint = Paint()
      borderpaint.color = Color.WHITE
      borderpaint.style = Paint.Style.STROKE
      borderpaint.strokeWidth = 5f
      canvas?.drawLine(0f, 0f, (widthhalf - radiusindp), 0f, borderpaint)
      canvas?.drawArc(oval, 180f, -180f, false, borderpaint)
      canvas?.drawLine((widthhalf + radiusindp), 0f, width.toFloat(), 0f, borderpaint)
   }

   fun Int.dpToPixels(context: bottombarView): Float = TypedValue.applyDimension(
      TypedValue.COMPLEX_UNIT_DIP, this.toFloat(), context.resources.displayMetrics
   )
}