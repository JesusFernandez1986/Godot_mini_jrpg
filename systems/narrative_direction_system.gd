class_name NarrativeDirectionSystem
extends RefCounted

const EXPRESSION_COLORS := {
	"neutral":Color("d7e5ed"), "happy":Color("ffe39a"), "hopeful":Color("aef5cf"),
	"determined":Color("ffbf78"), "worried":Color("b8d5ff"), "sad":Color("9eb5d4"),
	"annoyed":Color("ff9f91"), "surprised":Color("e6bdff")
}
const CONSEQUENCE_LABELS := {"council_path":"decisión del consejo", "people_hope":"esperanza", "valor":"valor"}
const CONSEQUENCE_VALUES := {"truth":"verdad", "mercy":"misericordia", "shared":"compartida", "guarded":"custodiada", "released":"liberada"}

static func expression_color(expression: String) -> Color:
	return EXPRESSION_COLORS.get(expression, EXPRESSION_COLORS["neutral"]) as Color

static func choice_hint(choice: Dictionary) -> String:
	var effects: Array = choice.get("effects", []) as Array
	if effects.is_empty(): return "[sin cambio inmediato]"
	var hints: Array[String] = []
	for effect in effects:
		var operation := str((effect as Dictionary).get("op", ""))
		var raw_key := str(effect.get("key", "decisión"))
		var label := str(CONSEQUENCE_LABELS.get(raw_key, raw_key.replace("_", " ")))
		if operation == "inc": hints.append("%s %+d" % [label, int(effect.get("value", 1))])
		elif operation == "set": hints.append("%s: %s" % [label, str(CONSEQUENCE_VALUES.get(str(effect.get("value", "")), effect.get("value", "")))])
		elif operation == "codex": hints.append("códice")
		elif operation.begins_with("quest_"): hints.append("misión")
	return "[%s]" % ", ".join(hints) if not hints.is_empty() else "[consecuencia narrativa]"

static func apply_choice_bond(hero_state: Dictionary, party: Array, speaker_name: String, choice: Dictionary) -> String:
	var speaker_id := ""
	var leader_id := ""
	for member in party:
		if not member is Dictionary: continue
		if leader_id.is_empty() and bool(member.get("active", false)): leader_id = str(member.get("id", ""))
		if str(member.get("name", "")).to_lower() == speaker_name.to_lower(): speaker_id = str(member.get("id", ""))
	if speaker_id.is_empty() or leader_id.is_empty() or speaker_id == leader_id: return ""
	var bond_key := HeroStorySystem.canonical_bond(leader_id, speaker_id)
	var strength := 2 if (choice.get("effects", []) as Array).size() >= 2 else 1
	var bonds: Dictionary = hero_state.get("bonds", {}) as Dictionary
	bonds[bond_key] = int(bonds.get(bond_key, 0)) + strength
	hero_state["bonds"] = bonds
	return bond_key

static func relationship_recap(hero_state: Dictionary) -> String:
	var bonds: Dictionary = hero_state.get("bonds", {}) as Dictionary
	if bonds.is_empty(): return "Los vínculos del grupo todavía están naciendo."
	var strongest_key := ""
	var strongest_value := -1
	for key in bonds:
		if int(bonds[key]) > strongest_value:
			strongest_key = str(key)
			strongest_value = int(bonds[key])
	return "Vínculo más fuerte: %s · rango %d" % [strongest_key.replace("+", " / ").capitalize(), strongest_value]

static func validate() -> Array[String]:
	var errors: Array[String] = []
	for expression in ["neutral", "happy", "hopeful", "determined", "worried", "sad", "annoyed", "surprised"]:
		if not EXPRESSION_COLORS.has(expression): errors.append("Expresión sin dirección cromática: %s" % expression)
	return errors
