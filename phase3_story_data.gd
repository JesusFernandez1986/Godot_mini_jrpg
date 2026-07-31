class_name Phase3StoryData
extends RefCounted

const NPCS := [
	{"id":"captain","name":"CAPITANA ELARA","role":"Guardia del León","position":Vector2(477,180),"quest":"echoes_below","lines":[["Elara","Las campanas bajo la plaza han vuelto a sonar. No las oye el oído, Aren: las oye el juramento."],["Aren","Entonces alguien ha tocado la piedra que sellaron nuestros abuelos."],["Elara","Baja a las catacumbas. Enciende los sellos gemelos y averigua quién reclama la corona de los muertos."]]},
	{"id":"archivist","name":"MAESE OREN","role":"Archivero real","position":Vector2(304,255),"quest":"lost_ledger","lines":[["Oren","Perdí un libro donde ningún libro debería poder perderse."],["Lyra","Eso suena menos a descuido y más a una advertencia."],["Oren","El Registro de los Canteros quedó en la cripta. Tráelo y sabremos quién abrió la puerta."]]},
	{"id":"healer","name":"HERMANA INÉS","role":"Sanadora","position":Vector2(605,253),"quest":"moonleaf_remedy","lines":[["Inés","Los mineros sueñan con una melena de piedra que los llama por su nombre."],["Aren","¿Puedes aliviarles?"],["Inés","Con hoja lunar de las galerías húmedas. Tráeme una y haré medicina para todos."]]},
	{"id":"guard","name":"SARGENTO DARIO","role":"Centinela","position":Vector2(773,304),"quest":"sentry_oath","lines":[["Dario","Mis reclutas mantienen la puerta, pero las alimañas ya conocen el olor del miedo."],["Aren","Limpiaré las primeras cámaras."],["Dario","Derriba a tres criaturas y mis soldados podrán asegurar la ruta."]]},
	{"id":"blacksmith","name":"NARA","role":"Herrera","position":Vector2(203,329),"quest":"","lines":[["Nara","El hierro canta distinto desde anoche. Cada espada apunta sola hacia la montaña."],["Brom","El metal recuerda las manos que lo forjaron. Y también las que lo traicionaron."]]},
	{"id":"baker","name":"TOMÁS","role":"Panadero","position":Vector2(358,363),"quest":"","lines":[["Tomás","He cocido pan para los guardias. Llévate el olor contigo; a veces basta para recordar el camino a casa."],["Aren","Volveremos antes de que se enfríe la segunda hornada."]]},
	{"id":"child","name":"MARA","role":"Aprendiz de cronista","position":Vector2(518,334),"quest":"","lines":[["Mara","Mi abuela dice que el león de piedra despierta cuando un rey olvida que también fue niño."],["Lyra","Tu abuela sabe más historia que muchos consejeros."]]},
	{"id":"mason","name":"GUIL","role":"Maestro cantero","position":Vector2(648,374),"quest":"","lines":[["Guil","Esas bóvedas no sostienen la ciudad. La ciudad las mantiene dormidas con su peso."],["Aren","Hoy tendremos que pedirles que despierten sin derrumbarnos."]]},
	{"id":"veteran","name":"RODERIC","role":"Veterano","position":Vector2(792,423),"quest":"","lines":[["Roderic","Vi al Caballero Perjuro cuando aún tenía rostro. Se negó a abandonar a su rey incluso cuando el rey abandonó al pueblo."],["Aren","Un juramento sin elección termina siendo una cadena."]]},
	{"id":"minister","name":"ALMA","role":"Ministra de las campanas","position":Vector2(145,421),"quest":"","lines":[["Alma","Cada campana de Valdoria guarda un nombre. Si oyes el tuyo bajo tierra, no respondas."],["Seris","Los nombres son puertas. Esta vez llamaremos nosotros primero."]]}
]

const DUNGEON_INTRO := [["Lyra","Aquí abajo la luz no proyecta sombras: proyecta recuerdos."],["Aren","Manteneos cerca. Activaremos los sellos y volveremos juntos."],["Voz bajo la piedra","Juntos... la palabra favorita de quienes aún no han sido puestos a prueba."]]
const MINIBOSS_INTRO := [["Caballero Perjuro","Custodié una corona cuando la ciudad olvidó a su rey. ¿Qué custodias tú, muchacho?"],["Aren","A quienes nunca tendrán corona, pero sí un nombre."],["Caballero Perjuro","Entonces mide tu promesa contra mi espada."]]
const BOSS_INTRO := [["León Hueco","Valdoria construyó sus hogares sobre mi tumba y llamó paz a mi silencio."],["Lyra","Vharos te presta voz para convertir una herida en hambre."],["Aren","No vengo a borrar tu dolor. Vengo a impedir que lo hereden los vivos."],["León Hueco","Demuestra que una ciudad merece recordar."]]
const RETURN_LINES := [["Elara","Las campanas han callado. Pero esta vez la plaza recuerda por qué sonaban."],["Aren","El León no pedía un rey. Pedía que Valdoria reconociera a quienes enterró sin nombre."],["Oren","El registro contiene trescientos doce nombres borrados de la piedra."],["Mara","Entonces los leeremos todos. Uno por uno."],["Lyra","Así se vence a Vharos: no destruyendo el pasado, sino devolviéndole voz."],["Elara","Aren, acepta el Emblema del León Despierto. No es una medalla: es una deuda que elegimos compartir."]]
const CLOSING_LINES := [["Narrador","Al amanecer, trescientas doce campanadas cruzaron Valdoria."],["Narrador","En cada puerta ardió una lámpara. En cada mesa quedó un lugar vacío para quienes levantaron la ciudad y fueron olvidados."],["Aren","Una victoria no cierra una historia. Solo decide quién tendrá derecho a contar el siguiente capítulo."],["Lyra","Y esta vez no lo escribirá un rey a solas."],["Narrador","Bajo la plaza, el león de piedra cerró los ojos. No para dormir, sino para escuchar."]]

static func npc_by_interaction(interaction_id: String) -> Dictionary:
	var npc_id := interaction_id.trim_prefix("npc_")
	for npc in NPCS:
		if str(npc["id"]) == npc_id:
			return npc
	return {}

static func dialogue_count() -> int:
	var total := DUNGEON_INTRO.size() + MINIBOSS_INTRO.size() + BOSS_INTRO.size() + RETURN_LINES.size() + CLOSING_LINES.size()
	for npc in NPCS:
		total += (npc["lines"] as Array).size()
	return total
