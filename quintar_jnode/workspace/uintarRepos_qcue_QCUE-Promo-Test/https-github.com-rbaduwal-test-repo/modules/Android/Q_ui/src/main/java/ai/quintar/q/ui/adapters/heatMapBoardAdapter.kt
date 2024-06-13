package ai.quintar.q.ui.adapters

import ai.quintar.q.config.colors
import ai.quintar.q.ui.R
import android.annotation.SuppressLint
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.recyclerview.widget.RecyclerView

class heatmapBoardAdapter(private val list: ArrayList<colors>, private val colorCardWidth: Int) :
   RecyclerView.Adapter<heatmapBoardAdapter.MyView>() {
   inner class MyView(view: View) : RecyclerView.ViewHolder(view) {
      var colorCard: ConstraintLayout = view.findViewById<View>(R.id.colorCard) as ConstraintLayout
      var percentageTextView: TextView = view.findViewById<View>(R.id.percentageText) as TextView
   }

   override fun onCreateViewHolder(
      parent: ViewGroup, viewType: Int
   ): MyView {
      val itemView: View = LayoutInflater.from(parent.context).inflate(
            R.layout.heatmap_board_item_layout, parent, false
         )
      return MyView(itemView)
   }

   @SuppressLint("SetTextI18n")
   override fun onBindViewHolder(
      holder: MyView, position: Int
   ) {
      if (position == 0) {
         holder.percentageTextView.text = "0-" + list[position].percentage.toString() + "%"
      } else {
         holder.percentageTextView.text =
            list[position - 1].percentage.toString()+"-"+list[position].percentage.toString()+ "%"
      }
      holder.colorCard.setBackgroundColor(Color.parseColor(list[position].color.toString()))

      //setting width to color card
      val layoutParams = holder.colorCard.layoutParams
      layoutParams.width = colorCardWidth
      holder.colorCard.layoutParams = layoutParams
   }

   override fun getItemCount(): Int {
      return list.size
   }
}
