class DriverWalletModel {
  int? status;
  String? message;
  WalletData? data;
  String? error;

  DriverWalletModel({this.status, this.message, this.data, this.error});

  DriverWalletModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? WalletData.fromJson(json['data']) : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
      'error': error,
    };
  }
}

class WalletData {
  List<DriverRide>? driverRides;
  int? offset;
  dynamic totalRides;
  dynamic totalEarnings;

  WalletData({this.driverRides, this.offset, this.totalRides, this.totalEarnings});

  WalletData.fromJson(Map<String, dynamic> json) {
    if (json['driverRides'] != null) {
      driverRides = [];
      json['driverRides'].forEach((v) {
        driverRides!.add(DriverRide.fromJson(v));
      });
    }
    offset = json['offset'];
    totalRides = json['totalRides'];
    totalEarnings = json['totalEarnings'];
  }

  Map<String, dynamic> toJson() {
    return {
      'driverRides': driverRides?.map((v) => v.toJson()).toList(),
      'offset': offset,
      'totalRides': totalRides,
      'totalEarnings': totalEarnings,
    };
  }
}
class DriverRide {
  int? id;
  String? rideDate;
  String? status;
  String? vendorCommission;
  String? total;
  String? token;

  DriverRide({this.id, this.rideDate, this.status, this.vendorCommission, this.total,this.token});

  DriverRide.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    rideDate = json['ride_date'];
    status = json['status'];
    vendorCommission = json['vendor_commission'];
    total = json['total'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_date': rideDate,
      'status': status,
      'vendor_commission': vendorCommission,
      'total': total,
      'token': token,
    };
  }
}
