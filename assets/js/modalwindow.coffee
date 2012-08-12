### 
# Modal window module, displays a
# modal window with the given content 
###
modalWindow = (pasteboard) ->
	TEMPLATE_URL = "jstemplates/modalwindow.tmpl"
	templateDefaults =
		title: ""
		content: ""

	$document = $ document
	$window = $ window
	$modal = null
	$modalWindow = null

	setPosition = () ->
		$modalWindow.css 
			top: $window.outerHeight() / 2 - $modalWindow.outerHeight() / 2

	self = 
		init: () ->
			pasteboard.template.load TEMPLATE_URL

		# Displays the modal window of the given type.
		# Compiles the modal window template using the params
		show: (modalType, params, callback) ->
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
					$document.on "click.modalwindowevents", ".modal-window .cancel, .modal-window .confirm", @hide
					
					callback $modal if callback
			)

		hide: () ->
			$modalWindow.transition(
				opacity: 0
				scale: 0.85
			, 300)
			$modal.transition(
				opacity: 0
			, 500, () ->
				$modal.remove()
			)
			$document.off ".modalwindowevents"
			$window.off "modalwindowevents"


window.moduleLoader.addModule "modalWindow", modalWindow
