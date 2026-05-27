# map_info.gd
extends Resource
class_name MapInfo

@export var map_name: String
@export_file("*.tscn") var scene_path: String
@export var preview: Texture2D
