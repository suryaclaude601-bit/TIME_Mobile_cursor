class WorkTypeModel {
  String? status;
  List<WorkTypeData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  WorkTypeModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  WorkTypeModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <WorkTypeData>[];
      json['data'].forEach((v) {
        data!.add(WorkTypeData.fromJson(v));
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

class WorkTypeData {
  String? mainCategory;

  WorkTypeData({this.mainCategory});

  WorkTypeData.fromJson(Map<String, dynamic> json) {
    mainCategory = json['mainCategory'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mainCategory'] = mainCategory;
    return data;
  }
}
