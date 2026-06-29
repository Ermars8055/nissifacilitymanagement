// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Registers the Three.js editor HTML file as a Flutter HtmlElementView.
/// Returns the unique view ID to use with HtmlElementView(viewType: id).
String registerEditorIframe(void Function(String) onMessage) {
  const viewType = 'threejs-editor-view';

  // Register the factory only once
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = 'assets/assets/web/3d_editor.html'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..allow = 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
      ..setAttribute('allowfullscreen', 'true');
    return iframe;
  });

  // Listen for postMessage from iframe
  html.window.onMessage.listen((event) {
    if (event.data is String) {
      onMessage(event.data as String);
    }
  });

  return viewType;
}

/// Sends a JSON string message into the registered iframe via postMessage.
void sendMessageToIframe(String viewId, String message) {
  final iframe = html.document.querySelector('iframe') as html.IFrameElement?;
  iframe?.contentWindow?.postMessage(message, '*');
}
