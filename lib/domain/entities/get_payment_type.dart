class GetPaymentTypeModel {
  final int? status;
  final String? message;
  final Data? data;
  final String? error;

  GetPaymentTypeModel({
    this.status,
    this.message,
    this.data,
    this.error,
  });

  factory GetPaymentTypeModel.fromJson(Map<String, dynamic> json) {
    return GetPaymentTypeModel(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
      error: json['error'] as String?,
    );
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
  final List<PayoutMethod>? payoutMethods;


  Data({this.payoutMethods, });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      payoutMethods: (json['payout_methods'] as List<dynamic>?)
          ?.map((e) => PayoutMethod.fromJson(e as Map<String, dynamic>))
          .toList(),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payout_methods': payoutMethods?.map((e) => e.toJson()).toList(),
   
    };
  }
}

class PayoutMethod {
  final int? id;
  final String? payoutMethod;
  final PaymentDetails? details;


  PayoutMethod({this.id, this.payoutMethod, this.details,});

  factory PayoutMethod.fromJson(Map<String, dynamic> json) {
    return PayoutMethod(
      id: json['id'] as int?,
      payoutMethod: json['payout_method'] as String?,
      details: json['details'] != null
          ? PaymentDetails.fromJson(json['details'] as Map<String, dynamic>)
          : null,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payout_method': payoutMethod,
      'details': details?.toJson(),
 
    };
  }
}

class PaymentDetails {
  final int? id;
    final int? isActive;
  final String? email;
  final String? note;
  final String? userId;
  final String? accountName;
  final String? bankName;
  final String? branchName;
  final String? accountNumber;
  final String? iban;
  final String? swiftCode;
  final String? createdAt;
  final String? updatedAt;

  PaymentDetails({
    this.id,
        this.isActive,
    this.email,
    this.note,
    this.userId,
    this.accountName,
    this.bankName,
    this.branchName,
    this.accountNumber,
    this.iban,
    this.swiftCode,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      id: json['id'] as int?,
            isActive: json['is_active'] as int?,
      email: json['email'] as String?,
      note: json['note'] as String?,
      userId: json['user_id'] as String?,
      accountName: json['account_name'] as String?,
      bankName: json['bank_name'] as String?,
      branchName: json['branch_name'] as String?,
      accountNumber: json['account_number'] as String?,
      iban: json['iban'] as String?,
      swiftCode: json['swift_code'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'note': note,
      'user_id': userId,
      'account_name': accountName,
      'bank_name': bankName,
      'branch_name': branchName,
      'account_number': accountNumber,
      'iban': iban,
      'swift_code': swiftCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
