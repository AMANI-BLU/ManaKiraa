import '../models/property.dart';

class MockData {
  MockData._();

  static const List<String> categories = [
    'All',
    'Single Room',
    'Organization',
    'Commercial',
    'Family House',
    'Store',
  ];

  static const List<String> locations = [
    'Addis Ketema',
    'Bajaj Tera(Quufto)',
    'Stadium',
    'Project(Quufto)',
    'Garbi',
    'Kella(Doloollo Hoola)',
    'Gabaya Guddo',
    'Gabaya Diqo',
    'Gidicho',
    'Kideste mariam school sefer',
  ];

  static const List<Property> properties = [
    Property(
      id: '1',
      name: 'Yabello Traditional Villa',
      location: 'Yabello, Borana, Oromia',
      city: 'Yabello',
      price: 15000,
      imageUrl:
          'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=600',
      type: 'Family House',
      isVerified: true,
      description:
          'A beautiful traditional Borana inspired home in the heart of Yabello. Features modern comfort with classic aesthetics. Perfect for cultural appreciation.',
      bedrooms: 3,
      bathrooms: 2,
      area: 200,
      amenities: ['Solar Power', 'Parking', 'Garden', 'Water Tank', 'Kitchen'],
      phoneNumber: '+251911223344',
    ),
    Property(
      id: '2',
      name: 'Addis Skyline Apartment',
      location: 'Bole, Addis Ababa',
      city: 'Addis Ababa',
      price: 45000,
      imageUrl:
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
      type: 'Family House',
      isVerified: true,
      description:
          'Luxury apartment in the bustling district of Bole. Stunning city views and high-end security. Walking distance to Edna Mall.',
      bedrooms: 2,
      bathrooms: 2,
      area: 120,
      amenities: [
        'WiFi',
        'Gym',
        'Security',
        'AC',
        'Elevator',
        'Backup Generator',
      ],
      phoneNumber: '+251112233445',
    ),
    Property(
      id: '3',
      name: 'Borana Heritage Cottage',
      location: 'Yabello Outskirts, Oromia',
      city: 'Yabello',
      price: 12000,
      imageUrl:
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600',
      type: 'Single Room',
      isVerified: true,
      description:
          'Peaceful cottage designed with locally sourced materials. Offers a unique living experience close to nature with stunning sunset views.',
      bedrooms: 2,
      bathrooms: 1,
      area: 150,
      amenities: ['Garden', 'Parking', 'Fireplace', 'Water Tank'],
      phoneNumber: '+251223344556',
    ),
    Property(
      id: '4',
      name: 'Jimma Coffee Garden House',
      location: 'Jimma Town, Oromia',
      city: 'Jimma',
      price: 8000,
      imageUrl:
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600',
      type: 'Family House',
      isVerified: true,
      description:
          'Spacious villa surrounded by coffee trees. Large windows provide natural light. Very quiet and secure neighborhood.',
      bedrooms: 4,
      bathrooms: 3,
      area: 350,
      amenities: ['WiFi', 'Garden', 'Parking', 'Kitchen', 'Balcony'],
      phoneNumber: '+251334455667',
    ),
    Property(
      id: '5',
      name: 'Nazareth Business Hub Room',
      location: 'Adama (Nazareth), Oromia',
      city: 'Adama',
      price: 5000,
      imageUrl:
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600',
      type: 'Commercial',
      isVerified: false,
      description:
          'Affordable shared room near the main market. Ideal for students or workers. Basic utilities included.',
      bedrooms: 1,
      bathrooms: 1,
      area: 30,
      amenities: ['Kitchen', 'Water Access', 'Main Road Access'],
      phoneNumber: '+251445566778',
    ),
    Property(
      id: '6',
      name: 'Hawassa Lakeview Condo',
      location: 'Hawassa Shore, Ethiopia',
      city: 'Hawassa',
      price: 25000,
      imageUrl:
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600',
      type: 'Organization',
      isVerified: true,
      description:
          'Modern condominium with a direct view of Lake Hawassa. Features balcony and common swimming pool.',
      bedrooms: 3,
      bathrooms: 2,
      area: 160,
      amenities: ['Pool', 'Gym', 'Parking', 'WiFi', 'Elevator'],
      phoneNumber: '+251556677889',
    ),
  ];

  static const List<Map<String, dynamic>> chatList = [
    {
      'name': 'Amanuel Solomon',
      'message': 'Is the Yabello Villa available for next month?',
      'time': '10:05 AM',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'unread': 1,
      'isOnline': true,
    },
    {
      'name': 'Fatuma Ahmed',
      'message': 'Obbo, I want to see the Jimma house.',
      'time': '9:30 AM',
      'avatar':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      'unread': 0,
      'isOnline': true,
    },
    {
      'name': 'Dawit Mengistu',
      'message': 'The price is fixed for Addis apartment?',
      'time': '8:15 AM',
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      'unread': 0,
      'isOnline': false,
    },
  ];

  static const Map<String, List<Map<String, dynamic>>> chatMessages = {
    'Amanuel Solomon': [
      {
        'text': 'Hello, I am interested in the Yabello Traditional Villa',
        'isMe': false,
        'time': '9:50 AM',
      },
      {
        'text': 'Greetings Amanuel! It is currently available.',
        'isMe': true,
        'time': '9:55 AM',
      },
      {
        'text': 'Is the Yabello Villa available for next month?',
        'isMe': false,
        'time': '10:05 AM',
      },
    ],
    'Fatuma Ahmed': [
      {'text': 'Baga nagaan dhuftan!', 'isMe': false, 'time': '9:00 AM'},
      {
        'text': 'Nagaa dhuftani Fatuma. Akkam jirta?',
        'isMe': true,
        'time': '9:05 AM',
      },
      {
        'text': 'Obbo, I want to see the Jimma house.',
        'isMe': false,
        'time': '9:30 AM',
      },
    ],
  };

  static const List<Map<String, dynamic>> notifications = [
    {
      'title': 'New Listing in Yabello',
      'message': 'A traditional Borana house just listed for 12,000 ETB/mo',
      'time': '5 min ago',
      'type': 'new',
      'isRead': false,
    },
    {
      'title': 'Addis Ababa Price Update',
      'message': 'Bole Apartment price reduced to 40,000 ETB/mo',
      'time': '2 hours ago',
      'type': 'price',
      'isRead': false,
    },
    {
      'title': 'Welcome to Mana Kiraa',
      'message': 'Explore the best rentals in Oromia and beyond!',
      'time': '1 day ago',
      'type': 'new',
      'isRead': true,
    },
  ];
}
