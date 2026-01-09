class DivisionListModel {
  String? status;
  List<DivisionData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  DivisionListModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  DivisionListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <DivisionData>[];
      json['data'].forEach((v) {
        data!.add(DivisionData.fromJson(v));
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

class DivisionData {
  String? division;
  String? divisionName;

  DivisionData({this.division, this.divisionName});

  DivisionData.fromJson(Map<String, dynamic> json) {
    division = json['division'];
    divisionName = json['divisionName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['division'] = division;
    data['divisionName'] = divisionName;
    return data;
  }
}
