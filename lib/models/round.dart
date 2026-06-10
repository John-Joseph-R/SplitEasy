class Round {
  final String id;
  String name;
  Set<String> participantIds;

  Round({
    required this.id,
    required this.name,
    Set<String>? participantIds,
  }) : participantIds = participantIds ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'participantIds': participantIds.toList(),
  };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
    id: json['id'],
    name: json['name'],
    participantIds: (json['participantIds'] as List)
        .map((e) => e.toString())
        .toSet(),
  );
}