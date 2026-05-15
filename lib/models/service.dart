// lib/models/service.dart
// Ánh xạ GET /api/services
// Response: data[] — List thẳng, không paged

import 'package:klcn_app/network/media_url.dart';

// ── SERVICE MODEL ─────────────────────────────────────────────────
class ServiceModel {
  final int serviceId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;

  const ServiceModel({
    required this.serviceId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
  });

  String get priceFmt {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M';
    return '${(price / 1000).toStringAsFixed(0)}k';
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    serviceId: json['serviceId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    imageUrl: (json['imageUrl'] as String?).toFullMediaUrl,
    isAvailable: json['isAvailable'] as bool? ?? true,
  );
}

// ── SERVICE REQUEST ITEM ──────────────────────────────────────────
// Dùng trong body của POST /api/bookings
class ServiceRequestItem {
  final int serviceId;
  final int quantity;

  const ServiceRequestItem({required this.serviceId, required this.quantity});

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'quantity': quantity,
  };
}
