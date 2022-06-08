
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:model/model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tmail_ui_user/features/base/reloadable/reloadable_controller.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/delete_authority_oidc_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/state/get_user_profile_state.dart';
import 'package:tmail_ui_user/features/manage_account/domain/usecases/log_out_oidc_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/model/account_menu_item.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/model/manage_account_arguments.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';

class ManageAccountDashBoardController extends ReloadableController {

  final _responsiveUtils = Get.find<ResponsiveUtils>();

  final menuDrawerKey = GlobalKey<ScaffoldState>(debugLabel: 'manage_account');

  final appInformation = Rxn<PackageInfo>();
  final userProfile = Rxn<UserProfile>();
  final accountId = Rxn<AccountId>();
  final accountMenuItemSelected = AccountMenuItem.profiles.obs;

  Session? sessionCurrent;

  ManageAccountDashBoardController(
    LogoutOidcInteractor logoutOidcInteractor,
    DeleteAuthorityOidcInteractor deleteAuthorityOidcInteractor
  ) : super(logoutOidcInteractor, deleteAuthorityOidcInteractor);

  @override
  void onReady() {
    _getArguments();
    _getAppVersion();
    super.onReady();
  }

  @override
  void onDone() {
    viewState.value.fold(
      (failure) {},
      (success) {
        if (success is GetUserProfileSuccess) {
          userProfile.value = success.userProfile;
        }
      }
    );
  }

  @override
  void onError(error) {
  }

  @override
  void handleReloaded(Session session) {
    sessionCurrent = session;
    accountId.value = session.accounts.keys.first;
    _getUserProfile();
  }

  void _getArguments() {
    final arguments = Get.arguments;
    log('ManageAccountDashBoardController::_getAccountIdAndUserProfile(): $arguments');
    if (arguments is ManageAccountArguments) {
      sessionCurrent = arguments.session;
      accountId.value = sessionCurrent?.accounts.keys.first;
      _getUserProfile();
    } else {
      if (kIsWeb) {
        reload();
      }
    }
  }

  Future<void> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    log('MailboxDashBoardController::_getAppVersion(): ${info.version}');
    appInformation.value = info;
  }

  void _getUserProfile() async {
    userProfile.value = sessionCurrent != null ? UserProfile(sessionCurrent!.username.value) : null;
  }

  void openMenuDrawer() {
    menuDrawerKey.currentState?.openDrawer();
  }

  void closeMenuDrawer() {
    menuDrawerKey.currentState?.openEndDrawer();
  }

  bool get isMenuDrawerOpen => menuDrawerKey.currentState?.isDrawerOpen == true;

  void selectAccountMenuItem(AccountMenuItem newAccountMenuItem) {
    accountMenuItemSelected.value = newAccountMenuItem;
    if (currentContext != null && !_responsiveUtils.isDesktop(currentContext!)) {
      closeMenuDrawer();
    }
  }

  void goToSettings() {
    pushAndPop(AppRoutes.MANAGE_ACCOUNT,
        arguments: ManageAccountArguments(sessionCurrent));
  }

  void backToMailboxDashBoard() {
    if (currentContext != null && !_responsiveUtils.isDesktop(currentContext!)) {
      closeMenuDrawer();
    }
    popBack();
  }
}