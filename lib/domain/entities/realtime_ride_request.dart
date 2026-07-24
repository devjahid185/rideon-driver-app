class RealTimeRideRequest {
  String? otp;
  String? adminCommission;
  String? rideId;
  String? bookingId;
  String? selectedDriverId;
  String? rideStatusLabel;
  Location? pickupLocation;
  Location? dropoffLocation;
  String? status;
  String? userId;
  Customer? customer;
  Driver? driver;
  String? driverPayment;
  String? totalDistance;
  String? distanceRemain;
  String? totalTime;
  String? timeRemain;
  String? tax;
  String? paymentStatus;
  String? paymentMethod;
  String? travelCharges;
  VehicleDetails? vehicleDetails;
  FeedbackData? customerFeedback;
  FeedbackData? driverFeedback;
  ParcalData? parcalData;
  String? driverConfirmedPayment;
  String? riderConfirmedPayment;
  String? timestamp;
  String? playerId;

  RealTimeRideRequest();

  RealTimeRideRequest.fromMap(Map<dynamic, dynamic>? map) {
    otp = map?['OTP'];
    adminCommission = map?['adminCommission'];
    rideId = map?['rideId'];
    bookingId = map?['bookingId'];
    selectedDriverId = map?['selectedDriverId'];
    rideStatusLabel = map?['rideStatusLabel'];
    pickupLocation = Location.fromMap(map?['pickupLocation']);
    dropoffLocation = Location.fromMap(map?['dropoffLocation']);
    status = map?['status'];
    userId = map?['userId'];
    customer = Customer.fromMap(map?['customer']);
    driver = Driver.fromMap(map?['driver']);
    driverPayment = map?['driverPayment'];
    totalDistance = map?['totalDistance'];
    distanceRemain = map?['distanceRemain'];
    totalTime = map?['totalTime'];
    timeRemain = map?['timeRemain'];
    tax = map?['tax'];
    paymentStatus = map?['paymentStatus'];
    paymentMethod = map?['paymentMethod'];
    travelCharges = map?['travelCharges'];
    vehicleDetails = VehicleDetails.fromMap(map?['vehicleDetails']);
    customerFeedback = FeedbackData.fromMap(map?['customerFeeback']);
    driverFeedback = FeedbackData.fromMap(map?['driverFeeback']);
    parcalData = ParcalData.fromMap(map?['parcelData']);
    driverConfirmedPayment = map?['driverConfirmedPayment'];
    riderConfirmedPayment = map?['riderConfirmedPayment'];
    timestamp = map?['timestamp'];
    playerId = map?['playerId'];
  }

  Map<String, dynamic> toJson() {
  return {
    'OTP': otp,
    'adminCommission': adminCommission,
    'rideId': rideId,
    'bookingId': bookingId,
    'selectedDriverId': selectedDriverId,
    'rideStatusLabel': rideStatusLabel,
    'pickupLocation': pickupLocation?.toJson(),
    'dropoffLocation': dropoffLocation?.toJson(),
    'status': status,
    'userId': userId,
    'customer': customer?.toJson(),
    'driver': driver?.toJson(),
    'driverPayment': driverPayment,
    'totalDistance': totalDistance,
    'distanceRemain': distanceRemain,
    'totalTime': totalTime,
    'timeRemain': timeRemain,
    'tax': tax,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod,
    'travelCharges': travelCharges,
    'vehicleDetails': vehicleDetails?.toJson(),
    'customerFeeback': customerFeedback?.toJson(),
    'driverFeeback': driverFeedback?.toJson(),
    'parcelData': parcalData?.toJson(),
    'driverConfirmedPayment': driverConfirmedPayment,
    'riderConfirmedPayment': riderConfirmedPayment,
    'timestamp': timestamp,
    'playerId': playerId,
  };
}


setTotalTime(value){
   totalTime=value;
}

}

class Location {
  double? lat;
  double? lng;
  String? pickupAddress;
  String? dropoffAddress;

  Location();

  Location.fromMap(Map<dynamic, dynamic>? map) {
    lat = (map?['lat'] as num?)?.toDouble();
    lng = (map?['lng'] as num?)?.toDouble();
    pickupAddress = map?['pickupAddress'];
    dropoffAddress = map?['dropoffAddress'];
  }
  Map<String, dynamic> toJson() {
  return {
    'lat': lat,
    'lng': lng,
    'pickupAddress': pickupAddress,
    'dropoffAddress': dropoffAddress,
  };
}
}

class Customer {
  String? userName;
  String? userPhone;
  String? userPhoto;
  String? userRating;
  String? userPhoneCountry;

  Customer();

  Customer.fromMap(Map<dynamic, dynamic>? map) {
    userName = map?['userName'];
    userPhone = map?['userPhone'];
    userPhoto = map?['userPhoto'];
    userRating = map?['userRating'];
    userPhoneCountry = map?['userPhoneCountry'];
  }
  Map<String, dynamic> toJson() {
  return {
    'userName': userName,
    'userPhone': userPhone,
    'userPhoto': userPhoto,
    'userRating': userRating,
    'userPhoneCountry': userPhoneCountry,
  };
}

}

class Driver {
  String? driverName;
  String? driverPhone;
  String? driverPhoto;
  String? driverRating;

  Driver();

  Driver.fromMap(Map<dynamic, dynamic>? map) {
    driverName = map?['driverName'];
    driverPhone = map?['driverPhone'];
    driverPhoto = map?['driverPhoto'];
    driverRating = map?['driverRating'];
  }
  Map<String, dynamic> toJson() {
  return {
    'driverName': driverName,
    'driverPhone': driverPhone,
    'driverPhoto': driverPhoto,
    'driverRating': driverRating,
  };
}
}

class VehicleDetails {
  String? itemId;
  String? itemTypeName;
  String? vehicleNumber;
  String? vehicleMake;
  String? vehicleModel;

  VehicleDetails();

  VehicleDetails.fromMap(Map<dynamic, dynamic>? map) {
    itemId = map?['itemId'].toString();
    itemTypeName = map?['itemTypeName'];
    vehicleNumber = map?['vehicleNumber'];
    vehicleMake = map?['vehicleMake'];
    vehicleModel = map?['vehicleModel'];
  }
  Map<String, dynamic> toJson() {
  return {
    'itemId': itemId,
    'itemTypeName': itemTypeName,
    'vehicleNumber': vehicleNumber,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
  };
}
}

class FeedbackData {
  String? rating;
  String? review;

  FeedbackData();

  FeedbackData.fromMap(Map<dynamic, dynamic>? map) {
    rating = map?['rating'];
    review = map?['review'];
  }
  Map<String, dynamic> toJson() {
  return {
    'rating': rating,
    'review': review,
  };
}
}
class ParcalData {
  String? name;
  String? weight;
  String? reciverName;
  String? reciverNumber;
  String? instruction;

  ParcalData();
  ParcalData.fromMap(Map<dynamic, dynamic>? map) {
    name = map?['name'];
    weight = map?['weight'];
    reciverName = map?['receiverName'];
    reciverNumber = map?['receiverPhone'];
    instruction = map?['pickupInstructions'];
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'receiverName': reciverName,
      'receiverPhone': reciverNumber,
      'pickupInstructions': instruction,
    };
  }
}
