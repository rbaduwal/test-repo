package ai.quintar.q.utility

class errorMessages {
   companion object {
      const val invalidUrlError = "Invalid Url"
      const val parseError = "Failed to parse data"
      const val invalidCorrectionMatrix = "Failed to get correction matrix from the server."
      const val invalidConfidenceValue = "Failed to get confidence value from the server."
      const val timeOutMessage = "The request timed out."
      const val failedTempTracking = "Failed to save temp tracking data to file."
      const val failedToDeserialize = "Failed to convert the JSON data to model class."
      const val fileNotFound = "File not found"
      const val failedToGetImage = "Failed to get image from the file."
   }

}