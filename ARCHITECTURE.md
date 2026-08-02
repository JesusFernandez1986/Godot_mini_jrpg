# Arquitectura de Crónicas del Cristal

## Objetivo

La base técnica separa contenido, reglas de dominio, persistencia, navegación y presentación. Una nueva ciudad, misión o personaje puede añadirse sin modificar sistemas no relacionados.

## Capas

- `data/`: definiciones `Resource` editables de personajes, objetos, equipo, enemigos, localizaciones y misiones; escenas ramificadas, ciudades vivas y los 32 capítulos personales residen en JSON.
- `systems/`: reglas deterministas de inventario, equipamiento, fabricación, progresión, narrativa, historias de héroes, mazmorras, bestiario, comercio, facciones, endgame, logros, accesibilidad, diálogo, viaje, mundo explorable, ciudades vivas, combate individual y de grupo, animación y cámara.
- `world/`: controlador físico del santuario, `CharacterBody2D`, capa de tiles, navegación, obstáculos e interacciones.
- `core/`: navegación de estados, ajustes persistentes y registro estructurado.
- `ui/`: primitivas compartidas de paneles, barras, texto y sprites animados.
- `save_system.gd`: tres ranuras, autoguardado, checksum, backup, escritura atómica y migraciones.
- `main.gd`: orquestación, entrada del usuario y composición de las pantallas actuales.
- `tests/`: pruebas unitarias y recorrido de integración completo.

## Estados de navegación

`SceneRouter` admite estos estados:

```text
title -> settings | save_menu | load_menu | dialogue
dialogue -> world_map | city | valdoria_explore | dungeon | victory
world_map -> city | landmark | explore | valdoria_explore | battle | game_menu
city -> dialogue | world_map | game_menu
landmark -> dungeon_crawl | world_map | game_menu
dungeon_crawl -> battle | landmark | game_menu
explore | valdoria_explore | dungeon -> battle | game_menu
battle -> explore | dungeon | dialogue
game_menu -> settings | save_menu | load_menu | estado anterior
```

Cada cambio genera una entrada estructurada de log y un fundido breve.

## Persistencia

- Formato actual: versión 16.
- Ranuras manuales: `user://saves/slot_1.json` a `slot_3.json`.
- Autoguardado: `user://saves/autosave.json`.
- Cada archivo incluye metadatos, payload y checksum SHA-256.
- La escritura usa un temporal y rota la versión anterior a `.bak` antes de publicar la nueva.
- Si el archivo principal falta o no supera el checksum, se intenta recuperar `.bak`.
- Las partidas v1–v15 migran secuencialmente a v16. Las migraciones añaden orientación, interacciones, vertical slice, afinidades, Resonancia, estadísticas base, equipo, talentos, trabajos, formación, códice, decisiones, escenas activas, posición mundial, tiempo, clima, campamentos, transporte marítimo, ciudades vivas, mazmorras multinivel, ocho protagonistas, capítulos personales, vínculos, epílogos, bestiario, comercio, facciones, endgame, logros y accesibilidad sin invalidar ranuras anteriores.

Los estados de equipo, avance, narrativa, bestiario, comercio, facciones, endgame y finalización son contratos persistentes validados al cargar. Los personajes conservan estadísticas base separadas de las efectivas; al cargar o cambiar una configuración, `EquipmentSystem.refresh_party_stats(...)` reconstruye el resultado y aplica límites seguros.

## Combate de grupo

`PartyBattleSystem` es una máquina de estado determinista separada de la presentación. Mantiene los cuatro aliados activos, cola de iniciativa, escudo de ruptura, Resonancia, estados alterados, fase/patrón enemigo, resultado, registro y botín.

`main.gd` solo traduce entrada y salida: presenta el orden de turnos, los ocho comandos, las afinidades y la intención enemiga; después sincroniza PV, animaciones, recompensas y retorno a la exploración. Los datos de velocidad, arma, elemento, debilidades, resistencias, escudo, patrones y botín residen en recursos `.tres`.

Las simulaciones llaman al mismo sistema que la partida real. Esto permite ejecutar miles de batallas sin renderizado y validar que ninguna queda bloqueada ni produce PV, escudos o Resonancia fuera de rango.

## Equipamiento y progresión

`EquipmentDefinition` describe ranura, rareza, compatibilidad, bonificaciones, pasiva, receta y límite de mejora. `EquipmentSystem` controla propiedad, piezas equipadas, comparación, fabricación, mejoras y estadísticas efectivas.

`AdvancementSystem` contiene el catálogo de artes, trabajos, formaciones y árboles de talentos. El combate recibe en cada miembro el arte seleccionada y las pasivas activas, por lo que las simulaciones y la partida utilizan exactamente las mismas reglas.

## Narrativa externa

`NarrativeSystem` carga `data/dialogues/phase6_dialogues.json` y ejecuta un grafo de nodos con condiciones, elecciones, efectos, misiones y desbloqueos de códice. El estado guarda escena/nodo activo, variables, elecciones, escenas completadas y conversaciones vistas.

`DialogueSystem` sigue aceptando las parejas lineales de las fases anteriores y también nodos estructurados. `main.gd` usa sus metadatos para retratos, expresiones, cámara, movimiento y señales musicales. El contenido se valida comprobando referencias y alcanzabilidad de todas las ramas.

