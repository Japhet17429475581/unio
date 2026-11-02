{{flutter_js}}
{{flutter_build_config}}

const unioEngineConfig = {
  canvasKitBaseUrl: 'canvaskit/',
  canvasKitVariant: 'full',
  fontFallbackBaseUrl: new URL('fonts/', document.baseURI).href
};
_flutter.loader.load({
  config: unioEngineConfig,
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine(unioEngineConfig);
      await appRunner.runApp();
      document.getElementById('boot')?.remove();
    } catch (_) { window.unioBootFailed(); }
  }
}).catch(() => window.unioBootFailed());
