class FetchItemId {
  int? status;
  String? message;
  Data? data;
  String? error;

  FetchItemId({this.status, this.message, this.data, this.error});

  FetchItemId.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['error'] = error;
    return data;
  }
}

class Data {
  String? useridId;
  String? itemTypeId;
  dynamic description;
  String? itemRating;
  String? status;
  dynamic address;
  dynamic stateRegion;
  dynamic zipPostalCode;
  dynamic cityName;
  dynamic country;
  dynamic latitude;
  dynamic longitude;
  String? token;
  String? module;
  String? fullTextSearch;
  String? updatedAt;
  String? createdAt;
  int? id;
  dynamic frontImage;

  dynamic frontImageDoc;
  dynamic itemDrivingLicence;
  dynamic itemDriverAuthorization;
  dynamic itemHireServiceLicence;
  dynamic itemInspectionCertificate;
  List<dynamic>? media;

  Data(
      {this.useridId,
      this.itemTypeId,
      this.description,
      this.itemRating,
      this.status,
      this.address,
      this.stateRegion,
      this.zipPostalCode,
      this.cityName,
      this.country,
      this.latitude,
      this.longitude,
      this.token,
      this.module,
      this.fullTextSearch,
      this.updatedAt,
      this.createdAt,
      this.id,
      this.frontImage,
      this.frontImageDoc,
      this.itemDrivingLicence,
      this.itemDriverAuthorization,
      this.itemHireServiceLicence,
      this.itemInspectionCertificate,
      this.media});

  Data.fromJson(Map<String, dynamic> json) {
    useridId = json['userid_id'];
    itemTypeId = json['item_type_id'];
    description = json['description'];
    itemRating = json['item_rating'];
    status = json['status'];
    address = json['address'];
    stateRegion = json['state_region'];
    zipPostalCode = json['zip_postal_code'];
    cityName = json['city_name'];
    country = json['country'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    token = json['token'];
    module = json['module'];
    fullTextSearch = json['full_text_search'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
    frontImage = json['front_image'];
    frontImageDoc = json['vehicle_registration_doc'];
    itemDrivingLicence = json['vehicle_driving_licence'];
    itemDriverAuthorization = json['driver_authorization'];
    itemHireServiceLicence = json['hire_service_licence'];
    itemInspectionCertificate = json['inspection_certificate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userid_id'] = useridId;
    data['item_type_id'] = itemTypeId;
    data['description'] = description;
    data['item_rating'] = itemRating;
    data['status'] = status;
    data['address'] = address;
    data['state_region'] = stateRegion;
    data['zip_postal_code'] = zipPostalCode;
    data['city_name'] = cityName;
    data['country'] = country;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['token'] = token;
    data['module'] = module;
    data['full_text_search'] = fullTextSearch;
    data['updated_at'] = updatedAt;
    data['created_at'] = createdAt;
    data['id'] = id;
    data['front_image'] = frontImage;
    data['vehicle_registration_doc'] = frontImageDoc;
    data['driving_licence'] = itemDrivingLicence;
    data['driver_authorization'] = itemDriverAuthorization;
    data['hire_service_licence'] = itemHireServiceLicence;
    data['inspection_certificate'] = itemInspectionCertificate;

    return data;
  }
}
