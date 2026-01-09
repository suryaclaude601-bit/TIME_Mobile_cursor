class DashboardCountModel {
  String? status;
  DashboardCountData? data;
  String? message;
  String? errorCode;
  int? totalRecordCount;

  DashboardCountModel({
    this.status,
    this.data,
    this.message,
    this.errorCode,
    this.totalRecordCount,
  });

  DashboardCountModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    data = json['data'] != null
        ? DashboardCountData.fromJson(json['data'])
        : null;
    message = json['message'];
    errorCode = json['errorCode'];
    totalRecordCount = json['totalRecordCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = message;
    data['errorCode'] = errorCode;
    data['totalRecordCount'] = totalRecordCount;
    return data;
  }
}

class DashboardCountData {
  dynamic projectFinished;
  dynamic projectOnGoing;
  dynamic projectOnHold;
  dynamic projectUpcoming;
  dynamic projectSlowprogress;
  dynamic totalProject;
  dynamic projectFinishedAmount;
  dynamic projectOnGoingAmount;
  dynamic projectOnHoldAmount;
  dynamic projectUpcomingAmount;
  dynamic projectSlowprogressAmount;
  dynamic totalProjectAmount;
  dynamic projectFinishedAmountText;
  String? projectOnGoingAmountText;
  String? projectOnHoldAmountText;
  String? projectUpcomingAmountText;
  String? projectSlowprogressAmountText;
  String? totalProjectAmountText;
  dynamic mbookApproved;
  dynamic mbookInApproval;
  dynamic mbookUpcoming;
  dynamic mbookRejected;
  dynamic totalMbooks;
  dynamic mbookNotUploaded;
  dynamic mbookUploaded;
  dynamic mbookNoActionTaken;
  dynamic mbookPaymentPending;
  dynamic mbookApprovedAmount;
  dynamic mbookInApprovalAmount;
  dynamic mbookUpcomingAmount;
  dynamic mbookRejectedAmount;
  dynamic mbookNotUploadedAmount;
  dynamic mbookUploadedAmount;
  dynamic mbookNoActionTakenAmount;
  dynamic mbookPaymentPendingAmount;
  dynamic mbookTotalAmount;
  String? mbookApprovedAmountText;
  String? mbookInApprovalAmountText;
  String? mbookUpcomingAmountText;
  String? mbookRejectedAmountText;
  String? mbookTotalAmountText;
  String? mbookNotUploadedAmountText;
  String? mbookUploadedAmountText;
  String? mbookNoActionTakenAmountText;
  String? mbookPaymentPendingAmountText;

  DashboardCountData({
    this.projectFinished,
    this.projectOnGoing,
    this.projectOnHold,
    this.projectUpcoming,
    this.projectSlowprogress,
    this.totalProject,
    this.projectFinishedAmount,
    this.projectOnGoingAmount,
    this.projectOnHoldAmount,
    this.projectUpcomingAmount,
    this.projectSlowprogressAmount,
    this.totalProjectAmount,
    this.projectFinishedAmountText,
    this.projectOnGoingAmountText,
    this.projectOnHoldAmountText,
    this.projectUpcomingAmountText,
    this.projectSlowprogressAmountText,
    this.totalProjectAmountText,
    this.mbookApproved,
    this.mbookInApproval,
    this.mbookUpcoming,
    this.mbookRejected,
    this.totalMbooks,
    this.mbookNotUploaded,
    this.mbookUploaded,
    this.mbookNoActionTaken,
    this.mbookPaymentPending,
    this.mbookApprovedAmount,
    this.mbookInApprovalAmount,
    this.mbookUpcomingAmount,
    this.mbookRejectedAmount,
    this.mbookNotUploadedAmount,
    this.mbookUploadedAmount,
    this.mbookNoActionTakenAmount,
    this.mbookPaymentPendingAmount,
    this.mbookTotalAmount,
    this.mbookApprovedAmountText,
    this.mbookInApprovalAmountText,
    this.mbookUpcomingAmountText,
    this.mbookRejectedAmountText,
    this.mbookTotalAmountText,
    this.mbookNotUploadedAmountText,
    this.mbookUploadedAmountText,
    this.mbookNoActionTakenAmountText,
    this.mbookPaymentPendingAmountText,
  });

