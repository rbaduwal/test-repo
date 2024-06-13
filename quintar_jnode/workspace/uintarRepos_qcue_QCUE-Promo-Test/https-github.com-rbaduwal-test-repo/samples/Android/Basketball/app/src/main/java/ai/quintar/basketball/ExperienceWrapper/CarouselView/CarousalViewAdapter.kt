package ai.quintar.basketball.ExperienceWrapper.CarouselView

import ai.quintar.basketball.R
import ai.quintar.q.sportData.players
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.mikhaellopez.circularimageview.CircularImageView

class carousalViewAdapter(private var players: ArrayList<players>, private var colour: String) :
   RecyclerView.Adapter<carousalViewAdapter.ViewHolder>() {

   class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
      val image: CircularImageView = itemView.findViewById(R.id.player_image)

   }

   override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
      val inflater = LayoutInflater.from(parent.context)
         .inflate(R.layout.carousal_view_item_layout, parent, false)
      return ViewHolder(inflater)
   }

   override fun getItemCount(): Int {
      return players.size
   }

   override fun onBindViewHolder(holder: ViewHolder, position: Int) {
      holder.image.borderColor = Color.parseColor(colour)
      Glide.with(holder.image).load(players[position].hs).circleCrop().into(holder.image)
   }

   fun updateData(list: ArrayList<players>, colour: String) {
      this.players = list
      this.colour = colour
      notifyDataSetChanged()
   }
}