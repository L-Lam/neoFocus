import 'package:flutter/material.dart';

enum BuddyRarity { common, rare, epic, legendary }

class Buddy {
  final String id;
  final String name;
  final BuddyRarity rarity;
  final String species;
  final String description;
  final String image;
  final int auraPoints;

  const Buddy({
    required this.id,
    required this.name,
    required this.rarity,
    required this.species,
    required this.description,
    required this.image,
    this.auraPoints = 0,
  });

  // Get max possible aura for this rarity
  int getMaxPossibleAura() {
    switch (rarity) {
      case BuddyRarity.common:
        return 100;
      case BuddyRarity.rare:
        return 500;
      case BuddyRarity.epic:
        return 2000;
      case BuddyRarity.legendary:
        return 10000;
    }
  }

  // Get color for this rarity
  Color getRarityColor() {
    switch (rarity) {
      case BuddyRarity.common:
        return Colors.grey;
      case BuddyRarity.rare:
        return Colors.blue;
      case BuddyRarity.epic:
        return Colors.purple;
      case BuddyRarity.legendary:
        return Colors.red;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rarity': rarity.name,
      'species': species,
      'description': description,
      'image': image,
      'auraPoints': auraPoints,
    };
  }

  factory Buddy.fromJson(Map<String, dynamic> json) {
    return Buddy(
      id: json['id'] as String,
      name: json['name'] as String,
      rarity: BuddyRarity.values.firstWhere((e) => e.name == json['rarity']),
      species: json['species'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      auraPoints: json['auraPoints'] as int? ?? 0,
    );
  }

  // Create a copy with updated aura points
  Buddy copyWith({
    int? auraPoints,
  }) {
    return Buddy(
      id: id,
      name: name,
      rarity: rarity,
      species: species,
      description: description,
      image: image,
      auraPoints: auraPoints ?? this.auraPoints,
    );
  }
}
