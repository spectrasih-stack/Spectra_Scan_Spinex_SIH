/// Operator identity and credentials for evidence chain of custody
class OperatorProfile {
  final String name;
  final String badge;
  final String agency;
  final String unit;
  final String email;
  final String deviceModel;
  final String authProvider; // 'GOOGLE', 'BIOMETRIC', 'PASSCODE'
  final String? photoUrl;

  const OperatorProfile({
    required this.name,
    required this.badge,
    required this.agency,
    required this.unit,
    this.email = 'lacshan.shakthivel@gmail.com',
    this.deviceModel = 'Samsung Galaxy F15 5G',
    this.authProvider = 'GOOGLE',
    this.photoUrl,
  });

  static const defaultOperator = OperatorProfile(
    name: 'Lacshan Shakthivel',
    badge: 'BADGE-7104',
    agency: 'State Forensic Evidence Division',
    unit: 'Mobile Chemical Screening Unit',
    email: 'lacshan.shakthivel@gmail.com',
    deviceModel: 'Samsung Galaxy F15 5G',
    authProvider: 'GOOGLE',
  );

  OperatorProfile copyWith({
    String? name,
    String? badge,
    String? agency,
    String? unit,
    String? email,
    String? deviceModel,
    String? authProvider,
    String? photoUrl,
  }) {
    return OperatorProfile(
      name: name ?? this.name,
      badge: badge ?? this.badge,
      agency: agency ?? this.agency,
      unit: unit ?? this.unit,
      email: email ?? this.email,
      deviceModel: deviceModel ?? this.deviceModel,
      authProvider: authProvider ?? this.authProvider,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'badge': badge,
        'agency': agency,
        'unit': unit,
        'email': email,
        'deviceModel': deviceModel,
        'authProvider': authProvider,
        'photoUrl': photoUrl,
      };

  factory OperatorProfile.fromJson(Map<String, dynamic> json) =>
      OperatorProfile(
        name: json['name'] as String? ?? 'Lacshan Shakthivel',
        badge: json['badge'] as String? ?? 'BADGE-7104',
        agency: json['agency'] as String? ?? 'State Forensic Evidence Division',
        unit: json['unit'] as String? ?? 'Field Screening',
        email: json['email'] as String? ?? 'lacshan.shakthivel@gmail.com',
        deviceModel: json['deviceModel'] as String? ?? 'Samsung Galaxy SM-E156B',
        authProvider: json['authProvider'] as String? ?? 'GOOGLE',
        photoUrl: json['photoUrl'] as String?,
      );
}
