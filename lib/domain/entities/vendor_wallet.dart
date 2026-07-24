

class VendorWallet {
  VendorWallet({
      num? status, 
      String? message, 
      Data? data, 
      String? error,}){
    _status = status;
    _message = message;
    _data = data;
    _error = error;
}

  VendorWallet.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
    _error = json['error'];
  }
  num? _status;
  String? _message;
  Data? _data;
  String? _error;
VendorWallet copyWith({  num? status,
  String? message,
  Data? data,
  String? error,
}) => VendorWallet(  status: status ?? _status,
  message: message ?? _message,
  data: data ?? _data,
  error: error ?? _error,
);
  num? get status => _status;
  String? get message => _message;
  Data? get data => _data;
  String? get error => _error;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    map['error'] = _error;
    return map;
  }

}



class Data {
  Data({
      String? walletBalance, 
      String? pendingToWithdrawl, 
      String? totalWithdrawled, 
      String? totalEarning, 
      String? refunded,
      String? incomingAmount,
      String? pendingPayout
      }){
    _walletBalance = walletBalance;
    _pendingToWithdrawl = pendingToWithdrawl;
    _totalWithdrawled = totalWithdrawled;
    _totalEarning = totalEarning;
    _refunded = refunded;
    _incomingAmount = incomingAmount;
    _pendingPayout = pendingPayout;
}

  Data.fromJson(dynamic json) {
    _walletBalance = json['walletBalance'];
    _pendingToWithdrawl = json['pendingToWithdrawl'];
    _totalWithdrawled = json['totalWithdrawled'];
    _totalEarning = json['totalEarning'];
    _refunded = json['refunded'];
    _incomingAmount = json['incoming_amount'];
    _pendingPayout = json['pendingPayout'];
  }
  String? _walletBalance;
  String? _pendingToWithdrawl;
  String? _totalWithdrawled;
  String? _totalEarning;
  String? _refunded;
  String? _incomingAmount;
  String? _pendingPayout;
Data copyWith({  String? walletBalance,
  String? pendingToWithdrawl,
  String? totalWithdrawled,
  String? totalEarning,
  String? refunded,
  String? incomingAmount,
  String? pendingPayout
}) => Data(  walletBalance: walletBalance ?? _walletBalance,
  pendingToWithdrawl: pendingToWithdrawl ?? _pendingToWithdrawl,
  totalWithdrawled: totalWithdrawled ?? _totalWithdrawled,
  totalEarning: totalEarning ?? _totalEarning,
  refunded: refunded ?? _refunded,
  incomingAmount: incomingAmount ?? _incomingAmount,
    pendingPayout: pendingPayout ?? _pendingPayout
);
  String? get walletBalance => _walletBalance;
  String? get pendingToWithdrawl => _pendingToWithdrawl;
  String? get totalWithdrawled => _totalWithdrawled;
  String? get totalEarning => _totalEarning;
  String? get refunded => _refunded;
  String? get incomingAmount => _incomingAmount;
  String? get pendingPayout => _pendingPayout;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['walletBalance'] = _walletBalance;
    map['pendingToWithdrawl'] = _pendingToWithdrawl;
    map['totalWithdrawled'] = _totalWithdrawled;
    map['totalEarning'] = _totalEarning;
    map['refunded'] = _refunded;
    map['incoming_amount'] = _incomingAmount;
    map['pendingPayout'] = _pendingPayout;
    return map;
  }

}