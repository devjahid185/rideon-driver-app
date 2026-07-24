class PaymentMethodModel {
  int? status;
  String? message;
  Data? data;
  String? error;

  PaymentMethodModel({this.status, this.message, this.data, this.error});

  PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    status = json['status'] as int?;
    message = json['message'] as String?;
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    error = json['error'] as String?;
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

class Data {
  List<PayoutTypes>? payoutTypes;

  Data({this.payoutTypes});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['payout_methods'] != null) {
      payoutTypes = (json['payout_methods'] as List)
          .map((v) => PayoutTypes.fromJson(v))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'payout_types': payoutTypes?.map((v) => v.toJson()).toList(),
    };
  }
}

class PayoutTypes {
  int? id;
  String? name;

  PayoutTypes({this.id, this.name});

  PayoutTypes.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    name = json['name'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}