package ai.quintar.q.ui.adapters

import ai.quintar.q.config.playerCardConfigurables
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

class playerCardAdapter(
   private var gameLeaderArray: ArrayList<teamLeaders>,
   private var playerCardConfigurables: playerCardConfigurables,
   private var isHomeTeam: Boolean
) : RecyclerView.Adapter<playerCardAdapter.MyView>() {
   inner class MyView(view: View) : RecyclerView.ViewHolder(view) {
      var endtitle: TextView = view.findViewById(R.id.endtitle)
      var scr: TextView = view.findViewById(R.id.scr)
      var divider: View = view.findViewById(R.id.divider)
   }

   override fun onCreateViewHolder(
      parent: ViewGroup, viewType: Int
   ): MyView {
      val itemView: View = LayoutInflater.from(parent.context).inflate(
            R.layout.player_card_item, parent, false
         )
      return MyView(itemView)
   }

   @SuppressLint("SetTextI18n")
   override fun onBindViewHolder(
      holder: MyView, position: Int
   ) {
      //setting playercard configurables
      if (isHomeTeam) {
         playerCardConfigurables.colors?.homeTeam?.scr?.let {
            holder.scr.setTextColor(Color.parseColor(it))
         }
         playerCardConfigurables.colors?.homeTeam?.highlight?.let {
            holder.divider.setBackgroundColor(Color.parseColor(it))
         }
         playerCardConfigurables.colors?.homeTeam?.endTitle?.let {
            holder.endtitle.setTextColor(Color.parseColor(it))
         }
      } else {
         playerCardConfigurables.colors?.awayTeam?.scr?.let {
            holder.scr.setTextColor(Color.parseColor(it))
         }
         playerCardConfigurables.colors?.awayTeam?.highlight?.let {
            holder.divider.setBackgroundColor(Color.parseColor(it))
         }
         playerCardConfigurables.colors?.awayTeam?.endTitle?.let {
            holder.endtitle.setTextColor(Color.parseColor(it))
         }
      }
      holder.endtitle.textSize = playerCardConfigurables.endTitleSize.toFloat() * constants.playerCardBoardSize
      holder.scr.textSize = playerCardConfigurables.scrSize.toFloat() * constants.playerCardBoardSize

      //setting list contents
      playerCardConfigurables.endTitle?.let {
         holder.endtitle.text = it
      }
      holder.scr.text =
         gameLeaderArray[position].scr.toString() + " " + gameLeaderArray[position].cat.toString()

      //removing divider for last item
      if (position == gameLeaderArray.size - 1) {
         holder.divider.visibility = View.INVISIBLE
      }
   }

   override fun getItemCount(): Int {
      return gameLeaderArray.size
   }
}