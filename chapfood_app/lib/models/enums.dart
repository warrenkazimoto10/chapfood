enum OrderStatus {
  pending('pending'),
  accepted('accepted'),
  readyForDelivery('ready_for_delivery'),
  pickedUp('picked_up'),
  inTransit('in_transit'),
  delivered('delivered'),
  cancelled('cancelled');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'ready_for_delivery':
        return OrderStatus.readyForDelivery;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

enum DeliveryType {
  delivery('delivery'),
  pickup('pickup');

  const DeliveryType(this.value);
  final String value;

  static DeliveryType fromString(String value) {
    switch (value) {
      case 'delivery':
        return DeliveryType.delivery;
      case 'pickup':
        return DeliveryType.pickup;
      default:
        return DeliveryType.delivery;
    }
  }
}

enum PaymentMethod {
  cash('cash'),
  card('card'),
  mobile('mobile');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'mobile':
        return PaymentMethod.mobile;
      default:
        return PaymentMethod.cash;
    }
  }
}

enum SupplementType {
  garniture('garniture'),
  extra('extra');

  const SupplementType(this.value);
  final String value;

  static SupplementType fromString(String value) {
    switch (value) {
      case 'garniture':
        return SupplementType.garniture;
      case 'extra':
        return SupplementType.extra;
      default:
        return SupplementType.garniture;
    }
  }
}
