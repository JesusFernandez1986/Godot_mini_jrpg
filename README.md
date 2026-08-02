# Crónicas del Cristal: La Corona Hueca

JRPG HD-2D hecho con Godot 4. Incluye menú principal, guardado/carga, mundo explorable con clima y ciclo horario, cuatro ciudades vivas, seis mazmorras multinivel, ocho protagonistas, más de 530 intervenciones narrativas, inventario, equipo, árboles de talentos, trabajos, códice, decisiones persistentes y combate táctico con formación activa de cuatro personajes.

## Ejecutar

1. Abre `project.godot` desde Godot.
2. Pulsa **F6** o el botón de ejecutar.

## Controles

- **Flechas/WASD:** moverse o navegar por los menús.
- **Shift:** correr durante la exploración.
- En el mapa mundial, **C** monta un campamento y **F** viaja al siguiente refugio desbloqueado.
- **E o Espacio:** abrir cofres, activar mecanismos y usar altares.
- **Enter:** aceptar, hablar o avanzar diálogos.
- **M, Tab o Esc:** abrir/cerrar el menú del grupo.
- En combate, **↑/↓** elige una orden, **←/→** cambia el objetivo y **Enter** confirma.
- En una decisión narrativa, **↑/↓** elige una respuesta y **Enter** la confirma.
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

## Fase 5 · Equipamiento y progresión

- Doce armas, armaduras y accesorios, con cinco rarezas, restricciones por personaje, pasivas y mejoras `+1…+5`.
- Comparación de estadísticas antes de equipar y recálculo desde estadísticas base para evitar acumulaciones.
- Taller con recetas, oro, Hierro resonante, Hilo lunar y Fragmentos prismáticos.
- Nueve artes activas, habilidades pasivas, tres talentos encadenados por personaje y cuatro trabajos secundarios.
- Cuatro formaciones: Equilibrada, Vanguardia, Convergencia arcana y Hostigamiento.
- EXP, puntos de trabajo, puntos de talento, materiales y botín especial integrados en las recompensas.

Abre **Menú → Equipo** para cambiar piezas, fabricar y mejorar. En **Menú → Progreso** puedes cambiar de personaje, especializarlo, aprender talentos, seleccionar su arte activa y elegir la formación.

## Fase 6 · Misiones y narrativa

- Misión principal ramificada, cuatro misiones personales y las misiones secundarias de Valdoria.
- Decisiones con variables persistentes y conversaciones posteriores condicionadas.
- Códice de personajes, lugares y acontecimientos desbloqueado por escenas y elecciones.
- Conversaciones opcionales durante viajes y descansos, sin repeticiones.
- Escenas dirigidas con movimiento ensayado, cámara, retratos, expresiones, animación y música ambiental sintetizada.
- Once escenas y 56 intervenciones nuevas definidas en `data/dialogues/phase6_dialogues.json`, fuera del código.
- Guardado y reanudación en el nodo exacto de una decisión.

Las misiones personales se inician desde **Menú → Diario**. El Consejo Abierto comienza al concluir **El León Despierto**.

## Fase 7 · Mundo explorable

- Movimiento libre del grupo sobre Eryndor, con límites de terreno y retorno seguro.
- Reloj persistente con amanecer, día, atardecer y noche; cinco regiones con clima determinista.
- Cuatro zonas de peligro visibles que inician combates y respetan un tiempo de reaparición.
- Campamentos que restauran al grupo, avanzan hasta el amanecer y crean puntos de viaje rápido.
- Barco desbloqueado tras Puerto Celestia y corredor marítimo hacia la Isla del Velo.
- Seis localizaciones adicionales: Gruta de las Ascuas, Ruinas de Eira, Torre de las Estrellas, Bosque de la Luna Baja, Fortaleza del Juramento e Isla del Velo.
- Cuevas, ruinas, torres, bosques y fortalezas se descubren mediante exploración o rumores urbanos, pueden cartografiarse y conservan su retorno.

En el mapa usa **WASD/flechas** para mover el grupo, **Enter** junto a un destino para entrar, **C** para acampar y **F** para recorrer los puntos de viaje rápido.

