class_name CatFaceSet
extends Resource

## Texture names can be shared across sets, e.g. neutral, sleeping, happy, angry.
@export var textures: Dictionary[String, Texture2D] = {}
@export var default_face: String = "neutral"
## Keys match animation names without their imported prefix, e.g. Armature|Attack -> attack.
@export var animation_faces: Dictionary[String, String] = {
	"idle": "neutral",
	"attack": "attack",
	"hurt": "hurt",
	"sleep": "sleep",
	"death": "hurt",
	"death2": "hurt",
	"pancake": "scared",
}

func get_animation_face(animation: String) -> String:
	var short_name = animation.get_slice("|", animation.get_slice_count("|") - 1).to_lower()
	var face = animation_faces.get(short_name, default_face)
	return face if has_face(face) else default_face

func has_face(face: String) -> bool:
	return textures.get(face) != null

func get_texture(face: String) -> Texture2D:
	return textures.get(face)
