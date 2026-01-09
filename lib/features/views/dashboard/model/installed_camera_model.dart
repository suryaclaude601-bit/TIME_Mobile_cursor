class InstalledCameraModel {
  String? status;
  List<Data>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  InstalledCameraModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  InstalledCameraModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
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

class Data {
  String? divisionIds;
  String? districtIds;
  String? notStarted;
  String? inProgress;
  String? slowProgress;
  String? completed;
  String? startedButStilled;
  String? total;

  Data({
    this.divisionIds,
    this.districtIds,
    this.notStarted,
    this.inProgress,
    this.slowProgress,
    this.completed,
    this.startedButStilled,
    this.total,
  });

  Data.fromJson(Map<String, dynamic> json) {
    divisionIds = json['divisionIds'];
    districtIds = json['districtIds'];
    notStarted = json['notStarted'];
    inProgress = json['inProgress'];
    slowProgress = json['slowProgress'];
    completed = json['completed'];
    startedButStilled = json['startedButStilled'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['divisionIds'] = divisionIds;
    data['districtIds'] = districtIds;
    data['notStarted'] = notStarted;
    data['inProgress'] = inProgress;
    data['slowProgress'] = slowProgress;
    data['completed'] = completed;
    data['startedButStilled'] = startedButStilled;
    data['total'] = total;
    return data;
  }
}
