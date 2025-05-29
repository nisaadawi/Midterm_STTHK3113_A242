class Threshold {
  final double temp_treshold;
  final double hum_treshold;

  Threshold({
    required this.temp_treshold,
    required this.hum_treshold,
  });

  factory Threshold.fromJson(Map<String, dynamic> json) {
    return Threshold(
      temp_treshold: double.tryParse(json['temp_treshold'].toString()) ?? 0.0,
      hum_treshold: double.tryParse(json['hum_treshold'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'temp_treshold': temp_treshold,
    'hum_treshold': hum_treshold,
  };
} 