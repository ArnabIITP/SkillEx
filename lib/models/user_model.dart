class UserModel {
  final String id;
  final String email;
  final String name;
  final String bio;
  final String photoUrl;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final List<String> availability;
  final bool isAdmin;
  final double rating;
  final int completedSwaps;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.bio = '',
    this.photoUrl = '',
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.availability = const [],
    this.isAdmin = false,
    this.rating = 0.0,
    this.completedSwaps = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    // Helper function to convert any type of data to a List<String>
    List<String> convertToStringList(dynamic data) {
      if (data == null) return [];
      
      if (data is String) {
        // If it's a single string, wrap it in a list
        return [data];
      } else if (data is List) {
        // If it's already a list, convert each element to String
        return data.map<String>((item) => item.toString()).toList();
      } else {
        // For any other type, return empty list
        return [];
      }
    }
    
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      skillsOffered: convertToStringList(data['skillsOffered']),
      skillsWanted: convertToStringList(data['skillsWanted']),
      availability: convertToStringList(data['availability']),
      isAdmin: data['isAdmin'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      completedSwaps: data['completedSwaps'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'photoUrl': photoUrl,
      'skillsOffered': skillsOffered,
      'skillsWanted': skillsWanted,
      'availability': availability,
      'isAdmin': isAdmin,
      'rating': rating,
      'completedSwaps': completedSwaps,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? photoUrl,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    List<String>? availability,
    bool? isAdmin,
    double? rating,
    int? completedSwaps,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      skillsOffered: skillsOffered ?? this.skillsOffered,
      skillsWanted: skillsWanted ?? this.skillsWanted,
      availability: availability ?? this.availability,
      isAdmin: isAdmin ?? this.isAdmin,
      rating: rating ?? this.rating,
      completedSwaps: completedSwaps ?? this.completedSwaps,
    );
  }
}
