{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('splash')?.remove();
  },
});

// Eigener Offline-Speicher (sw.js). Flutters eigener Service Worker ist
// veraltet und wird deshalb nicht verwendet.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('sw.js').catch(function (e) {
      console.warn('Offline-Speicher nicht verfügbar:', e);
    });
  });
}
