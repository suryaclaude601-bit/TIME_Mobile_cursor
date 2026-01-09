class DistrictListModel {
  String? status;
  List<DistrictData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  DistrictListModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  DistrictListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <DistrictData>[];
      json['data'].forEach((v) {
        data!.add(DistrictData.fromJson(v));
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

class DistrictData {
  String? district;
  String? districtName;

  DistrictData({this.district, this.districtName});

  DistrictData.fromJson(Map<String, dynamic> json) {
    district = json['district'];
    districtName = json['districtName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['district'] = district;
    data['districtName'] = districtName;
    return data;
  }
}
