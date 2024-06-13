package ai.quintar.q.ui.adapters

import ai.quintar.q.config.leaderBoardConfigurables
import ai.quintar.q.sportData.basketball.basketballGameChronicles.teamLeaders
import ai.quintar.q.ui.R
import ai.quintar.q.ui.constants
import android.annotation.SuppressLint
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.mikhaellopez.circularimageview.CircularImageView

class teamLeaderBoardAdapter(
   private val leaderboard: ArrayList<teamLeaders>,
   private val leaderBoardConfigurables: leaderBoardConfigurables,
   private val isHomeTeam: Boolean,
   private val highlightColor: String?
) : RecyclerView.Adapter<teamLeaderBoardAdapter.MyView>() {
   inner class MyView(view: View) : RecyclerView.ViewHolder(view) {
      var playerimage: CircularImageView = view.findViewById(R.id.playerimage)
      var playername: TextView = view.findViewById(R.id.playername)
      var points: TextView = view.findViewById(R.id.points)
   }

   override fun onCreateViewHolder(
      parent: ViewGroup, viewType: Int
   ): MyView {
      val itemView: View = LayoutInflater.from(parent.context).inflate(
            R.layout.leader_board_item_layout, parent, false
         )
      return MyView(itemView)
   }

   @SuppressLint("SetTextI18n")
   override fun onBindViewHolder(
      holder: MyView, position: Int
   ) {
      //setting player image,text and score value
      Glide.with(holder.playerimage).load(leaderboard[position].hs).circleCrop()
         .placeholder(R.drawable.placeholder).into(holder.playerimage)
      holder.playername.text = leaderboard[position].sn?.uppercase()
      holder.points.text = leaderboard[position].scr.toString() + " " + leaderboard[position].cat
      //setting size,color from leaderBoardConfigurables
      holder.points.textSize = leaderBoardConfigurables.scrSize.toFloat() * constants.teamLeaderBoardSize
      holder.playername.textSize = leaderBoardConfigurables.nameSize.toFloat() * constants.teamLeaderBoardSize
      holder.playerimage.borderColor = Color.parseColor(highlightColor)
      holder.playerimage.borderWidth = 2.0F
      if (isHomeTeam) {
         leaderBoardConfigurables.colors?.hometeam?.name?.let {
            holder.playername.setTextColor(Color.parseColor(it))
         }
         leaderBoardConfigurables.colors?.hometeam?.scr?.let {
            holder.points.setTextColor(Color.parseColor(it))
         }
      } else {
         leaderBoardConfigurables.colors?.awayTeam?.name?.let {
            holder.playername.setTextColor(Color.parseColor(it))
         }
         leaderBoardConfigurables.colors?.awayTeam?.scr?.let {
            holder.points.setTextColor(Color.parseColor(it))
         }
      }
   }

   override fun getItemCount(): Int {
      return leaderboard.size
   }
}