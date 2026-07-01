import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/Data/place_model.dart';

class PlaceRepository {
  final _collection = FirebaseFirestore.instance.collection('places');

  Future<List<PlaceModel>> getPlaces() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map(PlaceModel.fromFirestore).toList();
  }
}