## Mundo explorable

`WorldExplorationSystem` mantiene posición, reloj, día, clima por región, localizaciones descubiertas/cartografiadas, campamentos, viaje rápido, barco, peligros y retornos seguros. Su grafo de rutas permite validar que todos los destinos son alcanzables con los requisitos correctos. El mapa impide atravesar límites, cordilleras y el corredor marítimo antes de desbloquear el transporte.

Los encuentros visibles usan el mismo `PartyBattleSystem` que mazmorras y guardianes. Al vencer se registra un tiempo de reaparición y se regresa al mapa o a la localización exacta; una derrota devuelve al último refugio sin perder progreso.

## Ciudades vivas

`CityLifeSystem` carga `data/cities/phase8_cities.json`. El archivo define barrios, interiores, servicios, habitantes, horarios, líneas por etapa argumental, rumores, conflictos, música, ambientación y actividades características.

`city_life_state` persiste barrio e interior actuales, conversaciones, rumores, resoluciones políticas, puntuaciones, recompensas y servicios usados. Las pruebas calculan al menos treinta minutos de contenido distinto por ciudad y recorren las cuatro franjas horarias sin depender del renderizado.

## Mazmorras multinivel

`DungeonExplorationSystem` define seis mazmorras y tres layouts de tiles verificables. Su estado conserva planta, casilla, automapa, llaves, mecanismos, puzles, cofres, trampas, atajos, minijefes, jefes secretos y finalización. La búsqueda en anchura comprueba que cada entrada mantiene una ruta hasta la salida sin depender de objetos o secretos opcionales.

Los ocho poderes de campo se obtienen directamente del grupo reclutado. Un puzle que requiere una capacidad ausente informa del requisito, pero nunca bloquea la ruta principal. `main.gd` compone los tiles como diamantes para la vista isométrica y traduce encuentros opcionales al mismo `PartyBattleSystem` usado en el resto del juego.

## Ocho protagonistas

`HeroStorySystem` carga `data/stories/phase10_heroes.json`. El contrato exige ocho héroes, cuatro capítulos por héroe, conflicto, antagonista, jefe, seis historias cruzadas y un final común. `hero_story_state` persiste capítulos, resultados, reclutamientos, vínculos, conversaciones cruzadas, decisión final y ocho epílogos variables.

El roster separa `joined` de `active`: pueden reclutarse ocho protagonistas, pero solo cuatro entran en combate. Los cuatro nuevos recursos `CharacterDefinition` reutilizan el atlas direccional con bloques seguros y paletas propias; `assets/phase10_party.png` aporta retratos diferenciados para diálogo y menú.

## Sistemas finales

`BestiarySystem` genera un catálogo estable de 32 entradas, registra observación/análisis/derrota, aplica ocho afijos de élite y mantiene doce contratos. Las variantes siguen entregando un diccionario compatible con `PartyBattleSystem`.

`CommerceSystem` mantiene cuatro mercados, demanda, reputación, reposición y nodos de recolección. Solo entrega identificadores existentes en `GameDatabase`, por lo que inventario y equipo conservan sus contratos.

`FactionSystem` define cuatro facciones y 24 misiones de tres etapas. El diario consume sus entradas igual que las misiones personales y `main.gd` traduce cada etapa a una escena de diálogo persistente.

`EndgameSystem` compone 25 pruebas, ocho superjefes, dificultades y ciclos NG+. Escala copias de los enemigos en ejecución sin modificar sus recursos base. `CompletionSystem` sincroniza 40 logros desde una instantánea de progreso, conserva accesibilidad/idioma y ejecuta la auditoría cruzada de los estados finales.

## Movimiento y presentación

`CharacterAnimationSystem` selecciona regiones del atlas de forma determinista según personaje, estado, dirección y tiempo. Los índices 4–7 reutilizan de forma modular los cuatro bloques de movimiento y aplican paletas propias, mientras los retratos de alta definición siguen siendo únicos. No modifica estadísticas ni posición física.

`SanctuaryController` posee el cuerpo físico, la cápsula de colisión, los límites, los obstáculos, la capa `TileMapLayer`, el agente de navegación y el grafo A*. `CameraSystem` calcula seguimiento y zoom sin desplazar la UI. El render ordena entidades por profundidad y vuelve a dibujar regiones del escenario para producir oclusión real.

## Ajustes

`SettingsManager` persiste volumen maestro, música, efectos, velocidad del texto, resolución, modo de ventana y esquema de movimiento. Todos los valores se sanean antes de aplicarse.

## Añadir contenido

1. Crear el `.tres` correspondiente bajo `data/resources/`, o editar el JSON para contenido narrativo.
2. Registrarlo en `GameDatabase`.
3. Ejecutar la suite completa.
4. Añadir pruebas específicas si el recurso introduce una regla nueva.

No deben codificarse estadísticas o recompensas nuevas directamente en `main.gd`.

## Pruebas

Desde la raíz del repositorio:

```bash
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless \
  --rendering-method gl_compatibility \
  --rendering-driver opengl3 \
  --path games/mini_jrpg \
  --script res://tests/test_runner.gd
```

La suite usa exclusivamente `user://tests`, elimina sus artefactos y devuelve un código distinto de cero si alguna comprobación falla.
