# Estado — Sistema Cuentas (Flutter)

Actualizado: 2026-10-15 · `flutter analyze` limpio y ~2120 pruebas en verde (adaptadores falsos; nada confirmado contra el servidor)

## Dónde estamos
- Base aplicada con `new_project.sh` (Inter, primario `#0F4C5C`): `flutter analyze` limpio y pruebas del
  starter en verde. `lib/features/home/` es solo el ejemplo del starter (se borra con la primera feature real).
- **Backend listo, dentro de la app en `./backend`:** BD 001 + 002 instaladas y verificadas por el usuario; 28
  endpoints probados en local (163 comprobaciones) y confirmados en el servidor (health ok, 403 en `core/` y
  `conexion.php`, login real, catálogos y resumen). Resto de endpoints: se comprobarán desde la app.
  Bitácora: `backend/docs/REGISTRO.md`. Contrato: `backend/docs/API.md`.
- **Flutter:** hecho (implementado, `flutter analyze` limpio; probado solo en pruebas locales, NO contra el servidor real):
  - Base visual oscura (`AppColors`/`AppTheme.dark`, marca `#0F4C5C`, acento verde azulado), píldora flotante de 4
    pestañas (rail en ≥ 900 px), cabecera común (nombre, mes ‹ OCT DE 2026 ›, ojo, avatar con inicial).
  - `ApiEndpoints` con las 27 rutas que usa la app (sincronizado con `API.md`).
  - Feature `auth`: login → `sessionProvider` → router con redirección; 401 cierra sesión.
  - **Inicio** (`features/home`, `movements`, `summary`, `catalogs`): balance = `flujo_neto` del mes, Ingresos/Gastos, historial
    por día con buscador local, botón «+» → hoja Gasto/Ingreso → hoja inferior de nuevo movimiento. Usa `resumen/mes`,
    `movimientos/listar` y `registrar`, `catalogos/categorias` y `medios`. pruebas con adaptadores falsos;
    **no confirmado contra el servidor** (falta que el usuario registre un movimiento real).
  - **Pagos recurrentes** (`features/recurring`, `dues`): «Este mes» (vencimientos con estado, Cobrar/Pagar desde la fila) y
    «Acuerdos» (lista, detalle con historial, Finalizar, crear). Usa `vencimientos/listar`, `pagos_recurrentes/listar,
    detalle, crear, finalizar`, `catalogos/contactos` y `movimientos/registrar` con `id_vencimiento`. pruebas en verde
    (adaptadores falsos); **no confirmado contra el servidor**.
  - **Resumen** (`features/summary`): totales del mes, pendiente por cobrar y pagar, **barras ingresos vs gastos de los
    últimos 6 meses**, **dona por categoría** (gastos/ingresos; tocar un trozo lo resalta y tocar una categoría de la leyenda abre sus movimientos), **línea de tendencia de gastos**, **por dónde entra o
    sale el dinero por medio de pago frente al mes pasado** (con ▲▼ %), lo que dejó cada medio y el capital aparte. Todo lo
    calcula el servidor (`resumen/mes`, uno por mes, guardado por mes). Gráficas con el paquete **`fl_chart`** (aprobado por el usuario 2026-10-14): barras, dona y línea con toques y tooltips;
    estilo común en `features/summary/widgets/chart_style.dart`.
  - **Ajustes** (`features/settings`, `catalogs`, `users`): perfil, crear/editar categorías, medios de pago y contactos
    (activar/desactivar), usuarios (solo administrador) y «Cerrar sesión» con confirmación.
  - **Nuevo movimiento** ahora es una hoja inferior (elige Ingreso/Gasto y llena el formulario en la misma hoja, mide lo que
    miden sus campos) y, al registrar, el monto «vuela» hasta la tarjeta de Ingresos o de Gastos de Inicio
    (`shared/widgets/amount_flight.dart`, `fly_targets_provider`); la cifra se suma sola al llegar el total del servidor.
  - **Precarga** al entrar (`shared/providers/app_preload_provider.dart`): resumen, movimientos, vencimientos, acuerdos y
    catálogos por turnos en segundo plano, para que las pestañas ya tengan datos.
  - **Inicio:** el buscador se cambió por un conmutador Todos/Ingresos/Gastos (verde/rojo); las tarjetas Ingresos y Gastos del
    balance tienen su color y, al tocarlas, abren `MovementsListScreen` (`/movements/:type`) con buscador y filtros (fechas,
    categoría, medio de pago; el servidor filtra con `movimientos/listar`).
  - **Cabecera:** muestra el nombre de la vista (Inicio, Pagos recurrentes, Resumen, Ajustes); el nombre de la persona queda en el avatar.
  - **Inicio:** las tarjetas Ingresos y Gastos traen un despegable «Por medio» (cerrado al empezar) con lo de cada medio de pago, nombre e importe en la misma línea.
  - **Marca y nombre (2026-10-14):** la app se llama «Cuentas Claras» (CC); icono nuevo (billete con «$», `BrandMarkPainter`), pantalla de arranque nativa en iOS/Android/web (fondo oscuro, marca y nombre) y `SplashScreen` con «Cargando…» y mensajes con iconos que rotan. iOS listo para probar en iPhone real: `scripts/build_ios.sh` y `docs/IOS.md` (compilación release sin firmar comprobada; falta instalarla en un teléfono).
  - **Filas:** el contacto va primero y la fecha nunca se parte en dos líneas (`DotSeparatedText`); cada movimiento muestra bajo el monto la hora en que se registró (necesita la entrega backend 003, solo SQL).
  - **Tema, ocultar y saldo inicial (2026-10-14):** Ajustes → «Tema» (claro, oscuro o automático; se recuerda en el teléfono; `AppColors` ahora es dinámico). Además del ojo de la cabecera (tapa todo), la tarjeta de balance tiene su ojo y el neto de cada día se tapa tocándolo. Filas del historial compactas en 2 líneas (monto y hora en la esquina) y píldora del menú más abajo. **Saldo inicial:** la primera vez (mes actual y anterior vacíos) Inicio invita a registrar con cuánto se empieza, por medio de pago o en un solo valor (categoría «Saldo inicial», de capital; también en Ajustes). Sin cambios de servidor.
  - **Eliminar movimientos:** deslizar una fila a la izquierda (Inicio y listas de Ingresos/Gastos) abre una confirmación con motivo y anula el movimiento (`movimientos/anular`); solo con el permiso `movimientos.anular`. Implementado y probado con adaptadores falsos; **no confirmado contra el servidor**.
  - **Eliminar categorías (2026-10-15):** botón «Eliminar» (con confirmación) en el diálogo de editar; sin permiso aparte (Categorías ya no depende de `catalogos.gestionar`; solo `usuarios.gestionar` sigue restringido). La categoría eliminada sale de Ajustes y de los selectores, pero lo registrado con ella se conserva y sigue con su icono/color. Usa `catalogos/categoria_eliminar.php` y el campo `eliminada` (**entrega backend 004 / migración 005: generada y probada local, pendiente de que el usuario la instale**). Caso abierto: pagar un vencimiento de un acuerdo activo cuya categoría se eliminó da 422 hasta elegir otra.
  - **Inicio, primera vez:** sin el mensaje «Sin movimientos» y con la tarjeta «¿Con cuánto cuentas hoy?» latiendo 6 veces (`AppPulse`). **Splash:** círculo de carga e icono de cada mensaje en un cuadro de color con transición.
  - **Desplegables desde abajo (2026-10-15):** categoría, contacto, «Se repite», medio de pago (pagar, saldo inicial, finalizar) y los filtros de las listas ya no son `AppSearchDropdown`: son tarjetas (`CatalogPickCard`) que abren una hoja inferior (`showCatalogPicker`; sin buscador con pocas opciones, «x» para quitar en opcionales y filtros). `AppSearchDropdown` quedó sin uso en la app. Pagos recurrentes: Categoría+Contacto y Se repite+Desde en pareja. **Sin foco automático** al abrir nuevo gasto/ingreso (no sube el teclado solo) y **sin campo Nota** en gasto/ingreso y pago recurrente. En «Acuerdos», sin ninguno activo, se oculta el botón flotante y «Crear mi primer pago recurrente» late (`AppPulse`).
  - **Splash (2026-10-15):** se ve al menos 2 s (`splashMinDurationProvider`), sin «Cargando…» ni círculo: solo logo, nombre y los mensajes con su icono (cuadro de 56 px) que cambian solos cada 3 s si la carga se alarga. Un error de red se muestra enseguida. Al salir se funde con la vista que sigue (login o Inicio; `fadePage`, 450 ms, sin deslizar; inmediato con «reducir movimiento»). Otros pulsos: botón «Crear mi primer pago recurrente» y flotantes (`AppFab`) latiendo sin parar (`AppPulse`; en pruebas `AppPulse.debugLoopForever = false`).
  - **Eliminar datos (2026-10-15):** Ajustes → «Mis datos» → «Eliminar datos»: diálogo que dice qué se borra y qué se conserva → «Eliminando…» → aviso «Datos eliminados» con «Aceptar», que cierra la sesión y lleva al login. Usa `cuenta/reiniciar_datos.php` (borra de verdad todo lo del usuario y deja la semilla de un usuario nuevo; su usuario y contraseña se conservan). **Entrega backend 006 (migración 007): generada y probada local, pendiente de instalar (requiere la 005 antes).** Además «Eliminar» un acuerdo usa `pagos_recurrentes/eliminar.php` (entrega 005, pendiente).
  - Selector de ícono y color: 30 colores y el nombre de lo que se cambia.
  - **Resumen:** orden «Por dónde entra/sale» → dona por categoría → el resto; el mes pasado solo se ve si ese medio tuvo algo.
  - **Iconos y colores** de categorías y contactos (`CatalogVisuals`: ~70 iconos con buscador y 12 colores; selector en una hoja inferior desde el diálogo de editar/crear). Se ven en Ajustes y en las filas de movimientos, vencimientos y acuerdos. Entrega backend 002 (columnas `icono` y `color`) **instalada y confirmada por el usuario el 2026-10-14**; la app manda esos campos solo si el usuario los toca.
  - Los nombres ya no se cortan con «…» en tarjetas y filas; los conmutadores Me pagan/Yo pago van en verde/rojo.
  - `lib/features/home` del starter se reemplazó.
  - Pendiente de Pagos recurrentes: editar un acuerdo, omitir/ajustar un mes (`vencimientos/anular`, `ajustar`), crear
    contactos (irá en Ajustes), botón de recarga para mouse y listas en 2 columnas en pantalla ancha.
  - Pendiente de Inicio: «Ver historial completo» (filtros fecha/tipo/categoría/medio), detalle de un movimiento y anularlo
    con motivo, refresco silencioso que conserve datos si falla.
  - Web en desarrollo: puerto fijo 8765 (ver `CLAUDE.md`); el servidor debe tener `http://localhost:8765` en `origenes_permitidos`.

