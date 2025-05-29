class Dashboard {
  double temperature;
  double humidity;
  String relayStatus;
  DateTime timestamp;

  Dashboard({
    required this.temperature,
    required this.humidity,
    required this.relayStatus,
    required this.timestamp,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      temperature: double.parse(json['temperature'].toString()),
      humidity: double.parse(json['humidity'].toString()),
      relayStatus: json['relay_status'] ?? 'Off',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'relay_status': relayStatus,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
