package ai.quintar.sandbox

import android.content.Context

class preferences(context: Context) {
    private val context = context

    fun setTestmodeEnable(testModeEnable: Boolean) {
        val editor = context.getSharedPreferences("sandbox", Context.MODE_PRIVATE).edit()
        editor.putBoolean("testModeEnable", testModeEnable)
        editor.apply()
    }

    fun getTestmodeEnable(): Boolean {
        return context.getSharedPreferences("sandbox", Context.MODE_PRIVATE)
            .getBoolean("testModeEnable", true)
    }
}