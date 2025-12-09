import 'package:flutter/material.dart';

enum BuddyRarity { common, rare, exotic, unique }

enum BuddySource { gacha, shop }

class Buddy {
  final String id;
  final String name;
  final BuddyRarity rarity;
  final String description;
  final String image;
  final int auraPoints;
  final List<BuddySource> source;
  final int duplicate;

  const Buddy({
    required this.id,
    required this.name,
    required this.rarity,
    required this.description,
    required this.image,
    this.auraPoints = 0,
    this.source = const [BuddySource.gacha, BuddySource.shop],
    this.duplicate = 1,
  });

  // Get max possible aura for this rarity
  int getMaxPossibleAura() {
    switch (rarity) {
      case BuddyRarity.exotic || BuddyRarity.unique:
        return 10000;
      default:
        return 1000;
    }
  }

  // Get color for this rarity
  Color getRarityColor() {
    switch (rarity) {
      case BuddyRarity.common:
        return Colors.grey;
      case BuddyRarity.rare:
        return Colors.blue;
      case BuddyRarity.exotic:
        return Colors.red;
      case BuddyRarity.unique:
        return Colors.purpleAccent;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rarity': rarity.name,
      'description': description,
      'image': image,
      'auraPoints': auraPoints,
      'sources': source.map((s) => s.name).toList(),
      'duplicateCount': duplicate,
    };
  }

  factory Buddy.fromJson(Map<String, dynamic> json) {
    return Buddy(
      id: json['id'] as String,
      name: json['name'] as String,
      rarity: BuddyRarity.values.firstWhere((e) => e.name == json['rarity']),
      description: json['description'] as String,
      image: json['image'] as String,
      auraPoints: json['auraPoints'] as int? ?? 0,
      source:
          (json['sources'] as List<dynamic>?)
              ?.map((s) => BuddySource.values.firstWhere((e) => e.name == s))
              .toList() ??
          [BuddySource.gacha, BuddySource.shop],
      duplicate: json['duplicateCount'] as int? ?? 1,
    );
  }

  // Create a copy with updated fields
  Buddy copyWith({int? auraPoints, int? duplicateCount}) {
    return Buddy(
      id: id,
      name: name,
      rarity: rarity,
      description: description,
      image: image,
      auraPoints: auraPoints ?? this.auraPoints,
      source: source,
      duplicate: duplicateCount ?? this.duplicate,
    );
  }
}