## Próximos desarrollos (pedidos del usuario, por orden de interés)
- Iconos también en medios de pago y en la agenda (la agenda del servidor no trae `id_categoria`: pedirlo al `backend-builder`); colores de categoría en la dona y la leyenda.
0. Resumen: **balance futuro** (proyección a 90 días, como en la referencia; requiere definir cómo proyectar: ¿con los
   acuerdos recurrentes?) y comparar contra más de un mes.
1. **Saldo real por medio de pago («cuánto tengo en cada lado»):** hoy Resumen muestra lo que dejó cada medio *este mes*. Un
   saldo acumulado necesita pedir al `backend-builder` totales de siempre por medio (o un saldo inicial por medio).
2. **Detalle** de un movimiento y **anularlo con motivo** (`movimientos/anular`). (La lista con buscador y filtros por fechas,
   categoría y medio ya existe: tocar la tarjeta de Ingresos o de Gastos del balance de Inicio.)
3. **Editar un acuerdo** (`pagos_recurrentes/editar`) y **omitir/ajustar un mes** (`vencimientos/anular`, `ajustar`);
   tocar un vencimiento para abrir su acuerdo.
4. «Gasto por día / días restantes» (se pide al backend, no se calcula en la app).
5. Pantalla ancha: botón de recarga para mouse, listas en 2 columnas, «+» en el encabezado.
6. Un refresco silencioso que no muestre el cargador cuando ya hay datos en todas las pantallas; recordatorios de vencimiento
   (¿notificaciones o avisos dentro de la app?).
