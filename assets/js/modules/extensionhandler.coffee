###
# Extension handler module, listens to messages posted
# from the browser extension
###

extensionHandler = (pasteboard) ->
  {
    init: () ->
      $(window).on "extensionimageloaded", (e, data) ->
        return unless data.imageData
        pasteboard.fileHandler.readData data.imageData, extension: true
  }

window.moduleLoader.addModule "extensionHandler", extensionHandler