class_name ImageBox
extends TextBox


func setup(image_path: String, _is_you: bool):
	assert(!_is_setup, "Cannot set up multiple times")

	$Box/Label.add_image(ImageTexture.create_from_image(Image.load_from_file(image_path)))
	$Tail/TailMe.hide()
	$Tail/TailYou.hide()
	_is_setup = true

func clip_to_text(): pass
