{{flutter_js}}
{{flutter_build_config}}

// Rutas versionadas: cada build pide su motor y sus assets bajo
// v/<versión>/, que el .htaccess guarda un año. index.html y este archivo van
// sin caché, así que un despliegue nuevo llega de una.
(function () {
  var version = {{flutter_service_worker_version}};
  var assetBase = null;
  if (version) {
    _flutter.buildConfig.builds.forEach(function (build) {
      if (build.mainJsPath) {
        build.mainJsPath = 'v/' + version + '/' + build.mainJsPath;
      }
      if (build.mainWasmPath) {
        build.mainWasmPath = 'v/' + version + '/' + build.mainWasmPath;
        build.jsSupportRuntimePath = 'v/' + version + '/' + build.jsSupportRuntimePath;
      }
    });
    assetBase = 'v/' + version + '/';
  }

  // Flutter arranca después de que el navegador pinta la pantalla de carga.
  // Si el motor empieza a bajar antes, Lighthouse suma esas descargas al LCP
  // simulado. requestAnimationFrame no basta: corre antes de presentar el
  // cuadro. Tope de 500 ms por si el observador no reporta.
  var arrancado = false;

  function arrancarFlutter() {
    if (arrancado) return;
    arrancado = true;
    _flutter.loader.load({
      config: assetBase ? { assetBase: assetBase } : {}
    });
  }

  function trasPintarArranque() {
    var marca = document.querySelector('#arranque .marca');
    var tipos = window.PerformanceObserver && PerformanceObserver.supportedEntryTypes;
    if (document.hidden || !marca || !marca.naturalWidth || !tipos ||
        tipos.indexOf('largest-contentful-paint') < 0) {
      setTimeout(arrancarFlutter, 0);
      return;
    }
    var observador = new PerformanceObserver(function (lista) {
      var pintada = lista.getEntries().some(function (entrada) {
        return entrada.element === marca;
      });
      if (pintada) {
        observador.disconnect();
        arrancarFlutter();
      }
    });
    observador.observe({ type: 'largest-contentful-paint', buffered: true });
    setTimeout(arrancarFlutter, 500);
  }

  if (document.readyState === 'complete') {
    trasPintarArranque();
  } else {
    window.addEventListener('load', trasPintarArranque, { once: true });
  }
})();