## Fase 8 · Ciudades vivas

- Valdoria, Brumaforja, Puerto Celestia y Sylvaran tienen tres barrios diferenciados cada una.
- Cada ciudad ofrece interiores de taberna, posada, mercado, herrería, vivienda y sede política.
- Dieciséis habitantes siguen horarios de amanecer, día, atardecer y noche; sus conversaciones cambian entre el capítulo local, el viaje y el desenlace.
- Doce rumores revelan conflictos, misiones y localizaciones ocultas.
- Cuatro conflictos locales persistentes: censo y representación, deuda de clanes, política portuaria y frontera forestal.
- Actividades propias con decisiones y recompensa única: torneo de blasones, ritual del yunque, regata de corrientes y canto de las raíces.
- Música sintetizada y ambientación específicas por ciudad, además de lluvia, bruma, ceniza, luceros y cambios de luz.

Dentro de una ciudad usa **←/→** para cambiar de barrio, **↑/↓** para elegir una interacción y **Enter** para entrar en interiores, conversar o jugar la actividad local.

## Fase 9 · Mazmorras y exploración

- Seis mazmorras conectadas al mapa: ruinas, gruta, torre, bosque, fortaleza e isla.
- Tres plantas de tiles por mazmorra, con entrada, salida, automapa y porcentaje de descubrimiento persistente.
- Llaves, mecanismos, puzles ambientales, atajos permanentes, cofres normales, cofres secretos y trampas de un solo uso.
- Ocho capacidades de exploración: fuerza, lectura astral, martillo rúnico, rastreo, mareas, paso de sombra, canto de runas y garfio.
- Minijefe y jefe secreto opcionales en cada mazmorra, integrados con el combate y las recompensas existentes.
- La ruta principal de cada planta se valida por conectividad y nunca depende de un secreto u objeto perdible.

En una localización especial elige **Explorar el lugar**. Usa **WASD/flechas** sobre la cuadrícula isométrica y **Enter/Espacio** para interactuar con la casilla actual.

## Fase 10 · Ocho protagonistas

- Aren, Lyra, Brom y Seris se unen a Naia, Kael, Mira y Orin, con estadísticas, afinidad, arma, arte, árbol de talentos y capacidad de exploración propios.
- Exactamente 32 capítulos personales: cuatro por protagonista, incluido su prólogo individual.
- Cada héroe tiene conflicto, antagonista, jefe, revelaciones y desenlace propios.
- Seis misiones cruzadas enlazan parejas, tríos y finalmente a los ocho miembros del grupo.
- Un capítulo final común enfrenta a la Corona Hueca y genera ocho epílogos variables según las decisiones y vínculos conservados.
- **Menú → Grupo** permite alternar entre miembros activos y reserva, con un máximo de cuatro combatientes.
- **Menú → Diario** muestra los 32 capítulos, conversaciones cruzadas y final común con su estado de desbloqueo.
- Los nuevos retratos pixel-art se encuentran en `assets/phase10_party.png`; el atlas de movimiento conserva todas las secuencias de caminar, correr, hablar, atacar, defender, sufrir daño, usar objetos, interactuar y celebrar.

## Fase 11 · Bestiario y ecosistema de enemigos

- 32 entradas entre criaturas base y variantes cenicientas, prismáticas y abismales.
- Registro persistente de avistamientos, victorias, análisis, afinidades y porcentaje de completado.
- Ocho afijos de élite que alteran PV, ataque, defensa, velocidad, ruptura y recompensas.
- Doce contratos de caza con progreso y recompensa no duplicable.
- Los encuentros del mundo generan élites de forma progresiva y todos los combates alimentan el bestiario.

## Fase 12 · Economía y recolección

- Mercados independientes en Valdoria, Brumaforja, Celestia y Sylvaran.
- Existencias, demanda, descuentos por reputación y reposición cada dos jornadas.
- Compra de consumibles, materiales y equipo; venta segura de objetos no clave.
- Negociación y ocho nodos de recolección renovables ligados al calendario.

