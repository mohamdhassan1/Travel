import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceModel {
  final String id;
  final String title;
  final String image; // network URL stored in Firestore
  final double rate;
  final String description;
  final double price;

  PlaceModel({
    required this.id,
    required this.title,
    required this.image,
    required this.rate,
    required this.description,
    required this.price,
  });

  factory PlaceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlaceModel(
      id: doc.id,
      title: d['title'] ?? '',
      image: d['image'] ?? '',
      rate: (d['rate'] as num?)?.toDouble() ?? 0.0,
      description: d['description'] ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
