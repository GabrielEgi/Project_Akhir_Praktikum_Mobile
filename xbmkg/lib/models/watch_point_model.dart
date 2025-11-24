import 'package:hive/hive.dart';

part 'watch_point_model.g.dart';

@HiveType(typeId: 6)
class WatchPointModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String address;

  @HiveField(3)
  double latitude;

  @HiveField(4)
  double longitude;

  @HiveField(5)
  String? description;

  @HiveField(6)
  String? nearestCity;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? updatedAt;

  WatchPointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    this.nearestCity,
    required this.createdAt,
    this.updatedAt,
  });

  WatchPointModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    String? nearestCity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WatchPointModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      nearestCity: nearestCity ?? this.nearestCity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
