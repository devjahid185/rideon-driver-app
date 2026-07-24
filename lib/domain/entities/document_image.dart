
class DocumentImageModel {
  int? status;
  String? message;
  Data? data;
  String? error;

  DocumentImageModel({this.status, this.message, this.data, this.error});

  DocumentImageModel.fromJson(Map<String, dynamic> json) {
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
  DrivingLicenceFront? drivingLicenceFront;
  DrivingLicenceBack? drivingLicenceBack;

  DriverIdFront?driverIdFront;
  DriverIdBack?driverIdBack;


  DriverAuthorization? driverAuthorization;
  HireServiceLicence? hireServiceLicence;
  InspectionCertificate? inspectionCertificate;

  Data(
      {this.drivingLicenceFront,
      this.drivingLicenceBack,
      this.driverIdFront,
      this.driverIdBack,

      this.driverAuthorization,
      this.hireServiceLicence,
      this.inspectionCertificate});

  Data.fromJson(Map<String, dynamic> json) {
    drivingLicenceFront = json['driving_licence_front'] != null
        ? DrivingLicenceFront.fromJson(json['driving_licence_front'])
        : null;
    drivingLicenceBack = json['driving_licence_back'] != null
        ? DrivingLicenceBack.fromJson(json['driving_licence_back'])
        : null;
    driverIdFront = json['driver_id_front'] != null
        ? DriverIdFront.fromJson(json['driver_id_front'])
        : null;
    driverIdBack = json['driver_id_back'] != null
        ? DriverIdBack.fromJson(json['driver_id_back'])
        : null;


    driverAuthorization = json['driver_authorization'] != null
        ? DriverAuthorization.fromJson(json['driver_authorization'])
        : null;
    hireServiceLicence = json['hire_service_licence'] != null
        ? HireServiceLicence.fromJson(json['hire_service_licence'])
        : null;
    inspectionCertificate = json['inspection_certificate'] != null
        ? InspectionCertificate.fromJson(json['inspection_certificate'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (drivingLicenceFront != null) {
      data['driving_licence_front'] = drivingLicenceFront!.toJson();
    }if (drivingLicenceBack != null) {
      data['driving_licence_back'] = drivingLicenceBack!.toJson();
    }

    if (driverIdFront != null) {
      data['driver_id_front'] = driverIdFront!.toJson();
    }if (driverIdBack != null) {
      data['driver_id_back'] = driverIdBack!.toJson();
    }
    if (driverAuthorization != null) {
      data['driver_authorization'] = driverAuthorization!.toJson();
    }
    if (hireServiceLicence != null) {
      data['hire_service_licence'] = hireServiceLicence!.toJson();
    }
    if (inspectionCertificate != null) {
      data['inspection_certificate'] = inspectionCertificate!.toJson();
    }
    return data;
  }
}

class DrivingLicenceFront {
  String? drivingLicenceImage;
  String? drivingLicenceStatus;

  DrivingLicenceFront({this.drivingLicenceImage,this.drivingLicenceStatus});

  DrivingLicenceFront.fromJson(Map<String, dynamic> json) {
    drivingLicenceImage = json['driving_licence_front_image'];
    drivingLicenceStatus = json['driving_licence_front_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['driving_licence_front_image'] = drivingLicenceImage;
    data['driving_licence_front_status'] = drivingLicenceStatus;
    return data;
  }
}
class DrivingLicenceBack {

  String? drivingLicenceImageBack;
  String? drivingLicenceBackStatus;

  DrivingLicenceBack({this.drivingLicenceImageBack,this.drivingLicenceBackStatus});

  DrivingLicenceBack.fromJson(Map<String, dynamic> json) {
    drivingLicenceImageBack = json['driving_licence_back_image'];
    drivingLicenceBackStatus = json['driving_licence_back_status'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['driving_licence_back_image'] = drivingLicenceImageBack;
    data['driving_licence_back_status'] = drivingLicenceBackStatus;

    return data;
  }
}

class DriverIdFront {
  String? driverIdFrontImage;

  String? driverIdFrontImageStatus;

  DriverIdFront(
      {this.driverIdFrontImage, this.driverIdFrontImageStatus});

  DriverIdFront.fromJson(Map<String, dynamic> json) {
    driverIdFrontImage = json['driver_id_front_image'];
     driverIdFrontImageStatus = json['driver_id_front_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['driver_id_front_image'] = driverIdFrontImage;
    data['driver_id_front_status'] = driverIdFrontImageStatus;
     return data;
  }
}
class DriverIdBack {
  String? driverIdBackImage;

  String? driverIdBackImageStatus;

  DriverIdBack(
      {this.driverIdBackImage, this.driverIdBackImageStatus});

  DriverIdBack.fromJson(Map<String, dynamic> json) {
    driverIdBackImage = json['driver_id_back_image'];
    driverIdBackImageStatus = json['driver_id_back_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['driver_id_back_image'] = driverIdBackImage;
    data['driver_id_back_status'] = driverIdBackImageStatus;
     return data;
  }
}

class DriverAuthorization {
  String? driverAuthorizationImage;
  String? driverAuthorizationImageBack;
  String? driverAuthorizationStatus;

  DriverAuthorization(
      {this.driverAuthorizationImage, this.driverAuthorizationStatus,driverAuthorizationImageBack});

  DriverAuthorization.fromJson(Map<String, dynamic> json) {
    driverAuthorizationImage = json['driver_authorization_image'];
    driverAuthorizationImageBack = json['driver_authorization_image'];
    driverAuthorizationStatus = json['driver_authorization_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['driver_authorization_image'] = driverAuthorizationImage;
    data['driver_authorization_image'] = driverAuthorizationImageBack;
    data['driver_authorization_status'] = driverAuthorizationStatus;
    return data;
  }
}

class HireServiceLicence {
  String? hireServiceLicenceImage;
  String? hireServiceLicenceStatus;

  HireServiceLicence(
      {this.hireServiceLicenceImage, this.hireServiceLicenceStatus});

  HireServiceLicence.fromJson(Map<String, dynamic> json) {
    hireServiceLicenceImage = json['hire_service_licence_image'];
    hireServiceLicenceStatus = json['hire_service_licence_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hire_service_licence_image'] = hireServiceLicenceImage;
    data['hire_service_licence_status'] = hireServiceLicenceStatus;
    return data;
  }
}

class InspectionCertificate {
  String? inspectionCertificateImage;
  String? inspectionCertificateStatus;

  InspectionCertificate(
      {this.inspectionCertificateImage, this.inspectionCertificateStatus});

  InspectionCertificate.fromJson(Map<String, dynamic> json) {
    inspectionCertificateImage = json['inspection_certificate_image'];
    inspectionCertificateStatus = json['inspection_certificate_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['inspection_certificate_image'] = inspectionCertificateImage;
    data['inspection_certificate_status'] = inspectionCertificateStatus;
    return data;
  }
}


