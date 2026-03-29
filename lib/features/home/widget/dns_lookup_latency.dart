import 'package:hiddify/features/home/widget/dns_lookup_latency_io.dart'
    if (dart.library.html) 'package:hiddify/features/home/widget/dns_lookup_latency_stub.dart' as impl;

/// Rough latency estimate via DNS lookup; null on failure or web.
Future<int?> measureDnsLookupLatencyMs() => impl.measureDnsLookupLatencyMs();
