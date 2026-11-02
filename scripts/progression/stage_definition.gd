class_name StageDefinition
extends Resource

## Stable content ID, independent of the node's position on the route map.
@export var stage_id: StringName
@export var display_name: String = "Stage"
@export_color_no_alpha var color: Color = Color("b0c991")
@export var environment_scene: PackedScene
@export var spawn_rules: StageSpawnRules
