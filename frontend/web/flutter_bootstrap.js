{{flutter_js}}
{{flutter_build_config}}

const loading = document.querySelector("#loading");
const loadingContent = loading.querySelector(".loading-content");
const loadingText = loading.querySelector(".loading-text");

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    loadingText.textContent = "Initializing...";
    const appRunner = await engineInitializer.initializeEngine({
      renderer: 'html'
    });

    // Show success animation
    loading.querySelector(".loading-indicator").style.display = "none";
    loadingText.style.display = "none";
    loadingContent.classList.add("success-animation");

    // Run the app and fade out after animation
    setTimeout(() => {
      loading.classList.add("fade-out");
      setTimeout(() => {
        loading.remove();
        appRunner.runApp();
      }, 300);
    }, 500);
  }
}); 