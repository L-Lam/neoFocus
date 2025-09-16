enum GachaRarity { common, rare, epic, legendary }

class GachaItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final GachaRarity rarity;
  final String species;
  final bool isOwned;
  final DateTime? obtainedAt;

  GachaItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rarity,
    required this.species,
    this.isOwned = false,
    this.obtainedAt,
  });

  factory GachaItem.fromMap(Map<String, dynamic> map, String id) {
    return GachaItem(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rarity: GachaRarity.values.firstWhere(
        (e) => e.toString() == 'GachaRarity.${map['rarity']}',
        orElse: () => GachaRarity.common,
      ),
      species: map['species'] ?? '',
      isOwned: map['isOwned'] ?? false,
      obtainedAt: map['obtainedAt'] != null 
          ? DateTime.parse(map['obtainedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rarity': rarity.toString().split('.').last,
      'species': species,
      'isOwned': isOwned,
      'obtainedAt': obtainedAt?.toIso8601String(),
    };
  }

  GachaItem copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    GachaRarity? rarity,
    String? species,
    bool? isOwned,
    DateTime? obtainedAt,
  }) {
    return GachaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rarity: rarity ?? this.rarity,
      species: species ?? this.species,
      isOwned: isOwned ?? this.isOwned,
      obtainedAt: obtainedAt ?? this.obtainedAt,
    );
  }

  // Helper methods
  String get rarityDisplayName {
    switch (rarity) {
      case GachaRarity.common:
        return 'common';
      case GachaRarity.rare:
        return 'rare';
      case GachaRarity.epic:
        return 'epic';
      case GachaRarity.legendary:
        return 'legendary';
    }
  }

  double get dropRate {
    switch (rarity) {
      case GachaRarity.common:
        return 0.60; // 60%
      case GachaRarity.rare:
        return 0.30; // 30%
      case GachaRarity.epic:
        return 0.08; // 8%
      case GachaRarity.legendary:
        return 0.02; // 2%
    }
  }

  bool get isRareOrBetter {
    return rarity.index >= GachaRarity.rare.index;
  }
}