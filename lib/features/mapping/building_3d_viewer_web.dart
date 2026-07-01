// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

String registerBuildingIframe(void Function(String) onMessage) {
  const viewType = 'threejs-building-view';

  // Register the factory only once
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = 'assets/assets/web/building_3d_viewer.html'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..allow = 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
      ..setAttribute('allowfullscreen', 'true');
    return iframe;
  });

  html.window.onMessage.listen((event) {
    if (event.data is String) {
      onMessage(event.data as String);
    }
  });

  return viewType;
}

void sendToBuildingIframe(String viewId, String message) {
  final iframe = html.document.querySelector('iframe') as html.IFrameElement?;
  iframe?.contentWindow?.postMessage(message, '*');
}
