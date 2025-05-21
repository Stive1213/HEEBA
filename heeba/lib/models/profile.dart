class Profile {
  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String? nickname;
  final int age;
  final String? gender;
  final String? bio;
  final String region;
  final String city;
  final String? pfpPath;
  final bool notificationsEnabled; // Added field

  Profile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.nickname,
    required this.age,
    this.gender,
    this.bio,
    required this.region,
    required this.city,
    this.pfpPath,
    required this.notificationsEnabled, // Added to constructor
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      nickname: json['nickname'],
      age: json['age'],
      gender: json['gender'],
      bio: json['bio'],
      region: json['region'],
      city: json['city'],
      pfpPath: json['pfp_path'],
      notificationsEnabled: json['notifications_enabled'] == 1, // Parse INTEGER as boolean
    );
  }
}