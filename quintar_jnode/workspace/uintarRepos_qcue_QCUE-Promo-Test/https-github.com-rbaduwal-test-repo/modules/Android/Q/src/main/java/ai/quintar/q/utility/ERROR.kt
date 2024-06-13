package ai.quintar.q.utility

enum class ERROR {
   NONE,
   CONNECTION,
   PARSE,
   REGISTRATION,
   TRACKING,
   TRACKING_RESET,
   TRACKING_DEVICE_NOT_READY,
   URL_NOT_FOUND,
   INIT,
   ERROR_CONDITION,
   INVALID_PARAM;

   fun statusMessage(error: ERROR): String {
      return when (error) {
         NONE -> ""
         CONNECTION -> "Connection error"
         PARSE -> "Parse error"
         REGISTRATION -> "Registration error"
         TRACKING -> "Tracking error"
         TRACKING_RESET -> "Tracking reset"
         TRACKING_DEVICE_NOT_READY -> "Tracking device is not ready"
         URL_NOT_FOUND -> "URL is not found"
         INIT -> "INIT"
         ERROR_CONDITION -> "Error in conditions"
         INVALID_PARAM -> "Invalid param"
      }
   }
}