class GetItemVehicleModel {
  int? status;
  String? message;
  Data? data;
  String? error;

  GetItemVehicleModel({this.status, this.message, this.data, this.error});

  GetItemVehicleModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    error = json['error'];
  }


}

class Data {
  List<Items>? items;
  int? offset;
  int? limit;
  String? hostStatus;
  int? checkLimit;

  Data({this.items, this.offset, this.limit, this.hostStatus, this.checkLimit});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      items = [];
      json['items'].forEach((v) {
        items!.add(Items.fromJson(v));
      });
    }
    offset = json['offset'];
    limit = json['limit'];
    hostStatus = json['host_status'];
    checkLimit = json['checkLimit'];
  }


}

class Items {
  int? id;
  String? token;
  String? fullTextSearch;
  String? itemRating;
  String? vehicleNumber;
  String? vehicleMake;
  String? vehicleYear;
  String? vehicleModel;
  String? vehicleType;
  String? vehicleColor;

  String? itemTypeId;
  int? subcategoryId;
  int? categoryId;
  String? serviceType;
  dynamic module;
  String? stepProgress;
  String? status;
 
  String? metaData;
  String? availableDates;
  String? itemInfo;
  FrontImage? frontImage;
  List<String>? gallery; // Changed from Null list to List<String>
  FrontImage? frontImageDoc;
  FrontImage? itemInsuranceDoc;
  FrontImage? itemDrivingLicence;

  Items({
    this.id,
    this.token,
    this.fullTextSearch,
    this.itemRating,
    this.itemTypeId,
    this.subcategoryId,
    this.vehicleNumber,
    this.vehicleMake,
    this.vehicleYear,
    this.vehicleModel,
    this.vehicleType,
    this.vehicleColor,
    this.categoryId,
    this.serviceType,
    this.module,
    this.stepProgress,
    this.status,
    
    this.metaData,
    this.availableDates,
    this.itemInfo,
    this.frontImage,
    this.gallery,
    this.frontImageDoc,
    this.itemInsuranceDoc,
    this.itemDrivingLicence,
  });

  Items.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    token = json['token'];
    fullTextSearch = json['full_text_search'];
    itemRating = json['item_rating'];
    itemTypeId = json['item_type_id'];
    subcategoryId = json['subcategory_id'];
    categoryId = json['category_id'];
    serviceType = json['service_type'];
    module = json['module'];
    stepProgress = json['step_progress'];
    status = json['status'];

    vehicleNumber = json['registration_number'];
    vehicleMake = json['make'];
    vehicleYear = json['year'];
    vehicleModel = json['model'];
    vehicleType = json['item_type']["name"];
    vehicleColor = json['color'];



    metaData = json['metaData'];
    availableDates = json['available_dates'];
    itemInfo = json['item_info'];
    frontImage = json['front_image'] != null ? FrontImage.fromJson(json['front_image']) : null;
    gallery = (json['gallery'] != null) ? List<String>.from(json['gallery']) : null;
    frontImageDoc = json['vehicle_registration_doc'] != null ? FrontImage.fromJson(json['vehicle_registration_doc']) : null;
    itemInsuranceDoc = json['vehicle_insurance_doc'] != null ? FrontImage.fromJson(json['vehicle_insurance_doc']) : null;
    itemDrivingLicence = json['item_driving_licence'] != null ? FrontImage.fromJson(json['item_driving_licence']) : null;
  }


}

class FrontImage {
  int? id;
  String? url;
  String? thumbnail;
  String? preview;
  String? originalUrl;
  String? previewUrl;

  FrontImage({
    this.id,
    this.url,
    this.thumbnail,
    this.preview,
    this.originalUrl,
    this.previewUrl,
  });

  FrontImage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    url = json['url'];
    thumbnail = json['thumbnail'];
    preview = json['preview'];
    originalUrl = json['original_url'];
    previewUrl = json['preview_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['url'] = url;
    data['thumbnail'] = thumbnail;
    data['preview'] = preview;
    data['original_url'] = originalUrl;
    data['preview_url'] = previewUrl;
    return data;
  }
}
