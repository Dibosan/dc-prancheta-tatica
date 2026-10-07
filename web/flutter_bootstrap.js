{{flutter_js}}
{{flutter_build_config}}

(async () => {
  if ('serviceWorker' in navigator) {
    try {
      const serviceWorkerUrl = new URL(
        'service-worker.js',
        document.baseURI
      );

      await navigator.serviceWorker.register(serviceWorkerUrl);
      await navigator.serviceWorker.ready;
    } catch (error) {
      console.warn(
        'Service Worker não pôde ser registrado:',
        error
      );
    }
  }

  _flutter.loader.load();
})();
