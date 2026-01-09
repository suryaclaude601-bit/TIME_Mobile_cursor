class WorkStatusModel {
  String? status;
  List<WorkStatusData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  WorkStatusModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  WorkStatusModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <WorkStatusData>[];
      json['data'].forEach((v) {
        data!.add(WorkStatusData.fromJson(v));
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

class WorkStatusData {
  String? workStatus;

  WorkStatusData({this.workStatus});

  WorkStatusData.fromJson(Map<String, dynamic> json) {
    workStatus = json['workStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['workStatus'] = workStatus;
    return data;
  }
}
