const { withMainActivity } = require("@expo/config-plugins");

/**
 * Keeps Android share/process-text intents available when the app task already exists.
 * The native module places the shared text in the activity Intent; this hook makes
 * sure Android replaces the old Intent when it delivers onNewIntent.
 */
module.exports = function withFloatingTranslator(config) {
  return withMainActivity(config, (modConfig) => {
    const contents = modConfig.modResults.contents;

    if (contents.includes("override fun onNewIntent(intent: Intent)")) {
      return modConfig;
    }

    if (contents.includes("import android.os.Build") && !contents.includes("import android.content.Intent")) {
      modConfig.modResults.contents = contents.replace(
        "import android.os.Build",
        "import android.content.Intent\nimport android.os.Build",
      );
    }

    if (modConfig.modResults.contents.includes("class MainActivity : ReactActivity() {")) {
      modConfig.modResults.contents = modConfig.modResults.contents.replace(
        "class MainActivity : ReactActivity() {",
        "class MainActivity : ReactActivity() {\n  override fun onNewIntent(intent: Intent) {\n    super.onNewIntent(intent)\n    setIntent(intent)\n  }",
      );
    }

    return modConfig;
  });
};
