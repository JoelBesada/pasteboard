### 
# Modal window module, displays a
# modal window with the given content 
###
modalWindow = (pasteboard) ->
	TEMPLATE_URL = "jstemplates/modalwindow.tmpl"
	templateDefaults =
		title: ""
		content: ""
		showCancel: false
		showClose: false
		showConfirm: false
		showLink: false
		confirmText: "OK"
		cancelText: "Cancel"
		closeText: "Close"
		linkText: ""

	$document = $ document
	$window = $ window
	$modal = null
	$modalWindow = null

	setPosition = () ->
		top = Math.max 50, $window.outerHeight() / 2 - $modalWindow.outerHeight() / 2
		$modalWindow.css 
			top: top

	self = 
		init: () ->
			pasteboard.template.load TEMPLATE_URL

		# Displays the modal window of the given type.
		# Compiles the modal window template using the params
		show: (modalType, params, callback) ->
			self.hide() if $modal?
			pasteboard.template.compile(
				TEMPLATE_URL,
				$.extend({modalType: modalType}, templateDefaults, params),
				(compiledTemplate) =>
					$modal = $ compiledTemplate
					$modalWindow = $modal.find(".modal-window")
					
					$("body").append $modal
					setPosition()

					# Events
					$window.on "resize.modalwindowevents", setPosition
					$document.on("click.modalwindowevents", 
							".modal-window .cancel", () -> $(self).trigger("cancel"))
							.on("click.modalwindowevents", 
							".modal-window .confirm", () -> $(self).trigger("confirm"))
							.on("click.modalwindowevents",
							".modal-window .close", () -> self.hide())

					if params.showClose 
						# Allow clicking outside to close
						$document.on("click.modalwindowevents", () -> self.hide())
							.on("click.modalwindowevents", ".modal-window", (e) -> e.stopPropagation())

					callback $modal if callback
			)

		hide: () ->
			$modalWindow.transition(
				opacity: 0
				scale: 0.85
			, 300)

			currentModal = $modal;
			currentModal.transition(
				opacity: 0
			, 500, () ->
				currentModal.remove()
				currentModal = null
			)

			$document.off ".modalwindowevents"
			$window.off ".modalwindowevents"


window.moduleLoader.addModule "modalWindow", modalWindow
