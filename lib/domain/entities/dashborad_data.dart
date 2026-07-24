class DashboardModel {
  int? status;
  String? message;
  DashboardData? data;
  String? error;

  DashboardModel({this.status, this.message, this.data, this.error});

  DashboardModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? DashboardData.fromJson(json['data']) : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    result['status'] = status;
    result['message'] = message;
    if (data != null) {
      result['data'] = data!.toJson();
    }
    result['error'] = error;
    return result;
  }
}

class DashboardData {
  dynamic totalOrders;
  String? totalEarnings;
  double? averageRating;

  DashboardData({this.totalOrders, this.totalEarnings, this.averageRating});

  DashboardData.fromJson(Map<String, dynamic> json) {
    totalOrders = json['total_orders'];
    totalEarnings = json['total_earnings'];
    averageRating = (json['average_rating'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'total_orders': totalOrders,
      'total_earnings': totalEarnings,
      'average_rating': averageRating,
    };
  }
}
