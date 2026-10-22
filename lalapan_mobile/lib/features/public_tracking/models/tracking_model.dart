class TimelineStepModel {
  final int step;
  final String title;
  final String description;
  final String status; // 'COMPLETED', 'PENDING', 'IN_PROGRESS', 'REVISION_REQUIRED'
  final String? timestamp;

  TimelineStepModel({
    required this.step,
    required this.title,
    required this.description,
    required this.status,
    this.timestamp,
  });

  factory TimelineStepModel.fromJson(Map<String, dynamic> json) {
    return TimelineStepModel(
      step: json['step'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'PENDING',
      timestamp: json['timestamp'],
    );
  }
}

class TrackingModel {
  final String registrationNumber;
  final String status;
  final String babyName;
  final String motherName;
  final String institutionName;
  final String? aktaKelahiranNumber;
  final String? publicInstruction;
  final List<TimelineStepModel> timeline;

  TrackingModel({
    required this.registrationNumber,
    required this.status,
    required this.babyName,
    required this.motherName,
    required this.institutionName,
    this.aktaKelahiranNumber,
    this.publicInstruction,
    required this.timeline,
  });

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    return TrackingModel(
      registrationNumber: json['registrationNumber'] ?? '',
      status: json['status'] ?? 'DRAFT',
      babyName: json['babyName'] ?? '',
      motherName: json['motherName'] ?? '',
      institutionName: json['institutionName'] ?? '',
      aktaKelahiranNumber: json['aktaKelahiranNumber'],
      publicInstruction: json['publicInstruction'],
      timeline: (json['timeline'] as List? ?? [])
          .map((t) => TimelineStepModel.fromJson(t))
          .toList(),
    );
  }
}
