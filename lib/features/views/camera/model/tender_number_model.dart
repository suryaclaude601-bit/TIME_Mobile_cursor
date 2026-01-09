class TenderNumberModel {
  String? status;
  List<TenderNumberData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  TenderNumberModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  TenderNumberModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <TenderNumberData>[];
      json['data'].forEach((v) {
        data!.add(TenderNumberData.fromJson(v));
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

class TenderNumberData {
  String? tenderId;
  String? tenderNumber;

  TenderNumberData({this.tenderId, this.tenderNumber});

  TenderNumberData.fromJson(Map<String, dynamic> json) {
    tenderId = json['tenderId'];
    tenderNumber = json['tenderNumber'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tenderId'] = tenderId;
    data['tenderNumber'] = tenderNumber;
    return data;
  }
}
