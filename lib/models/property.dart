class Property {
  final String id;
  final String name;
  final String location;
  final String city;
  final double price;
  final String imageUrl;
  final String type;
  final bool isVerified;
  final String verificationStatus; // 'unverified', 'pending', 'verified'
  final String description;
  final int bedrooms;
  final int bathrooms;
  final int area;
  final List<String> amenities;
  final List<String> images;

  final String phoneNumber;
  final String? user_id;

  const Property({
    required this.id,
    this.user_id,
    required this.name,
    required this.location,
    required this.city,
    required this.price,
    required this.imageUrl,
    required this.type,
    this.phoneNumber = '+251911223344',
    this.isVerified = false,
    this.verificationStatus = 'unverified',
    this.description = '',
    this.bedrooms = 2,
    this.bathrooms = 1,
    this.area = 1200,
    this.amenities = const [],
    this.images = const [],
  });
}
