class_name ArtDirectionSystem
extends RefCounted

const MANIFEST_PATH := "res://data/art/phase22_manifest.json"

static func manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Dictionary if parsed is Dictionary else {}

static func asset(asset_id: String) -> Dictionary:
	for raw_entry in manifest().get("assets", []) as Array:
		var entry := raw_entry as Dictionary
		if str(entry.get("id", "")) == asset_id:
			return entry
	return {}

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var data := manifest()
	if data.is_empty():
		return ["No se puede leer el manifiesto de arte de la fase 22."]
	var ids: Array[String] = []
	for raw_entry in data.get("assets", []) as Array:
		var entry := raw_entry as Dictionary
		var asset_id := str(entry.get("id", ""))
		var path := str(entry.get("path", ""))
		if asset_id.is_empty() or asset_id in ids:
			errors.append("Identificador artístico vacío o duplicado: %s." % asset_id)
		else:
			ids.append(asset_id)
		if not ResourceLoader.exists(path):
			errors.append("Falta el recurso artístico %s." % path)
		if str(entry.get("license", "")).is_empty() or str(entry.get("prompt_summary", "")).is_empty():
			errors.append("%s no documenta procedencia." % asset_id)
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.is_empty():
			errors.append("%s no se puede decodificar." % asset_id)
			continue
		if image.get_width() < int(entry.get("min_width", 1)) or image.get_height() < int(entry.get("min_height", 1)):
			errors.append("%s no alcanza su resolución de producción." % asset_id)
		if bool(entry.get("requires_alpha", false)) and image.detect_alpha() == Image.ALPHA_NONE:
			errors.append("%s necesita transparencia real." % asset_id)
	return errors
