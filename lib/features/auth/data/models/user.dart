class User {
  final String id;
  final int? userId;
  final String username;
  final String fullName;
  final String role; // 'customer' | 'admin' | 'employee' | 'staff'

  const User({
    required this.id,
    this.userId,
    required this.username,
    required this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String,
    userId:
        (j['userId'] as num?)?.toInt() ??
        int.tryParse((j['id'] ?? '').toString()),
    username: j['username'] as String,
    fullName: j['fullName'] as String,
    role: j['role'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'username': username,
    'fullName': fullName,
    'role': role,
  };
}
