Eres el chat Flutter de «Sistema Cuentas». Usa mi base (flutter-new-project, flutter-feature, flutter-ui, flutter-testing). Lee primero CLAUDE.md, docs/ESTADO.md y docs/NEGOCIO.md.

BACKEND (./backend, ya instalado y confirmado en https://cobros.com.co/bd_cuentas/)
- Contrato único: backend/docs/API.md (28 rutas). Qué hay y qué falta: backend/docs/REGISTRO.md («Pendiente para Flutter»). No leas ni asumas el esquema de la BD ni edites backend/ a mano.
- Si falta un dato, un campo, un filtro o un endpoint: no lo inventes. Junta el pedido (pantalla, datos que entran y salen, filtros, reglas) y llama al subagente backend-builder con la ruta ./backend. Puedes juntar varios pedidos en una sola llamada. Te devuelve el contrato exacto y un paquete en backend/entregas/NNN_*/; yo lo subo y te confirmo. Mientras tanto avanzas contra el contrato. Si te devuelve preguntas de negocio, me las haces a mí. Nunca marques nada como «instalado».

MODELO (CLAUDE.md, NEGOCIO.md y ESTADO.md ya están actualizados)
App multiusuario (cada persona ve solo lo suyo; el administrador da de alta a otros). Pagos recurrentes (los que me pagan = ingreso, los que pago = gasto) → vencimientos mensuales → movimientos (la plata real, con categoría y medio de pago obligatorios). Borra lib/features/home/ al crear la primera feature real.

ASÍ QUIERO QUE SE VEA (te adjunto 6 capturas de una app de referencia: tómala como inspiración de estructura y estilo, no la copies al pie de la letra)
- Tema oscuro, sobrio, con acento verde azulado (mi color de marca es #0F4C5C; propón la paleta oscura dentro de AppColors/AppTheme, sin colores sueltos en las vistas). Pregúntame en el plan si quiero también tema claro.
- Navegación: barra inferior flotante tipo píldora con 4 pestañas: Inicio · Pagos recurrentes · Resumen · Ajustes (en pantalla ancha, el rail lateral de AppShell).
- Cabecera común: nombre del usuario, selector de mes con flechas (‹ OCT DE 2026 ›), botón de ojo para ocultar cifras (motion.md: «ocultar saldos») y avatar.
- INICIO: tarjeta grande de balance del mes («Balance disponible», cifra grande que cuenta al aparecer) con dos tarjetas pequeñas debajo, Ingresos (+) y Gastos (−). Más abajo, historial de movimientos agrupado por día, con el total del día a la derecha, icono de la categoría, descripción, categoría y monto en verde (ingreso) o rojo (gasto); «Ver historial completo» lleva a la lista con filtros (fecha, tipo, categoría, medio de pago). Al hacer scroll aparece una barra de búsqueda. Un solo botón flotante «+».
- BOTÓN «+»: abre una hoja inferior con dos opciones grandes, Gasto e Ingreso. (La referencia trae un «Asistente inteligente» por voz/foto: NO lo hagas.)
- FORMULARIO Ingreso/Gasto (pantalla completa): monto grande arriba, fecha en una píldora, descripción opcional, categoría (selector), medio de pago (OBLIGATORIO en mi modelo: Nequi, Bancolombia, efectivo…), nota opcional y botón «Guardar», con el interruptor «Guardar y agregar otro». Etiquetas (#) y «Estado» de la referencia: solo si el backend ya lo soporta; si no, no las pongas y dímelo.
- PAGOS RECURRENTES: lista de mis pagos recurrentes (ingresos y gastos) con su día y valor, la sección «Este mes» con los vencimientos (quién pagó y quién no, vencidos, a quién le toca hoy; desde cada fila registrar un pago o abono), estado vacío con «Crear mi primer pago recurrente» y botón para crear uno nuevo. Detalle con historial y «Finalizar» (fecha y nota, p. ej. «me devolvió el capital»).
- RESUMEN: ingresos, gastos y balance del mes, total por categoría y por medio de pago, el capital recuperado/entregado aparte, y lo por cobrar. Navegar entre meses.
- AJUSTES: catálogos (categorías, medios de pago, contactos), usuarios (solo administrador) y cerrar sesión.
- Cifras como «gasto por día / días restantes» de la referencia: déjalo para después y, si lo quiero, se pide al backend-builder (no se calcula en la app).

REGLAS QUE NO SE NEGOCIAN
Dinero como texto o entero al enviar y texto al recibir, solo con los formateadores de core/utils. Tras registrar o anular algo se refrescan vencimientos, historial y resumen sin vaciar la pantalla (el servidor es la fuente de saldos, sin cifras precalculadas). Cada pantalla resuelve datos / cargando / error / vacío. Nada se borra: se anula con motivo. Un 401 cierra sesión.

HAZ ESTO
1. Plan de 5 a 10 líneas (features, orden, dudas de diseño y qué pedirías al backend) y espera mi visto bueno.
2. Una feature por vez, con ApiEndpoints sincronizado: python3 -I ~/.claude/flutter-base/tools/api_sync_check.py backend/docs/API.md lib/core/network/api_endpoints.dart backend
3. Al cerrar cada feature: ui_audit.sh + agentes flutter-ui-reviewer y flutter-tester, y dime el resultado real y lo que no se pudo verificar.
Orden sugerido: login → Inicio (balance + historial) → formulario ingreso/gasto → pagos recurrentes y vencimientos → resumen → ajustes (catálogos y usuarios).
