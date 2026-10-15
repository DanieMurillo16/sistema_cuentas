# iOS: probar la app en un iPhone real

Estado del proyecto (revisado el 2026-10-14):

- **Nombre en el teléfono:** «Cuentas Claras» (`CFBundleDisplayName`). Icono y pantalla de arranque propios (ver abajo).
- **Bundle ID:** `com.murillodev.siscuent.sistemaCuentas` (no se cambió para no perder la firma ya configurada).
- **Equipo de firma:** `HN6KYY325Z` ya está en el proyecto, y la Mac tiene una identidad «Apple Development» válida.
- **iOS mínimo:** 15.0. **Versión:** `1.0.0+1` (`pubspec.yaml`).
- **Servidor:** `API_BASE_URL` sale de `.env.json` (ignorado por git), igual que en web.

## Una sola vez, en el iPhone
1. Conéctalo por cable y desbloquéalo; acepta «Confiar en este equipo».
2. Ajustes → Privacidad y seguridad → **Modo de desarrollador** → activar (pide reiniciar).
3. Tras instalar la app por primera vez, Ajustes → General → **VPN y gestión de dispositivos** → confía en tu cuenta de desarrollador.

## Compilar e instalar
```bash
bash scripts/build_ios.sh devices        # copia el ID de tu iPhone
bash scripts/build_ios.sh run <ID>       # instala y abre la app (modo release)
```
- Para probar sin instalar: `bash scripts/build_ios.sh build`. Para un `.ipa` (TestFlight o distribución): `bash scripts/build_ios.sh ipa`.
- La primera compilación tarda varios minutos (CocoaPods y Xcode). Si Xcode pide firmar, abre `ios/Runner.xcworkspace` →
  Runner → Signing & Capabilities y confirma el equipo.
- Con una cuenta Apple **gratuita** la app instalada caduca a los 7 días y hay que volver a instalarla.
- En un teléfono real prueba lo que los tests no cubren: fluidez, teclado, deslizar para eliminar, la pantalla de arranque.

## Icono y pantalla de arranque
- El dibujo (un billete con «$») está en `lib/shared/widgets/brand_mark_painter.dart`. Los PNG salen de él:
  `flutter test tool/icon_gen/icon_gen_test.dart && bash scripts/apply_brand_assets.sh` (iOS, Android y web).
- Arranque de iOS: `ios/Runner/Base.lproj/LaunchScreen.storyboard` (fondo oscuro, marca y «Cuentas Claras»); al abrir, la app muestra la misma
  imagen con «Cargando…» y mensajes (`SplashScreen`), así no hay pantalla blanca ni logo de Flutter.