  DashboardCountData.fromJson(Map<String, dynamic> json) {
    projectFinished = json['project_Finished'];
    projectOnGoing = json['project_OnGoing'];
    projectOnHold = json['project_OnHold'];
    projectUpcoming = json['project_Upcoming'];
    projectSlowprogress = json['project_Slowprogress'];
    totalProject = json['total_Project'];
    projectFinishedAmount = json['project_Finished_Amount'];
    projectOnGoingAmount = json['project_OnGoing_Amount'];
    projectOnHoldAmount = json['project_OnHold_Amount'];
    projectUpcomingAmount = json['project_Upcoming_Amount'];
    projectSlowprogressAmount = json['project_Slowprogress_Amount'];
    totalProjectAmount = json['total_Project_Amount'];
    projectFinishedAmountText = json['project_Finished_Amount_Text'];
    projectOnGoingAmountText = json['project_OnGoing_Amount_Text'];
    projectOnHoldAmountText = json['project_OnHold_Amount_Text'];
    projectUpcomingAmountText = json['project_Upcoming_Amount_Text'];
    projectSlowprogressAmountText = json['project_Slowprogress_Amount_Text'];
    totalProjectAmountText = json['total_Project_Amount_Text'];
    mbookApproved = json['mbook_Approved'];
    mbookInApproval = json['mbook_InApproval'];
    mbookUpcoming = json['mbook_Upcoming'];
    mbookRejected = json['mbook_Rejected'];
    totalMbooks = json['totalMbooks'];
    mbookNotUploaded = json['mbook_NotUploaded'];
    mbookUploaded = json['mbook_Uploaded'];
    mbookNoActionTaken = json['mbook_No_Action_Taken'];
    mbookPaymentPending = json['mbook_PaymentPending'];
    mbookApprovedAmount = json['mbook_Approved_Amount'];
    mbookInApprovalAmount = json['mbook_InApproval_Amount'];
    mbookUpcomingAmount = json['mbook_Upcoming_Amount'];
    mbookRejectedAmount = json['mbook_Rejected_Amount'];
    mbookNotUploadedAmount = json['mbook_NotUploaded_Amount'];
    mbookUploadedAmount = json['mbook_Uploaded_Amount'];
    mbookNoActionTakenAmount = json['mbook_No_Action_Taken_Amount'];
    mbookPaymentPendingAmount = json['mbook_PaymentPending_Amount'];
    mbookTotalAmount = json['mbook_Total_Amount'];
    mbookApprovedAmountText = json['mbook_Approved_Amount_Text'];
    mbookInApprovalAmountText = json['mbook_InApproval_Amount_Text'];
    mbookUpcomingAmountText = json['mbook_Upcoming_Amount_Text'];
    mbookRejectedAmountText = json['mbook_Rejected_Amount_Text'];
    mbookTotalAmountText = json['mbook_Total_Amount_Text'];
    mbookNotUploadedAmountText = json['mbook_NotUploaded_Amount_Text'];
    mbookUploadedAmountText = json['mbook_Uploaded_Amount_Text'];
    mbookNoActionTakenAmountText = json['mbook_No_Action_Taken_Amount_Text'];
    mbookPaymentPendingAmountText = json['mbook_PaymentPending_Amount_Text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['project_Finished'] = projectFinished;
    data['project_OnGoing'] = projectOnGoing;
    data['project_OnHold'] = projectOnHold;
    data['project_Upcoming'] = projectUpcoming;
    data['project_Slowprogress'] = projectSlowprogress;
    data['total_Project'] = totalProject;
    data['project_Finished_Amount'] = projectFinishedAmount;
    data['project_OnGoing_Amount'] = projectOnGoingAmount;
    data['project_OnHold_Amount'] = projectOnHoldAmount;
    data['project_Upcoming_Amount'] = projectUpcomingAmount;
    data['project_Slowprogress_Amount'] = projectSlowprogressAmount;
    data['total_Project_Amount'] = totalProjectAmount;
    data['project_Finished_Amount_Text'] = projectFinishedAmountText;
    data['project_OnGoing_Amount_Text'] = projectOnGoingAmountText;
    data['project_OnHold_Amount_Text'] = projectOnHoldAmountText;
    data['project_Upcoming_Amount_Text'] = projectUpcomingAmountText;
    data['project_Slowprogress_Amount_Text'] = projectSlowprogressAmountText;
    data['total_Project_Amount_Text'] = totalProjectAmountText;
    data['mbook_Approved'] = mbookApproved;
    data['mbook_InApproval'] = mbookInApproval;
    data['mbook_Upcoming'] = mbookUpcoming;
    data['mbook_Rejected'] = mbookRejected;
    data['totalMbooks'] = totalMbooks;
    data['mbook_NotUploaded'] = mbookNotUploaded;
    data['mbook_Uploaded'] = mbookUploaded;
    data['mbook_No_Action_Taken'] = mbookNoActionTaken;
    data['mbook_PaymentPending'] = mbookPaymentPending;
    data['mbook_Approved_Amount'] = mbookApprovedAmount;
    data['mbook_InApproval_Amount'] = mbookInApprovalAmount;
    data['mbook_Upcoming_Amount'] = mbookUpcomingAmount;
    data['mbook_Rejected_Amount'] = mbookRejectedAmount;
    data['mbook_NotUploaded_Amount'] = mbookNotUploadedAmount;
    data['mbook_Uploaded_Amount'] = mbookUploadedAmount;
    data['mbook_No_Action_Taken_Amount'] = mbookNoActionTakenAmount;
    data['mbook_PaymentPending_Amount'] = mbookPaymentPendingAmount;
    data['mbook_Total_Amount'] = mbookTotalAmount;
    data['mbook_Approved_Amount_Text'] = mbookApprovedAmountText;
    data['mbook_InApproval_Amount_Text'] = mbookInApprovalAmountText;
    data['mbook_Upcoming_Amount_Text'] = mbookUpcomingAmountText;
    data['mbook_Rejected_Amount_Text'] = mbookRejectedAmountText;
    data['mbook_Total_Amount_Text'] = mbookTotalAmountText;
    data['mbook_NotUploaded_Amount_Text'] = mbookNotUploadedAmountText;
    data['mbook_Uploaded_Amount_Text'] = mbookUploadedAmountText;
    data['mbook_No_Action_Taken_Amount_Text'] = mbookNoActionTakenAmountText;
    data['mbook_PaymentPending_Amount_Text'] = mbookPaymentPendingAmountText;
    return data;
  }
}
