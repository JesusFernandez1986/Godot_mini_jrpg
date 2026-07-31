# Arquitectura de Crónicas del Cristal

## Objetivo

La base técnica separa contenido, reglas de dominio, persistencia, navegación y presentación. Una nueva ciudad, misión o personaje puede añadirse sin modificar sistemas no relacionados.

## Capas

- `data/`: definiciones `Resource` editables de personajes, objetos, enemigos, localizaciones y misiones.
- `systems/`: reglas deterministas de inventario, progresión, diálogo, viaje, combate individual y de grupo, animación y cámara.
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
world_map -> city | explore | valdoria_explore | game_menu
city -> dialogue | world_map | game_menu
explore | valdoria_explore | dungeon -> battle | game_menu
battle -> explore | dungeon | dialogue
game_menu -> settings | save_menu | load_menu | estado anterior
```

Cada cambio genera una entrada estructurada de log y un fundido breve.

## Persistencia

- Formato actual: versión 5.
- Ranuras manuales: `user://saves/slot_1.json` a `slot_3.json`.
- Autoguardado: `user://saves/autosave.json`.
- Cada archivo incluye metadatos, payload y checksum SHA-256.
- La escritura usa un temporal y rota la versión anterior a `.bak` antes de publicar la nueva.
- Si el archivo principal falta o no supera el checksum, se intenta recuperar `.bak`.
- Las partidas v1–v4 migran secuencialmente a v5. Las migraciones añaden orientación, interacciones, progreso de la vertical slice, afinidades de combate y estado del tutorial de Resonancia sin invalidar ranuras anteriores.

## Combate de grupo

`PartyBattleSystem` es una máquina de estado determinista separada de la presentación. Mantiene los cuatro aliados activos, cola de iniciativa, escudo de ruptura, Resonancia, estados alterados, fase/patrón enemigo, resultado, registro y botín.

`main.gd` solo traduce entrada y salida: presenta el orden de turnos, los ocho comandos, las afinidades y la intención enemiga; después sincroniza PV, animaciones, recompensas y retorno a la exploración. Los datos de velocidad, arma, elemento, debilidades, resistencias, escudo, patrones y botín residen en recursos `.tres`.

Las simulaciones llaman al mismo sistema que la partida real. Esto permite ejecutar miles de batallas sin renderizado y validar que ninguna queda bloqueada ni produce PV, escudos o Resonancia fuera de rango.

## Movimiento y presentación

`CharacterAnimationSystem` selecciona regiones del atlas de forma determinista según personaje, estado, dirección y tiempo. No modifica las estadísticas ni la posición física.

`SanctuaryController` posee el cuerpo físico, la cápsula de colisión, los límites, los obstáculos, la capa `TileMapLayer`, el agente de navegación y el grafo A*. `CameraSystem` calcula seguimiento y zoom sin desplazar la UI. El render ordena entidades por profundidad y vuelve a dibujar regiones del escenario para producir oclusión real.

## Ajustes

`SettingsManager` persiste volumen maestro, música, efectos, velocidad del texto, resolución, modo de ventana y esquema de movimiento. Todos los valores se sanean antes de aplicarse.

## Añadir contenido

1. Crear el `.tres` correspondiente bajo `data/resources/`.
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
