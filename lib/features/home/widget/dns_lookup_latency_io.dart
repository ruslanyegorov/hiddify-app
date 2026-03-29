import 'dart:io';

Future<int?> measureDnsLookupLatencyMs() async {
  final sw = Stopwatch()..start();
  try {
    await InternetAddress.lookup('cloudflare.com').timeout(const Duration(seconds: 3));
  } catch (_) {
    return null;
  }
  sw.stop();
  return sw.elapsedMilliseconds;
}
