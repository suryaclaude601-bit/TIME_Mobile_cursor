import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streaming_dashboard/core/config/log_service.dart';
import 'package:streaming_dashboard/core/config/shared_preferences/shared_preference_service.dart';
import 'package:streaming_dashboard/core/constants/api_constants.dart';
import 'package:streaming_dashboard/core/constants/api_endpoints.dart';
import 'package:streaming_dashboard/core/constants/app_strings.dart';
import 'package:streaming_dashboard/features/views/profile/model/profile_model.dart';
import 'package:streaming_dashboard/services/api_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final userGroupController = TextEditingController();
  final roleNameController = TextEditingController();

  bool isLoading = false;
  String? userId;
  String? errorMessage;
  ProfileModel? profileModel;

  Future<void> fetchUserInfo(BuildContext context) async {
    userId = await SharedPreferenceService.getUserId();
    if (!context.mounted) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners(); // If using ChangeNotifier
    try {
      final token = await SharedPreferenceService.getInstance();
      String? accessToken = await token.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        isLoading = false;
        errorMessage = AppStrings.ksTokenNotFound;
        notifyListeners();
        // Navigate to login
        if (context.mounted) {
          context.go('/login');
        }
        return;
      }
      ApiService.instance.setAccessToken(accessToken);
      //Cal the Get method from Apiservice
      final apiResponse = await ApiService.instance.get(
        endpoint:
            '${ApiConstants.baseUrl}${ApiEndpoints.profileInfoAPI}?IsActive=true&UserId=$userId',
        fromJson: (json) => ProfileModel.fromJson(json),
      );
      if (!context.mounted) return;
      if (apiResponse.isSuccess == true && apiResponse.data != null) {
        isLoading = false;
        profileModel = apiResponse.data;
        firstNameController.text = profileModel?.data?.first.firstName ?? '';
        lastNameController.text = profileModel?.data?.first.lastName ?? '';
        emailController.text = profileModel?.data?.first.email ?? '';
        phoneController.text = profileModel?.data?.first.mobile ?? '';
        lastNameController.text = profileModel?.data?.first.lastName ?? '';
        userGroupController.text =
            profileModel?.data?.first.userGroupName ?? '';
        roleNameController.text = profileModel?.data?.first.roleName ?? '';
        notifyListeners();
        return;
      }
      LogService.debug(
        '✅ ${AppStrings.ksDataLoadedSuccessfully} ${apiResponse.isSuccess}',
      );
    } catch (e) {
      isLoading = false;
      errorMessage = '${AppStrings.ksFailedToFetch} $e';
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void showAndroidAlertDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text(
        AppStrings.ksCancel,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget continueButton = TextButton(
      child: Text(
        AppStrings.ksLogout,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      onPressed: () async {
        Navigator.pop(context);
        if (context.mounted) {
          SharedPreferenceService.getInstance().then((prefs) {
            prefs.saveLoginStatus(false);
            prefs.logout();
            context.go('/login'); // Changed from push to go
          });
        }
      },
    );

    AlertDialog alert = AlertDialog(
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      title: Text(
        AppStrings.ksLogout,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      content: Text(
        '${AppStrings.ksLogoutHint}?',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black87,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      actions: [cancelButton, continueButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void showiOSAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            AppStrings.ksLogout,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          content: Text(
            '${AppStrings.ksLogoutHint}?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
              fontSize: 13,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                AppStrings.ksCancel,
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
                AppStrings.ksLogout,
                style: TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                if (context.mounted) {
                  SharedPreferenceService.getInstance().then((prefs) {
                    prefs.saveLoginStatus(false);
                    prefs.logout();
                    // ignore: use_build_context_synchronously
                    context.go('/login'); // Changed from push to go
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
