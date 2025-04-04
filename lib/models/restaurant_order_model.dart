import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderType {
  delivery,
  pickup
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  completed,
  cancelled
}

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? specialInstructions;
  final Map<String, dynamic> options;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.specialInstructions,
    this.options = const {},
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      specialInstructions: map['specialInstructions'],
      options: map['options'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'specialInstructions': specialInstructions,
      'options': options,
    };
  }
}

class RestaurantOrderModel {
  final String id;
  final String userId;
  final String restaurantId;
  final List<OrderItem> items;
  final OrderType type;
  final OrderStatus status;
  final DateTime orderTime;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final String? deliveryAddress;
  final double subtotal;
  final double taxAmount;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final bool useLoyaltyPoints;
  final int loyaltyPointsUsed;
  final int loyaltyPointsEarned;
  final String paymentMethod;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  RestaurantOrderModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.items,
    required this.type,
    this.status = OrderStatus.pending,
    required this.orderTime,
    this.pickupTime,
    this.deliveryTime,
    this.deliveryAddress,
    required this.subtotal,
    required this.taxAmount,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    required this.totalAmount,
    this.useLoyaltyPoints = false,
    this.loyaltyPointsUsed = 0,
    this.loyaltyPointsEarned = 0,
    required this.paymentMethod,
    this.isPaid = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  // Conversion depuis/vers Firestore
  factory RestaurantOrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<OrderItem> items = [];
    if (data['items'] != null) {
      for (var item in data['items']) {
        items.add(OrderItem.fromMap(item));
      }
    }
    
    return RestaurantOrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      items: items,
      type: _orderTypeFromString(data['type'] ?? 'pickup'),
            status: _orderStatusFromString(data['status'] ?? 'pending'),
            orderTime: (data['orderTime'] as Timestamp).toDate(),
            pickupTime: data['pickupTime'] != null ? (data['pickupTime'] as Timestamp).toDate() : null,
            deliveryTime: data['deliveryTime'] != null ? (data['deliveryTime'] as Timestamp).toDate() : null,
            deliveryAddress: data['deliveryAddress'],
            subtotal: (data['subtotal'] ?? 0.0).toDouble(),
            taxAmount: (data['taxAmount'] ?? 0.0).toDouble(),
            deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
            discount: (data['discount'] ?? 0.0).toDouble(),
            totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
            useLoyaltyPoints: data['useLoyaltyPoints'] ?? false,
            loyaltyPointsUsed: data['loyaltyPointsUsed'] ?? 0,
            loyaltyPointsEarned: data['loyaltyPointsEarned'] ?? 0,
            paymentMethod: data['paymentMethod'] ?? 'card',
            isPaid: data['isPaid'] ?? false,
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
            metadata: data['metadata'] ?? {},
          );
        }
      
        Map<String, dynamic> toFirestore() {
          List<Map<String, dynamic>> itemsMap = [];
          for (var item in items) {
            itemsMap.add(item.toMap());
          }
          
          return {
            'userId': userId,
            'restaurantId': restaurantId,
            'items': itemsMap,
            'type': _orderTypeToString(type),
            'status': _orderStatusToString(status),
            'orderTime': Timestamp.fromDate(orderTime),
            'pickupTime': pickupTime != null ? Timestamp.fromDate(pickupTime!) : null,
            'deliveryTime': deliveryTime != null ? Timestamp.fromDate(deliveryTime!) : null,
            'deliveryAddress': deliveryAddress,
            'subtotal': subtotal,
            'taxAmount': taxAmount,
            'deliveryFee': deliveryFee,
            'discount': discount,
            'totalAmount': totalAmount,
            'useLoyaltyPoints': useLoyaltyPoints,
            'loyaltyPointsUsed': loyaltyPointsUsed,
            'loyaltyPointsEarned': loyaltyPointsEarned,
            'paymentMethod': paymentMethod,
            'isPaid': isPaid,
            'createdAt': Timestamp.fromDate(createdAt),
            'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
            'metadata': metadata,
          };
        }
      
        // Helpers pour la conversion des enums
        static OrderType _orderTypeFromString(String type) {
          switch (type) {
            case 'delivery': return OrderType.delivery;
            case 'pickup': return OrderType.pickup;
            default: return OrderType.pickup;
          }
        }
      
        static String _orderTypeToString(OrderType type) {
          switch (type) {
            case OrderType.delivery: return 'delivery';
            case OrderType.pickup: return 'pickup';
          }
        }
      
        static OrderStatus _orderStatusFromString(String status) {
          switch (status) {
            case 'pending': return OrderStatus.pending;
            case 'confirmed': return OrderStatus.confirmed;
            case 'preparing': return OrderStatus.preparing;
            case 'ready': return OrderStatus.ready;
            case 'delivering': return OrderStatus.delivering;
            case 'completed': return OrderStatus.completed;
            case 'cancelled': return OrderStatus.cancelled;
            default: return OrderStatus.pending;
          }
        }
      
        static String _orderStatusToString(OrderStatus status) {
          switch (status) {
            case OrderStatus.pending: return 'pending';
            case OrderStatus.confirmed: return 'confirmed';
            case OrderStatus.preparing: return 'preparing';
            case OrderStatus.ready: return 'ready';
            case OrderStatus.delivering: return 'delivering';
            case OrderStatus.completed: return 'completed';
            case OrderStatus.cancelled: return 'cancelled';
          }
        }
      
        // Obtenir le nom français du type de commande
        String getOrderTypeName() {
          switch (type) {
            case OrderType.delivery: return 'Livraison';
            case OrderType.pickup: return 'À emporter';
          }
        }
      
        // Obtenir le nom français du statut
        String getStatusName() {
          switch (status) {
            case OrderStatus.pending: return 'En attente';
            case OrderStatus.confirmed: return 'Confirmée';
            case OrderStatus.preparing: return 'En préparation';
            case OrderStatus.ready: return 'Prête';
            case OrderStatus.delivering: return 'En livraison';
            case OrderStatus.completed: return 'Terminée';
            case OrderStatus.cancelled: return 'Annulée';
          }
        }
      
        // Vérifier si la commande peut être annulée
        bool canBeCancelled() {
          return status == OrderStatus.pending || status == OrderStatus.confirmed;
        }
      
        // Vérifier si la commande peut être modifiée
        bool canBeModified() {
          return status == OrderStatus.pending;
        }
      }