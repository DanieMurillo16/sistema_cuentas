# Sistema Cuentas — control personal de dinero

App (web / iOS / Android) para llevar las cuentas y reemplazar el bloc de notas: **pagos recurrentes**
(los que me pagan cada mes = ingreso; los que yo pago = gasto) → **vencimientos** mensuales → **movimientos**
(la plata real). Es **multiusuario**: cada persona ve solo lo suyo y el administrador da de alta a otros.
Hereda las reglas de `~/.claude/CLAUDE.md` y la base de diseño de `~/.claude/flutter-base/` (diseño,
diálogos, formularios, responsive, pruebas, web). Aquí va **solo lo propio del proyecto**.

> **Antes de tocar nada** lee [`docs/ESTADO.md`](docs/ESTADO.md): dónde vamos, qué sigue y qué está
> pendiente de decidir. El negocio y el vocabulario están en [`docs/NEGOCIO.md`](docs/NEGOCIO.md).

## Estructura

```
lib/
  core/        config, errors, network (un solo Dio), router, services (AppToast), theme, utils
  features/<x>/{data,models,providers,utils,widgets,<x>_screen.dart}
  shared/      widgets reutilizables (diálogos, formularios, tarjetas), navigation
  main.dart
```

Features previstas (aún sin construir; `lib/features/home/` es el ejemplo del starter y se borra al
crear la primera real): `auth` (login y sesión), `summary` (resumen del mes), `dues` (vencimientos y agenda),
`movements` (ingresos y gastos), `recurring` (pagos recurrentes), `catalogs` (categorías, medios de pago,
contactos), `users` (solo administrador). Pantallas y orden en [`docs/ARRANQUE_FLUTTER.md`](docs/ARRANQUE_FLUTTER.md).

## Reglas propias

- Riverpod a mano + go_router + un solo Dio. Sin domain/usecases/codegen/freezed.
- Nombres de archivos y clases en inglés; textos de UI y errores en español.
- App **multiusuario**: la identidad sale del token, nunca de un id enviado por la app; un 401 cierra sesión.
- Dinero: pesos colombianos (COP), `DECIMAL` como texto desde el backend, solo con los formateadores de
  `core/utils`. Fechas `AAAA-MM-DD`, hora de Colombia.
- Lo cobrado o pagado es historial: se **anula** con motivo, no se borra (ver `database.md`).
- Todo movimiento lleva **categoría y medio de pago** obligatorios (Nequi, Bancolombia, efectivo…).
- Los saldos y totales (por cobrar, balance del mes, por categoría y por medio) los calcula el servidor; la
  app no inventa cifras precalculadas aparte.
- Datos compartidos entre vistas: un dato vive en un solo provider (`upsert`/`invalidate`), ver
  `flutter-base/architecture.md`. Ej.: registrar un pago actualiza el vencimiento, el resumen del mes y la
  lista de movimientos sin recargar.
- Toda vista nueva: skill `flutter-ui` + agentes `flutter-ui-reviewer` y `flutter-tester` al terminar.

## Backend (API + base de datos)

- **Carpeta:** `./backend` (dentro de esta app, **ignorada por su git**; **no se le hace `git init`**: su historia es `backend/docs/REGISTRO.md`). PHP + MariaDB. Su `CLAUDE.md` tiene las
  reglas; su bitácora es `backend/docs/REGISTRO.md` (qué entregas hay, su estado y qué debe hacer Flutter).
- **Contrato (única fuente de verdad):** `backend/docs/API.md`. `ApiEndpoints` refleja sus filas; comprobar con
  `python3 -I ~/.claude/flutter-base/tools/api_sync_check.py backend/docs/API.md lib/core/network/api_endpoints.dart backend`.
- **Servidor:** `public_html/bd_cuentas/` · **URL base:** `https://cobros.com.co/bd_cuentas/` · **BD:** `u668681301_cuentas`.
- **Credenciales:** `privado/cuentas.php` fuera de `public_html`; nunca en git ni en la app.
- La app envía `Authorization: Bearer TOKEN`; la identidad sale del token.
- **Si falta algo del backend** (un dato, un campo, un filtro, un endpoint): **no lo inventes ni edites `backend/` a
  mano.** Junta el pedido (pantalla, datos que entran y salen, filtros, reglas) y llama al subagente
  **`backend-builder`** indicando la ruta `./backend`. Hace BD + PHP + pruebas + paquete `entregas/NNN_*/` + fila en
  `REGISTRO.md`, y devuelve el contrato exacto. Varios pedidos juntos = una sola entrega. Si devuelve preguntas de
  negocio, se las haces al usuario. Mientras tanto avanza contra el contrato.
- **Estados de una entrega:** `generada → probada local → instalada (confirmada) → consumida por Flutter`. Solo el
  usuario confirma «instalada» (él sube el SQL y los PHP); nunca la marques tú. Marca «consumida por Flutter» cuando
  la app ya use el endpoint.
- Antes de usar un endpoint, mira en `REGISTRO.md` que su entrega esté instalada; si no, avísale al usuario.
- **Cierre de cada trabajo con backend:** el ÚLTIMO mensaje debe traer una sola lista consolidada de lo que el usuario debe
  subir: ruta exacta (`backend/entregas/NNN_*/…`), orden numerado (1. SQL en phpMyAdmin, 2. verificador, 3. PHP a
  `public_html/bd_cuentas/…`, 4. publicar la app) y el estado de cada entrega (instalada / pendiente). Nada de pasos sueltos
  en mensajes intermedios ni de subagentes: si una entrega cambia, se reemplaza la lista completa.
- No me conecto al servidor: lo que haya que instalar lo hago yo siguiendo `backend/entregas/NNN_*/LEEME.md`.

## Comandos

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://cobros.com.co/bd_cuentas/
flutter analyze
flutter test
bash scripts/build_web.sh --dart-define=API_BASE_URL=https://cobros.com.co/bd_cuentas/   # web con Wasm
bash scripts/build_ios.sh run <ID-del-iPhone>   # iPhone real (ver docs/IOS.md)
```

`API_BASE_URL` va por `--dart-define` (o `.env.json`, ignorado por git); nunca en el código. El botón Run del IDE ya lo
usa: `.idea/runConfigurations/main_dart.xml` (Android Studio) y `.vscode/launch.json` pasan `--dart-define-from-file=.env.json` y fijan el puerto web en **8765**: el origen
`http://localhost:8765` debe estar en `origenes_permitidos` de `privado/cuentas.php` (CORS del servidor; también el dominio de producción de la web).

## Identidad visual

- Fuente: Inter (empaquetada en `assets/fonts/`). Color de marca: `#0F4C5C` (verde azulado profundo, sobrio).
- El resto del diseño sale de la base (`AppColors`, `AppTheme`, `DesignTokens`).
