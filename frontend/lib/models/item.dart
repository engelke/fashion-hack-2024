class Item {
  final String id;
  final String imageUrl;
  final String clothingType;
  final String color;
  final String style;
  final String material;
  final String occasion;

  Item({
    required this.id,
    required this.imageUrl,
    required this.clothingType,
    required this.color,
    required this.style,
    required this.material,
    required this.occasion,
  });

  Item copyWith({
    String? id,
    String? imageUrl,
    String? clothingType,
    String? color,
    String? style,
    String? material,
    String? occasion,
  }) {
    return Item(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      clothingType: clothingType ?? this.clothingType,
      color: color ?? this.color,
      style: style ?? this.style,
      material: material ?? this.material,
      occasion: occasion ?? this.occasion,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json, {String? id}) {
    // Helper function to handle array or string
    String getFirstStringOrValue(dynamic value) {
      if (value is List) {
        return value.isNotEmpty ? value[0].toString() : '';
      }
      return value?.toString() ?? '';
    }

    return Item(
      id: id ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      clothingType: getFirstStringOrValue(json['clothing_type']),
      color: getFirstStringOrValue(json['color']),
      style: getFirstStringOrValue(json['style']),
      material: getFirstStringOrValue(json['material']),
      occasion: getFirstStringOrValue(json['occasion']),
    );
  }

  Map<String, dynamic> toJson() => {
        'image_url': imageUrl,
        'clothing_type': clothingType,
        'color': color,
        'style': style,
        'material': material,
        'occasion': occasion,
      };
}
