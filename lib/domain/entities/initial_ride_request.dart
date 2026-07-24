class InitialRideRequest {
  final String rideId;
  final String pickupLocation;
  final String dropoffLocation;
  final String userId;
  final Customer customer;
  final ParcalData parcalData;
  final String travelCharges;
  final String status;
  final String travelDistance;
  final String travelTime;
  final String playerId;

  InitialRideRequest({
    required this.rideId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.userId,
    required this.customer,
    required this.parcalData,
    required this.travelCharges,
    required this.status,
    required this.travelDistance,
    required this.travelTime,
    required this.playerId ,
  });

  factory InitialRideRequest.fromJson(Map<String, dynamic> json) {
    return InitialRideRequest(
      rideId: _asString(json['rideId']),
      pickupLocation: _asString(json['pickupLocation']),
      dropoffLocation: _asString(json['dropoffLocation']),
      userId: _asString(json['userId']),
      customer: Customer.fromJson(_asMap(json['customer'])),
      parcalData: ParcalData.fromJson(_asMap(json['parcelData'])),
      travelCharges: _asString(json['travelCharges']),
      status: _asString(json['status']),
      travelDistance: _asString(json['travelDistance']),
      travelTime: _asString(json['travelTime']),
      playerId: _asString(json['playerId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'userId': userId,
      'customer': customer.toJson(),
      'travelCharges': travelCharges,
      'status': status,
      'travelDistance': travelDistance,
      'travelTime': travelTime,
      'playerId': playerId,
    };
  }
}

class Customer {
  final String userName;
  final String userPhone;
  final String? userPhoto;
  final String userRating;

  Customer({
    required this.userName,
    required this.userPhone,
    this.userPhoto,
    required this.userRating,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      userName: _asString(json['userName']),
      userPhone: _asString(json['userPhone']),
      userPhoto: json['userPhoto']?.toString(),
      userRating: _asString(json['userRating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userPhone': userPhone,
      'userPhoto': userPhoto,
      'userRating': userRating,
    };
  }
}

class ParcalData {
  final String? name;
  final String? weight;
  final String? reciverName;
  final String? reciverNumber;
  final String? instruction;

  ParcalData({
    this.name,
      this.weight,
    this.reciverName,
     this.reciverNumber,
     this.instruction,
  });

  factory ParcalData.fromJson(Map<String, dynamic> json) {
    return ParcalData(
      name: _asString(json['name']),
      weight: _asString(json['weight']),
      reciverName: json['receiverName']?.toString(),
      reciverNumber: json['receiverPhone']?.toString(),
      instruction: _asString(json['pickupInstructions']),
    );
  }

  
  
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}
