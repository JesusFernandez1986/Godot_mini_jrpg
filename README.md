# Crónicas del Cristal: La Corona Hueca

JRPG HD-2D hecho con Godot 4. Incluye menú principal, guardado/carga, mapa mundial, cuatro ciudades, 277 intervenciones narrativas, inventario, estadísticas, Valdoria explorable, una vertical slice con mazmorra y combate táctico de cuatro personajes.

## Ejecutar

1. Abre `project.godot` desde Godot.
2. Pulsa **F6** o el botón de ejecutar.

## Controles

- **Flechas/WASD:** moverse o navegar por los menús.
- **Shift:** correr durante la exploración.
- **E o Espacio:** abrir cofres, activar mecanismos y usar altares.
- **Enter:** aceptar, hablar o avanzar diálogos.
- **M, Tab o Esc:** abrir/cerrar el menú del grupo.
- En combate, **↑/↓** elige una orden, **←/→** cambia el objetivo y **Enter** confirma.
- Los atajos **1–8** ejecutan: atacar, arte, curar, defender, objeto, cambiar iniciativa, ataque combinado y huir.

La partida se guarda automáticamente al completar capítulos y también puede guardarse manualmente desde **Menú → Sistema**.

## Fase 3 · El León Despierto

1. Completa el primer capítulo de Valdoria para obtener control libre en la plaza.
2. Habla con la **capitana Elara** para iniciar la misión principal.
3. Habla con **Oren**, **Inés** y **Dario** para aceptar las tres secundarias; hay diez NPC interactivos en total.
4. Entra por la puerta norte, activa los dos sellos y completa los objetivos opcionales.
5. Derrota seis tipos de enemigo, al **Caballero Perjuro** y al **León de la Corona Hueca**.
6. Regresa a Valdoria, entrega los encargos y habla con Elara para ver el cierre narrativo.

El objetivo actual y el progreso de los tres encargos aparecen en **Menú → Diario**. Todo el progreso de la fase se incluye en guardados manuales y autoguardados.

## Fase 4 · Combate completo de grupo

- Hasta cuatro héroes activos con iniciativa por velocidad y los próximos siete turnos siempre visibles.
- Ataques físicos, artes mágicas y afinidades elementales; debilidades, resistencias y escudo de ruptura por enemigo.
- **Resonancia** al explotar debilidades. Con tres puntos, el grupo puede ejecutar **Convergencia del Cristal**.
- Defensa, consumibles, cambio de iniciativa, selección de objetivo y huida; los combates de élite impiden escapar.
- Veneno, silencio, sueño, miedo, ceguera y regeneración con duración por turnos.
- Enemigos con tres fases de IA, intención anticipada y patrones propios.
- EXP para todo el grupo, oro y botín configurable al terminar cada victoria.

Todos los comandos usan las secuencias de animación correspondientes: ataque, arte, cura, defensa, objeto, relevo, combinado y carrera.

## Base técnica

- Tres ranuras manuales y autoguardado con checksum, backup y migraciones.
- Ajustes persistentes de audio, ventana, velocidad de texto y controles.
- Datos de personajes, objetos, enemigos, lugares y misiones en recursos editables.
- Sistemas independientes para inventario, progresión, diálogo, viaje y combate.
- Suite automatizada unitaria y de integración.
- Escalado 16:9 explícito para que el juego llene tanto una ventana normal como el modo incrustado del editor.

## Pruebas

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_runner.gd
```

La suite ejecuta comprobaciones unitarias y de integración sobre datos, misiones, navegación A*, colisiones, renderizado, guardado/carga y el recorrido completo de la campaña. Además simula 2.500 batallas deterministas contra enemigos normales, miniboss y jefe.

## Movimiento y animación

- Atlas frame a frame para Aren, Lyra, Brom y Seris, con ocho orientaciones.
- Secuencias de reposo, caminar, correr, hablar, atacar, defender, recibir daño, caer, usar objetos e interactuar.
- Exploración física mediante `CharacterBody2D`, `TileMapLayer`, obstáculos sólidos, `NavigationAgent2D` y rutas A*.
- Cámara suave con zoom contextual, escala por profundidad, sombras dinámicas y oclusión tras el escenario.
- Cofre, mecanismo y altar interactivos cuyo estado se conserva en el guardado.

Consulta [ARCHITECTURE.md](ARCHITECTURE.md) para ampliar el juego y ejecutar las pruebas.