7. Pendiente de decisión: día de cobro 29–31 en meses cortos; capital de Harol y Astu (lo completa el usuario).
- Fuera de alcance por ahora: etiquetas (#) y «Estado» de la referencia (el backend no los soporta), asistente por voz/foto,
  tema claro.

## Siguiente
1. Construir una feature por vez (plan aprobado 2026-10-13): ~~base visual + login~~ → ~~Inicio~~ → ~~formulario ingreso/gasto~~ (falta historial completo y anular) → ~~pagos recurrentes y vencimientos~~ → resumen → ajustes.
3. Lo que falte del backend se pide al subagente `backend-builder` (ver `CLAUDE.md`).

## Decisiones tomadas
- 2026-10-12 · Fuente Inter, color de marca `#0F4C5C`.
- 2026-10-13 · Multiusuario; pagos recurrentes → vencimientos → movimientos; categoría y medio de pago obligatorios.
- 2026-10-13 · Dirección visual: tema oscuro sobrio, barra inferior píldora (Inicio · Pagos recurrentes · Resumen · Ajustes), tarjeta de balance + ingresos/gastos, historial por día, botón «+» → hoja Gasto/Ingreso (ver `docs/ARRANQUE_FLUTTER.md`).
- 2026-10-13 · Solo tema oscuro por ahora; «Balance disponible» = `flujo_neto`; historial de Inicio = mes seleccionado (empieza en el actual).
- 2026-10-13 · Backend dentro de la app (`./backend`, ignorado por git) con registro de entregas; los cambios los
  hace el subagente `backend-builder`.

## Pendientes de decidir
- Día de cobro 29–31 en meses cortos (recomendado: último día del mes).
- Capital de Harol y Astu: lo completa el usuario.
- Recordatorios de vencimiento (¿notificaciones o solo avisos dentro de la app?).

## Separar siempre
**Implementado** · **Probado localmente** · **Confirmado en el servidor** (solo si yo lo confirmé).
