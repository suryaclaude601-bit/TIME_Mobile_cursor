class ProfileModel {
  String? status;
  List<ProfileData>? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  ProfileModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  ProfileModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <ProfileData>[];
      json['data'].forEach((v) {
        data!.add(ProfileData.fromJson(v));
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

class ProfileData {
  String? userId;
  String? userNumber;
  String? firstName;
  String? lastName;
  String? email;
  bool? isContractor;
  bool? isActive;
  String? roleId;
  String? prefix;
  String? suffix;
  int? runningNumber;
  String? mobile;
  String? divisionId;
  String? userGroup;
  String? dob;
  String? districtId;
  String? pofileImageId;
  String? loginId;
  List<String>? divisionIdList;
  List<String>? districtIdList;
  List<String>? departmentIdList;
  String? district;
  String? division;
  String? userGroupName;
  String? userGroupCode;
  String? roleCode;
  String? roleName;
  String? departmentId;
  String? department;
  String? password;
  String? lastUpdatedBy;
  String? lastUpdatedUserName;
  String? lastUpdatedDate;

  ProfileData({
    this.userId,
    this.userNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.isContractor,
    this.isActive,
    this.roleId,
    this.prefix,
    this.suffix,
    this.runningNumber,
    this.mobile,
    this.divisionId,
    this.userGroup,
    this.dob,
    this.districtId,
    this.pofileImageId,
    this.loginId,
    this.divisionIdList,
    this.districtIdList,
    this.departmentIdList,
    this.district,
    this.division,
    this.userGroupName,
    this.userGroupCode,
    this.roleCode,
    this.roleName,
    this.departmentId,
    this.department,
    this.password,
    this.lastUpdatedBy,
    this.lastUpdatedUserName,
    this.lastUpdatedDate,
  });

  ProfileData.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userNumber = json['userNumber'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    isContractor = json['isContractor'];
    isActive = json['isActive'];
    roleId = json['roleId'];
    prefix = json['prefix'];
    suffix = json['suffix'];
    runningNumber = json['runningNumber'];
    mobile = json['mobile'];
    divisionId = json['divisionId'];
    userGroup = json['userGroup'];
    dob = json['dob'];
    districtId = json['districtId'];
    pofileImageId = json['pofileImageId'];
    loginId = json['loginId'];
    divisionIdList = json['divisionIdList'].cast<String>();
    districtIdList = json['districtIdList'].cast<String>();
    departmentIdList = json['departmentIdList'].cast<String>();
    district = json['district'];
    division = json['division'];
    userGroupName = json['userGroupName'];
    userGroupCode = json['userGroupCode'];
    roleCode = json['roleCode'];
    roleName = json['roleName'];
    departmentId = json['departmentId'];
    department = json['department'];
    password = json['password'];
    lastUpdatedBy = json['lastUpdatedBy'];
    lastUpdatedUserName = json['lastUpdatedUserName'];
    lastUpdatedDate = json['lastUpdatedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userNumber'] = userNumber;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['email'] = email;
    data['isContractor'] = isContractor;
    data['isActive'] = isActive;
    data['roleId'] = roleId;
    data['prefix'] = prefix;
    data['suffix'] = suffix;
    data['runningNumber'] = runningNumber;
    data['mobile'] = mobile;
    data['divisionId'] = divisionId;
    data['userGroup'] = userGroup;
    data['dob'] = dob;
    data['districtId'] = districtId;
    data['pofileImageId'] = pofileImageId;
    data['loginId'] = loginId;
    data['divisionIdList'] = divisionIdList;
    data['districtIdList'] = districtIdList;
    data['departmentIdList'] = departmentIdList;
    data['district'] = district;
    data['division'] = division;
    data['userGroupName'] = userGroupName;
    data['userGroupCode'] = userGroupCode;
    data['roleCode'] = roleCode;
    data['roleName'] = roleName;
    data['departmentId'] = departmentId;
    data['department'] = department;
    data['password'] = password;
    data['lastUpdatedBy'] = lastUpdatedBy;
    data['lastUpdatedUserName'] = lastUpdatedUserName;
    data['lastUpdatedDate'] = lastUpdatedDate;
    return data;
  }
}
