class CameraLiveModel {
  String? status;
  List<CameraData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  CameraLiveModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  CameraLiveModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <CameraData>[];
      json['data'].forEach((v) {
        data!.add(CameraData.fromJson(v));
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

class CameraData {
  dynamic divisionIds;
  dynamic districtIds;
  dynamic departmentIds;
  String? tenderId;
  String? divisionName;
  String? workStatus;
  String? districtName;
  String? tenderNumber;
  String? channel;
  String? rtspUrl;
  String? rtmpUrl;
  String? liveUrl;
  String? mainCategory;
  String? subcategory;
  String? type;
  String? tenderFinalAwardedValue;
  String? tipsTenderId;
  String? schemeName;
  String? goPackageNo;
  String? awardedDate;
  String? contractorCompanyName;
  dynamic workCommencementDate;
  dynamic workCompletionDate;
  bool? isRtspValid;
  bool? isRtspLive;
  int? rows;
  int? dateDifference;

  CameraData({
    this.divisionIds,
    this.districtIds,
    this.departmentIds,
    this.tenderId,
    this.divisionName,
    this.workStatus,
    this.districtName,
    this.tenderNumber,
    this.channel,
    this.rtspUrl,
    this.rtmpUrl,
    this.liveUrl,
    this.mainCategory,
    this.subcategory,
    this.type,
    this.tenderFinalAwardedValue,
    this.tipsTenderId,
    this.schemeName,
    this.goPackageNo,
    this.awardedDate,
    this.contractorCompanyName,
    this.workCommencementDate,
    this.workCompletionDate,
    this.isRtspValid,
    this.isRtspLive,
    this.rows,
    this.dateDifference,
  });

  CameraData.fromJson(Map<String, dynamic> json) {
    divisionIds = json['divisionIds'];
    districtIds = json['districtIds'];
    departmentIds = json['departmentIds'];
    tenderId = json['tenderId'];
    divisionName = json['divisionName'];
    workStatus = json['workStatus'];
    districtName = json['districtName'];
    tenderNumber = json['tenderNumber'];
    channel = json['channel'];
    rtspUrl = json['rtspUrl'];
    rtmpUrl = json['rtmpUrl'];
    liveUrl = json['liveUrl'];
    mainCategory = json['mainCategory'];
    subcategory = json['subcategory'];
    type = json['type'];
    tenderFinalAwardedValue = json['tender_final_awarded_value'];
    tipsTenderId = json['tipsTender_Id'];
    schemeName = json['schemeName'];
    goPackageNo = json['go_Package_No'];
    awardedDate = json['awardedDate'];
    contractorCompanyName = json['contractorCompanyName'];
    workCommencementDate = json['workCommencementDate'];
    workCompletionDate = json['workCompletionDate'];
    isRtspValid = json['isRtspValid'];
    isRtspLive = json['isRtspLive'];
    rows = json['rows'];
    dateDifference = json['dateDifference'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['divisionIds'] = divisionIds;
    data['districtIds'] = districtIds;
    data['departmentIds'] = departmentIds;
    data['tenderId'] = tenderId;
    data['divisionName'] = divisionName;
    data['workStatus'] = workStatus;
    data['districtName'] = districtName;
    data['tenderNumber'] = tenderNumber;
    data['channel'] = channel;
    data['rtspUrl'] = rtspUrl;
    data['rtmpUrl'] = rtmpUrl;
    data['liveUrl'] = liveUrl;
    data['mainCategory'] = mainCategory;
    data['subcategory'] = subcategory;
    data['type'] = type;
    data['tender_final_awarded_value'] = tenderFinalAwardedValue;
    data['tipsTender_Id'] = tipsTenderId;
    data['schemeName'] = schemeName;
    data['go_Package_No'] = goPackageNo;
    data['awardedDate'] = awardedDate;
    data['contractorCompanyName'] = contractorCompanyName;
    data['workCommencementDate'] = workCommencementDate;
    data['workCompletionDate'] = workCompletionDate;
    data['isRtspValid'] = isRtspValid;
    data['isRtspLive'] = isRtspLive;

    data['rows'] = rows;
    data['dateDifference'] = dateDifference;
    return data;
  }
}
