// Mobile stub — these functions are no-ops on Android/iOS.
// The 3D editor will use a native WebView approach on mobile in a future brick.

String registerEditorIframe(void Function(String) onMessage) => '';
void sendMessageToIframe(String viewId, String message) {}
