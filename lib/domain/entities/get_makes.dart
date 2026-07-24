class GetMakeModel {
  GetMakeModel({
    num? status,
    String? message,
    Data? data,
    String? error,
  }) {
    _status = status;
    _message = message;
    _data = data;
    _error = error;
  }
  GetMakeModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
    _error = json['error'];
  }
  num? _status;
  String? _message;
  Data? _data;
  String? _error;

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
    List<MakeTypes>? makesTypes,
  }) {
    _makesTypes = makesTypes;
  }

  Data.fromJson(dynamic json) {
    if (json['makes'] != null) {
      _makesTypes = [];
      json['makes'].forEach((v) {
        _makesTypes?.add(MakeTypes.fromJson(v));
      });
    }
  }
  List<MakeTypes>? _makesTypes;
  List<MakeTypes>? get makesTypes => _makesTypes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_makesTypes != null) {
      map['makes'] = _makesTypes?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class MakeTypes {
  MakeTypes({
    num? id,
    String? name,
    String? description,
    String? status,
    dynamic image,
    List<Models>? models,
  }) {
    _id = id;
    _name = name;
    _description = description;
    _status = status;
    _models = models;
  }

  MakeTypes.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _description = json['description'];
    _status = json['status'];
    _models = json['models'] != null ? List.from(json['models']).map((e) => Models.fromJson(e)).toList() : null;
  }

  num? _id;
  String? _name;
  String? _description;
  String? _status;
  List<Models>? _models;

  List<Models>? get models => _models;
  num? get id => _id;
  String? get name => _name;
  String? get description => _description;
  String? get status => _status;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['description'] = _description;
    map['status'] = _status;
    if (_models != null) {
      map['models'] = _models?.map((e) => e.toJson()).toList();
    }
    return map;
  }
}

class Models {
  Models({
    num? id,
    dynamic makeId,
    String? name,
    String? description,
    String? status,
    List<Models>? models,
  }) {
    _id = id;
    _name = name;
    _makeId = makeId;
    _description = description;
    _status = status;
  }

  Models.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _makeId = json['make_id'];
    _description = json['description'];
    _status = json['status'];
  }

  num? _id;
  dynamic _makeId;
  String? _name;
  String? _description;
  String? _status;
  dynamic _image;

  dynamic get makeId => _makeId;
  num? get id => _id;
  String? get name => _name;
  String? get description => _description;
  String? get status => _status;
  dynamic get image => _image;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['description'] = _description;
    map['status'] = _status;
    map['make_id'] = _makeId;
    return map;
  }
}