## Fase 13 · Facciones

- Corona del León, Gremio de la Brasa, Cónclave Astral y Pacto Verde.
- 24 misiones secundarias en tres etapas, con escenas propias y progresión encadenada.
- Hasta tres encargos simultáneos, reputación de −100 a 100, rangos y acontecimientos mundiales persistentes.
- Resoluciones de concordia o ascendencia y final político variable.

## Fase 14 · Endgame

- Arena de los Ecos con 25 pruebas escaladas y jefe cada cinco combates.
- Ocho superjefes opcionales, veinte desafíos especiales y dificultad Relato/Estandar/Veterano/Pesadilla.
- Rachas, recompensas de legado y escalado adicional por ciclo.
- Nueva Partida + tras completar toda la arena, conservando el progreso de legado.

## Fase 15 · Versión final

- 40 logros en ocho categorías, sincronizados con la partida real.
- Accesibilidad persistente: alto contraste, movimiento reducido, escala de texto, daltonismo, avance automático, velocidad de batalla y vibración de cámara.
- Base de localización español/inglés, créditos y auditoría de integridad de lanzamiento.
- Nueva pestaña **Menú → Extras** para bestiario, mercado, facciones, arena, dificultad, accesibilidad e idioma.

## Fases 16–21 · Pase de calidad jugable

- Perfiles de animación propios para ocho protagonistas, diseños diferenciados para Naia, Kael, Mira y Orin, poses de anticipación/impacto y partículas de interacción.
- Combate con hit-stop, sacudida opcional, números de daño y un atlas elemental HD-2D para fuego, hielo, rayo, viento, luz y oscuridad.
- Demo vertical Valdoria/Eira accesible con **V** desde el título, ocho hitos visibles y directrices para las fases del jefe.
- Ordenación isométrica por profundidad, patrullas y horarios urbanos, clima de intensidad variable y primer plano ambiental.
- Expresiones dirigidas, consecuencias anticipadas en las elecciones y vínculos persistentes afectados por las respuestas.
- Seis topologías de mazmorra diferenciadas, paletas propias y patrullas visibles y evitables en sus 18 plantas.

## Base técnica

- Tres ranuras manuales y autoguardado v16 con checksum, backup y migraciones desde v1.
- Ajustes persistentes de audio, ventana, velocidad de texto y controles.
- Datos de personajes, objetos, enemigos, lugares y misiones en recursos editables.
- Sistemas independientes para inventario, progresión, diálogo, viaje y combate.
- Suite automatizada unitaria y de integración.
- Escalado 16:9 explícito para que el juego llene tanto una ventana normal como el modo incrustado del editor.

## Pruebas

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_runner.gd
```

La suite ejecuta más de 1.180 comprobaciones unitarias y de integración sobre datos, misiones, 18 plantas de mazmorra, ocho capacidades de exploración, 32 capítulos personales, bestiario, mercados, facciones, arena, logros, todas las animaciones, rutas, horarios, clima, presentación de combate, decisiones, navegación A*, guardado/carga v1–v16, Nueva Partida + y campaña completa. Además simula 2.500 batallas deterministas, 1.200 combinaciones de equipo y 6.000 pasos de estrés sobre el mapa mundial.

## Movimiento y animación

- Atlas frame a frame para los ocho protagonistas, con ocho orientaciones y paletas diferenciadas; retratos HD pixel-art propios para el segundo grupo.
- Secuencias de reposo, caminar, correr, hablar, atacar, defender, recibir daño, caer, usar objetos e interactuar.
- Exploración física mediante `CharacterBody2D`, `TileMapLayer`, obstáculos sólidos, `NavigationAgent2D` y rutas A*.
- Cámara suave con zoom contextual, escala por profundidad, sombras dinámicas y oclusión tras el escenario.
- Cofre, mecanismo y altar interactivos cuyo estado se conserva en el guardado.

Consulta [ARCHITECTURE.md](ARCHITECTURE.md) para ampliar el juego y ejecutar las pruebas.
