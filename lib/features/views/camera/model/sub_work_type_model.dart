class SubWorkTypeModel {
  String? status;
  List<SubWorkTypeData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  SubWorkTypeModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  SubWorkTypeModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <SubWorkTypeData>[];
      json['data'].forEach((v) {
        data!.add(SubWorkTypeData.fromJson(v));
      });
    }
    message = json['message'];
    errorCode = json['errorCode'];
    totalRecordCount = json['totalRecordCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = message;
    data['errorCode'] = errorCode;
    data['totalRecordCount'] = totalRecordCount;
    return data;
  }
}

class SubWorkTypeData {
  String? subCategory;

  SubWorkTypeData({this.subCategory});

  SubWorkTypeData.fromJson(Map<String, dynamic> json) {
    subCategory = json['subcategory'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['subcategory'] = subCategory;
    return data;
  }
}
