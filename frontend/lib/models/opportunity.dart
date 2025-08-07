import 'user.dart';
class Opportunity {
  final String id;
  final String title;
  final String userName;
  final double userRating;
  final String ratedBy;
  final String category;
  final String imageUrl;
  final String? description;
  final double? price;
  final String? location;
  final DateTime? createdAt;
  final DateTime? scheduledDate; // Nueva: fecha programada del trabajo
  final bool? isActive;

  Opportunity({
    required this.id,
    required this.title,
    required this.userName,
    required this.userRating,
    required this.ratedBy,
    required this.category,
    required this.imageUrl,
    this.description,
    this.price,
    this.location,
    this.createdAt,
    this.scheduledDate,
    this.isActive = true,
  });

  // Método para convertir desde JSON (cuando venga del backend)
  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      userName: json['user_name'] ?? '',
      userRating: (json['user_rating'] ?? 0.0).toDouble(),
      ratedBy: json['rated_by'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      description: json['description'],
      price: json['price']?.toDouble(),
      location: json['location'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      scheduledDate: json['scheduled_date'] != null 
          ? DateTime.parse(json['scheduled_date']) 
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  // Método para convertir a JSON (cuando se envíe al backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'user_name': userName,
      'user_rating': userRating,
      'rated_by': ratedBy,
      'category': category,
      'image_url': imageUrl,
      'description': description,
      'price': price,
      'location': location,
      'created_at': createdAt?.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}