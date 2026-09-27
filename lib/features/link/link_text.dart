/// First http(s) link in [text]; apps often share "Look at this https://…".
String? extractUrl(String text) {
  final match = RegExp(r'https?://[^\s<>"]+').firstMatch(text);
  if (match == null) return null;
  final url = match.group(0)!.replaceAll(RegExp(r'[.,;:!?)\]]+$'), '');
  final uri = Uri.tryParse(url);
  return uri != null && uri.host.contains('.') ? url : null;
}
