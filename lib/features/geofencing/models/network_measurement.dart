enum NetworkUsageLevel {
  noConnectivity,
  voiceOnly,
  smsNotificationsOnly,
  basicInternet,
  fullInternet,
}

extension NetworkUsageLevelLabel on NetworkUsageLevel {
  String get label {
    switch (this) {
      case NetworkUsageLevel.noConnectivity:
        return 'Aucune connectivite';
      case NetworkUsageLevel.voiceOnly:
        return 'Voix uniquement';
      case NetworkUsageLevel.smsNotificationsOnly:
        return 'SMS / notifications uniquement';
      case NetworkUsageLevel.basicInternet:
        return 'Internet basique';
      case NetworkUsageLevel.fullInternet:
        return 'Internet complet';
    }
  }
}

class NetworkMeasurement {
  final String declaredNetworkType;
  final int? signalDbm;
  final bool? voiceCapable;
  final double? tcpLatencyMedianMs;
  final double? downlinkKbps;
  final NetworkUsageLevel usageLevel;

  const NetworkMeasurement({
    required this.declaredNetworkType,
    required this.usageLevel,
    this.signalDbm,
    this.voiceCapable,
    this.tcpLatencyMedianMs,
    this.downlinkKbps,
  });

  String get usageLabel => usageLevel.label;

  static NetworkUsageLevel deriveUsageLevel({
    required String declaredNetworkType,
    required bool? voiceCapable,
    required double? tcpLatencyMedianMs,
    required double? downlinkKbps,
  }) {
    final type = declaredNetworkType.toLowerCase();
    final hasRadio = type != 'none' && type != 'unknown';

    final hasInternetSignal =
        tcpLatencyMedianMs != null || (downlinkKbps != null && downlinkKbps > 0);

    if (!hasRadio && !hasInternetSignal) {
      return NetworkUsageLevel.noConnectivity;
    }

    if (hasRadio && !hasInternetSignal) {
      if (voiceCapable == true) {
        return NetworkUsageLevel.voiceOnly;
      }
      return NetworkUsageLevel.smsNotificationsOnly;
    }

    final speed = downlinkKbps ?? 0;
    final latency = tcpLatencyMedianMs ?? 9999;

    if (speed >= 2000 && latency <= 120) {
      return NetworkUsageLevel.fullInternet;
    }
    return NetworkUsageLevel.basicInternet;
  }
}
