import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:model/model.dart';
import 'package:better_open_file/better_open_file.dart' as open_file;
import 'package:permission_handler/permission_handler.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:share/share.dart' as share_library;
import 'package:tmail_ui_user/features/base/base_controller.dart';
import 'package:tmail_ui_user/features/base/mixin/app_loader_mixin.dart';
import 'package:tmail_ui_user/features/composer/presentation/extensions/email_action_type_extension.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/model/destination_picker_arguments.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_to_mailbox_request.dart';
import 'package:tmail_ui_user/features/email/domain/state/download_attachment_for_web_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/download_attachments_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/export_attachment_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/get_email_content_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_read_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/mark_as_email_star_state.dart';
import 'package:tmail_ui_user/features/email/domain/state/move_to_mailbox_state.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/download_attachment_for_web_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/download_attachments_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/export_attachment_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/get_email_content_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_email_read_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/mark_as_star_email_interactor.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/move_to_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/email/presentation/model/composer_arguments.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/email_address_bottom_sheet_builder.dart';
import 'package:tmail_ui_user/features/email/presentation/widgets/email_address_dialog_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/download/download_task_state.dart';
import 'package:tmail_ui_user/features/thread/presentation/model/delete_action_type.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';
import 'package:uuid/uuid.dart';

class EmailController extends BaseController with AppLoaderMixin {

  final mailboxDashBoardController = Get.find<MailboxDashBoardController>();
  final responsiveUtils = Get.find<ResponsiveUtils>();
  final imagePaths = Get.find<ImagePaths>();
  final _appToast = Get.find<AppToast>();
  final _uuid = Get.find<Uuid>();
  final _downloadManager = Get.find<DownloadManager>();

  final GetEmailContentInteractor _getEmailContentInteractor;
  final MarkAsEmailReadInteractor _markAsEmailReadInteractor;
  final DownloadAttachmentsInteractor _downloadAttachmentsInteractor;
  final DeviceManager _deviceManager;
  final ExportAttachmentInteractor _exportAttachmentInteractor;
  final MoveToMailboxInteractor _moveToMailboxInteractor;
  final MarkAsStarEmailInteractor _markAsStarEmailInteractor;
  final DownloadAttachmentForWebInteractor _downloadAttachmentForWebInteractor;

  final emailAddressExpandMode = ExpandMode.COLLAPSE.obs;
  final isDisplayFullEmailAddress = false.obs;
  final attachmentsExpandMode = ExpandMode.COLLAPSE.obs;
  final emailContents = <EmailContent>[].obs;
  final attachments = <Attachment>[].obs;
  EmailId? _currentEmailId;
  List<EmailContent>? initialEmailContents;

  late Worker emailWorker;

  final StreamController<Either<Failure, Success>> _downloadProgressStateController =
      StreamController<Either<Failure, Success>>.broadcast();
  Stream<Either<Failure, Success>> get downloadProgressState => _downloadProgressStateController.stream;

  PresentationEmail? get currentEmail => mailboxDashBoardController.selectedEmail.value;

  EmailController(
    this._getEmailContentInteractor,
    this._markAsEmailReadInteractor,
    this._downloadAttachmentsInteractor,
    this._deviceManager,
    this._exportAttachmentInteractor,
    this._moveToMailboxInteractor,
    this._markAsStarEmailInteractor,
    this._downloadAttachmentForWebInteractor,
  );

  @override
  void onInit() {
    _initWorker();
    _listenDownloadAttachmentProgressState();
    super.onInit();
  }

  @override
  void onClose() {
    _downloadProgressStateController.close();
    _clearWorker();
    super.onClose();
  }

  void _initWorker() {
    emailWorker = ever( mailboxDashBoardController.selectedEmail, (presentationEmail) {
      if (presentationEmail is PresentationEmail) {
        if (_currentEmailId != presentationEmail.id) {
          _currentEmailId = presentationEmail.id;
          _resetToOriginalValue();
          _getEmailContentAction(presentationEmail.id);
          if (!presentationEmail.hasRead) {
            markAsEmailRead(presentationEmail, ReadActions.markAsRead);
          }
        }
      }
    });
  }

  void _clearWorker() {
    emailWorker.call();
  }

  void _listenDownloadAttachmentProgressState() {
    downloadProgressState.listen((state) {
        log('EmailController::_listenDownloadAttachmentProgressState(): $state');
        state.fold(
          (failure) => null,
          (success) {
            if (success is StartDownloadAttachmentForWeb) {
              mailboxDashBoardController.addDownloadTask(
                  DownloadTaskState(
                    taskId: success.taskId,
                    attachment: success.attachment));

              if (currentOverlayContext != null &&  currentContext != null) {
                _appToast.showToastWithIcon(currentOverlayContext!,
                    message: AppLocalizations.of(currentContext!).your_download_has_started,
                    iconColor: AppColor.primaryColor,
                    icon: imagePaths.icDownload);
              }
            } else if (success is DownloadingAttachmentForWeb) {
              final percent = success.progress.round();
              log('EmailController::DownloadingAttachmentForWeb(): $percent%');

              mailboxDashBoardController.updateDownloadTask(
                  success.taskId,
                  (currentTask) {
                      final newTask = currentTask.copyWith(
                        progress: success.progress,
                        downloaded: success.downloaded,
                        total: success.total);

                      return newTask;
                  });
            }
          });
    });
  }

  void _getEmailContentAction(EmailId emailId) async {
    final accountId = mailboxDashBoardController.accountId.value;
    final baseDownloadUrl = mailboxDashBoardController.sessionCurrent?.getDownloadUrl();
    if (accountId != null && baseDownloadUrl != null) {
      consumeState(_getEmailContentInteractor.execute(accountId, emailId, baseDownloadUrl));
    }
  }

  @override
  void onDone() {
    viewState.value.fold(
      (failure) {
        if (failure is MarkAsEmailReadFailure) {
          _markAsEmailReadFailure(failure);
        } else if (failure is DownloadAttachmentsFailure) {
          _downloadAttachmentsFailure(failure);
        } else if (failure is ExportAttachmentFailure) {
          _exportAttachmentFailureAction(failure);
        } else if (failure is DownloadAttachmentForWebFailure) {
          _downloadAttachmentForWebFailureAction(failure);
        }
      },
      (success) {
        if (success is GetEmailContentSuccess) {
          _getEmailContentSuccess(success);
        } else if (success is MarkAsEmailReadSuccess) {
          _markAsEmailReadSuccess(success);
        } else if (success is ExportAttachmentSuccess) {
          _exportAttachmentSuccessAction(success);
        } else if (success is MoveToMailboxSuccess) {
          _moveToMailboxSuccess(success);
        } else if (success is MarkAsStarEmailSuccess) {
          _markAsEmailStarSuccess(success);
        } else if (success is DownloadAttachmentForWebSuccess) {
          _downloadAttachmentForWebSuccessAction(success);
        }
      });
  }

  @override
  void onError(error) {
    log('EmailController::onError(): $error');
  }

  void _getEmailContentSuccess(GetEmailContentSuccess success) {
    emailContents.value = success.emailContentsDisplayed;
    initialEmailContents = success.emailContents;
    attachments.value = success.attachments;
  }

  void _resetToOriginalValue() {
    attachmentsExpandMode.value = ExpandMode.COLLAPSE;
    emailAddressExpandMode.value = ExpandMode.COLLAPSE;
    isDisplayFullEmailAddress.value = false;
    emailContents.clear();
    initialEmailContents?.clear();
    attachments.clear();
  }

  void toggleDisplayEmailAddressAction({ExpandMode? expandMode}) {
    if (expandMode != null) {
      emailAddressExpandMode.value = expandMode;
    } else {
      final newExpandMode = emailAddressExpandMode.value == ExpandMode.EXPAND ? ExpandMode.COLLAPSE : ExpandMode.EXPAND;
      emailAddressExpandMode.value = newExpandMode;
    }

    if (emailAddressExpandMode.value == ExpandMode.COLLAPSE) {
      isDisplayFullEmailAddress.value = false;
    }
  }

  bool get isExpandEmailAddress => emailAddressExpandMode.value == ExpandMode.EXPAND;

  PresentationMailbox? getMailboxContain(PresentationEmail email) {
    return mailboxDashBoardController.searchController.isSearchEmailRunning
        ? email.findMailboxContain(mailboxDashBoardController.mapMailboxById)
        : mailboxDashBoardController.selectedMailbox.value;
  }

  void markAsEmailRead(PresentationEmail presentationEmail, ReadActions readActions) async {
    final accountId = mailboxDashBoardController.accountId.value;
    final mailboxCurrent = getMailboxContain(presentationEmail);
    if (accountId != null && mailboxCurrent != null) {
      consumeState(_markAsEmailReadInteractor.execute(accountId, presentationEmail.toEmail(), readActions));
    }
  }

  void _markAsEmailReadSuccess(Success success) {
    mailboxDashBoardController.dispatchState(Right(success));

    if (success is MarkAsEmailReadSuccess
        && success.readActions == ReadActions.markAsUnread
        && currentContext != null) {
      closeEmailView(currentContext!);
    }
  }

  void _markAsEmailReadFailure(Failure failure) {
    if (failure is MarkAsEmailReadFailure
        && failure.readActions == ReadActions.markAsUnread
        && currentContext != null) {
      closeEmailView(currentContext!);
    }
  }

  void toggleDisplayAttachmentsAction() {
    final newExpandMode = attachmentsExpandMode.value == ExpandMode.COLLAPSE
        ? ExpandMode.EXPAND
        : ExpandMode.COLLAPSE;
    attachmentsExpandMode.value = newExpandMode;
  }

  void downloadAttachments(BuildContext context, List<Attachment> attachments) async {
    final needRequestPermission = await _deviceManager.isNeedRequestStoragePermissionOnAndroid();

    if (needRequestPermission) {
      final status = await Permission.storage.status;
      switch (status) {
        case PermissionStatus.granted:
          _downloadAttachmentsAction(attachments);
          break;
        case PermissionStatus.permanentlyDenied:
          _appToast.showToast(AppLocalizations.of(context).you_need_to_grant_files_permission_to_download_attachments);
          break;
        default: {
          final requested = await Permission.storage.request();
          switch (requested) {
            case PermissionStatus.granted:
              _downloadAttachmentsAction(attachments);
              break;
            default:
              _appToast.showToast(AppLocalizations.of(context).you_need_to_grant_files_permission_to_download_attachments);
              break;
          }
        }
      }
    } else {
      _downloadAttachmentsAction(attachments);
    }
  }

  void _downloadAttachmentsAction(List<Attachment> attachments) async {
    final accountId = mailboxDashBoardController.accountId.value;
    if (accountId != null && mailboxDashBoardController.sessionCurrent != null) {
      final baseDownloadUrl = mailboxDashBoardController.sessionCurrent!.getDownloadUrl();
      consumeState(_downloadAttachmentsInteractor.execute(attachments, accountId, baseDownloadUrl));
    }
  }

  void _downloadAttachmentsFailure(DownloadAttachmentsFailure failure) {
    if (currentContext != null) {
      _appToast.showErrorToast(AppLocalizations.of(currentContext!).attachment_download_failed);
    }
  }

  void exportAttachment(BuildContext context, Attachment attachment) {
    final cancelToken = CancelToken();
    _showDownloadingFileDialog(context, attachment, cancelToken: cancelToken);
    _exportAttachmentAction(attachment, cancelToken);
  }

  void _showDownloadingFileDialog(BuildContext context, Attachment attachment, {CancelToken? cancelToken}) {
    if (cancelToken != null) {
      showCupertinoDialog(
          context: context,
          builder: (_) =>
              PointerInterceptor(child: (DownloadingFileDialogBuilder()
                    ..key(const Key('downloading_file_dialog'))
                    ..title(AppLocalizations.of(context).preparing_to_export)
                    ..content(AppLocalizations.of(context).downloading_file(attachment.name ?? ''))
                    ..actionText(AppLocalizations.of(context).cancel)
                    ..addCancelDownloadActionClick(() {
                      cancelToken.cancel([AppLocalizations.of(context).user_cancel_download_file]);
                      popBack();
                    }))
                .build()));
    } else {
      showCupertinoDialog(
          context: context,
          builder: (_) =>
              PointerInterceptor(child: (DownloadingFileDialogBuilder()
                  ..key(const Key('downloading_file_for_web_dialog'))
                  ..title(AppLocalizations.of(context).preparing_to_save)
                  ..content(AppLocalizations.of(context).downloading_file(attachment.name ?? '')))
                .build()));
    }
  }

  void _exportAttachmentAction(Attachment attachment, CancelToken cancelToken) async {
    final accountId = mailboxDashBoardController.accountId.value;
    if (accountId != null && mailboxDashBoardController.sessionCurrent != null) {
      final baseDownloadUrl = mailboxDashBoardController.sessionCurrent!.getDownloadUrl();
      consumeState(_exportAttachmentInteractor.execute(attachment, accountId, baseDownloadUrl, cancelToken));
    }
  }

  void _exportAttachmentFailureAction(ExportAttachmentFailure failure) {
    if (failure.exception is! CancelDownloadFileException) {
      popBack();
      if (currentContext != null) {
        _appToast.showErrorToast(AppLocalizations.of(currentContext!).attachment_download_failed);
      }
    }
  }

  void _exportAttachmentSuccessAction(ExportAttachmentSuccess success) async {
    popBack();
    _openDownloadedPreviewWorkGroupDocument(success.downloadedResponse);
  }

  void _openDownloadedPreviewWorkGroupDocument(DownloadedResponse downloadedResponse) async {
    log('EmailController::_openDownloadedPreviewWorkGroupDocument(): $downloadedResponse');
    if (downloadedResponse.mediaType == null) {
      await share_library.Share.shareFiles([downloadedResponse.filePath]);
    }

    final openResult = await open_file.OpenFile.open(
        downloadedResponse.filePath,
        type: Platform.isAndroid ? downloadedResponse.mediaType!.mimeType : null,
        uti: Platform.isIOS ? downloadedResponse.mediaType!.getDocumentUti().value : null);

    if (openResult.type != open_file.ResultType.done) {
      logError('EmailController::_openDownloadedPreviewWorkGroupDocument(): no preview available');
      if (currentContext != null) {
        _appToast.showErrorToast(AppLocalizations.of(currentContext!).noPreviewAvailable);
      }
    }
  }

  void downloadAttachmentForWeb(BuildContext context, Attachment attachment) {
    _downloadAttachmentForWebAction(context, attachment);
  }

  void _downloadAttachmentForWebAction(BuildContext context, Attachment attachment) async {
    final accountId = mailboxDashBoardController.accountId.value;
    if (accountId != null && mailboxDashBoardController.sessionCurrent != null) {
      final baseDownloadUrl = mailboxDashBoardController.sessionCurrent!.getDownloadUrl();
      final generateTaskId = DownloadTaskId(_uuid.v4());
      consumeState(_downloadAttachmentForWebInteractor.execute(
          generateTaskId,
          attachment,
          accountId,
          baseDownloadUrl,
          _downloadProgressStateController));
    }
  }

  void _downloadAttachmentForWebSuccessAction(DownloadAttachmentForWebSuccess success) {
    log('EmailController::_downloadAttachmentForWebSuccessAction():');
    mailboxDashBoardController.deleteDownloadTask(success.taskId);

    _downloadManager.createAnchorElementDownloadFileWeb(
        success.bytes,
        success.attachment.generateFileName());
  }

  void _downloadAttachmentForWebFailureAction(DownloadAttachmentForWebFailure failure) {
    log('EmailController::_downloadAttachmentForWebFailureAction(): $failure');
    mailboxDashBoardController.deleteDownloadTask(failure.taskId);

    if (currentOverlayContext != null &&  currentContext != null) {
      _appToast.showToastWithIcon(currentOverlayContext!,
          message: AppLocalizations.of(currentContext!).attachment_download_failed,
          bgColor: AppColor.toastErrorBackgroundColor,
          textColor: Colors.white,
          iconColor: Colors.white,
          icon: imagePaths.icDownload);
    }
  }

  void moveToMailbox(BuildContext context, PresentationEmail email) async {
    final currentMailbox = getMailboxContain(email);
    final accountId = mailboxDashBoardController.accountId.value;

    if (currentMailbox != null && accountId != null) {
      final destinationMailbox = await push(
        AppRoutes.DESTINATION_PICKER,
        arguments: DestinationPickerArguments(accountId, MailboxActions.moveEmail)
      );

      if (destinationMailbox != null && destinationMailbox is PresentationMailbox) {
        if (destinationMailbox.isTrash) {
          _moveToTrashAction(context, accountId, MoveToMailboxRequest(
              [email.id],
              currentMailbox.id,
              destinationMailbox.id,
              MoveAction.moving,
              EmailActionType.moveToTrash));
        } else if (destinationMailbox.isSpam) {
          _moveToSpamAction(context, accountId, MoveToMailboxRequest(
              [email.id],
              currentMailbox.id,
              destinationMailbox.id,
              MoveAction.moving,
              EmailActionType.moveToSpam));
        } else {
          _moveToMailbox(accountId, MoveToMailboxRequest(
              [email.id],
              currentMailbox.id,
              destinationMailbox.id,
              MoveAction.moving,
              EmailActionType.moveToMailbox,
              destinationPath: destinationMailbox.mailboxPath));
        }
      }
    }
  }

  void _moveToMailbox(AccountId accountId, MoveToMailboxRequest moveRequest) {
    consumeState(_moveToMailboxInteractor.execute(accountId, moveRequest));
  }

  void _moveToMailboxSuccess(MoveToMailboxSuccess success) {
    mailboxDashBoardController.dispatchState(Right(success));

    if (success.moveAction == MoveAction.moving && currentContext != null && currentOverlayContext != null) {
      _appToast.showToastWithAction(
          currentOverlayContext!,
          success.emailActionType.getToastMessageMoveToMailboxSuccess(currentContext!, destinationPath: success.destinationPath),
          AppLocalizations.of(currentContext!).undo_action, () {
        _revertedToOriginalMailbox(MoveToMailboxRequest(
              [success.emailId],
              success.destinationMailboxId,
              success.currentMailboxId,
              MoveAction.undo,
              success.emailActionType));
          },
        maxWidth: responsiveUtils.getMaxWidthToast(currentContext!)
      );
    }
  }

  void _revertedToOriginalMailbox(MoveToMailboxRequest newMoveRequest) {
    final accountId = mailboxDashBoardController.accountId.value;
    if (accountId != null) {
      _moveToMailbox(accountId, newMoveRequest);
    }
  }

  void moveToTrash(BuildContext context, PresentationEmail email) async {
    final accountId = mailboxDashBoardController.accountId.value;
    final trashMailboxId = mailboxDashBoardController.getMailboxIdByRole(PresentationMailbox.roleTrash);
    final currentMailbox = getMailboxContain(email);

    if (accountId != null && currentMailbox != null && trashMailboxId != null) {
      _moveToTrashAction(context, accountId, MoveToMailboxRequest(
        [email.id],
        currentMailbox.id,
        trashMailboxId,
        MoveAction.moving,
        EmailActionType.moveToTrash)
      );
    }
  }

  void _moveToTrashAction(BuildContext context, AccountId accountId, MoveToMailboxRequest moveRequest) {
    closeEmailView(context);
    mailboxDashBoardController.moveToMailbox(accountId, moveRequest);
  }

  void moveToSpam(BuildContext context, PresentationEmail email) async {
    final accountId = mailboxDashBoardController.accountId.value;
    final spamMailboxId = mailboxDashBoardController.getMailboxIdByRole(PresentationMailbox.roleSpam);
    final currentMailbox = getMailboxContain(email);

    if (accountId != null && currentMailbox != null && spamMailboxId != null) {
      _moveToSpamAction(context, accountId, MoveToMailboxRequest(
          [email.id],
          currentMailbox.id,
          spamMailboxId,
          MoveAction.moving,
          EmailActionType.moveToSpam)
      );
    }
  }

  void unSpam(BuildContext context, PresentationEmail email) async {
    final accountId = mailboxDashBoardController.accountId.value;
    final spamMailboxId = mailboxDashBoardController.getMailboxIdByRole(PresentationMailbox.roleSpam);
    final inboxMailboxId = mailboxDashBoardController.getMailboxIdByRole(PresentationMailbox.roleInbox);

    if (accountId != null && spamMailboxId != null && inboxMailboxId != null) {
      _moveToSpamAction(context, accountId, MoveToMailboxRequest(
          [email.id],
          spamMailboxId,
          inboxMailboxId,
          MoveAction.moving,
          EmailActionType.unSpam)
      );
    }
  }

  void _moveToSpamAction(BuildContext context, AccountId accountId, MoveToMailboxRequest moveRequest) {
    closeEmailView(context);
    mailboxDashBoardController.moveToMailbox(accountId, moveRequest);
  }

  void markAsStarEmail(PresentationEmail presentationEmail, MarkStarAction markStarAction) async {
    final accountId = mailboxDashBoardController.accountId.value;
    final mailboxCurrent = getMailboxContain(presentationEmail);
    if (accountId != null && mailboxCurrent != null) {
      consumeState(_markAsStarEmailInteractor.execute(accountId, presentationEmail.toEmail(), markStarAction));
    }
  }

  void _markAsEmailStarSuccess(Success success) {
    if (success is MarkAsStarEmailSuccess) {
      mailboxDashBoardController.setSelectedEmail(success.updatedEmail.toPresentationEmail(selectMode: SelectMode.ACTIVE));
    }
    mailboxDashBoardController.dispatchState(Right(success));
  }

  void handleEmailAction(BuildContext context, PresentationEmail presentationEmail, EmailActionType actionType) {
    switch(actionType) {
      case EmailActionType.markAsUnread:
        popBack();
        markAsEmailRead(presentationEmail, ReadActions.markAsUnread);
        break;
      case EmailActionType.markAsStarred:
        markAsStarEmail(presentationEmail, MarkStarAction.markStar);
        break;
      case EmailActionType.unMarkAsStarred:
        markAsStarEmail(presentationEmail, MarkStarAction.unMarkStar);
        break;
      case EmailActionType.moveToMailbox:
        moveToMailbox(context, presentationEmail);
        break;
      case EmailActionType.moveToTrash:
        moveToTrash(context, presentationEmail);
        break;
      case EmailActionType.deletePermanently:
        deleteEmailPermanently(context, presentationEmail);
        break;
      case EmailActionType.moveToSpam:
        popBack();
        moveToSpam(context, presentationEmail);
        break;
      case EmailActionType.unSpam:
        popBack();
        unSpam(context, presentationEmail);
        break;
      default:
        break;
    }
  }

  void showFullEmailAddress() {
    isDisplayFullEmailAddress.value = true;
  }

  void openEmailAddressDialog(BuildContext context, EmailAddress emailAddress) {
    if (responsiveUtils.isScreenWithShortestSide(context)) {
      (EmailAddressBottomSheetBuilder(context, imagePaths, emailAddress)
          ..addOnCloseContextMenuAction(() => popBack())
          ..addOnCopyEmailAddressAction((emailAddress) => copyEmailAddress(context, emailAddress))
          ..addOnComposeEmailAction((emailAddress) => composeEmailFromEmailAddress(emailAddress)))
        .show();
    } else {
      showDialog(
          context: context,
          barrierColor: AppColor.colorDefaultCupertinoActionSheet,
          builder: (BuildContext context) => PointerInterceptor(child: (EmailAddressDialogBuilder(context, imagePaths, emailAddress)
              ..addOnCloseContextMenuAction(() => popBack())
              ..addOnCopyEmailAddressAction((emailAddress) => copyEmailAddress(context, emailAddress))
              ..addOnComposeEmailAction((emailAddress) => composeEmailFromEmailAddress(emailAddress)))
            .build()));
    }
  }

  void copyEmailAddress(BuildContext context, EmailAddress emailAddress) {
    popBack();

    Clipboard.setData(ClipboardData(text: emailAddress.emailAddress)).then((_){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).email_address_copied_to_clipboard))
      );
    });
  }

  void composeEmailFromEmailAddress(EmailAddress emailAddress) {
    popBack();

    final arguments = ComposerArguments(
        emailActionType: EmailActionType.composeFromEmailAddress,
        emailAddress: emailAddress,
        mailboxRole: mailboxDashBoardController.selectedMailbox.value?.role);

    mailboxDashBoardController.goToComposer(arguments);
  }

  void openMailToLink(Uri? uri) {
    log('EmailController::openMailToLink(): ${uri.toString()}');
    String address = uri?.path ?? '';
    log('EmailController::openMailToLink(): address: $address');
    if (address.isNotEmpty) {
      final emailAddress = EmailAddress(null, address);
      final arguments = ComposerArguments(
          emailActionType: EmailActionType.composeFromEmailAddress,
          emailAddress: emailAddress,
          mailboxRole: mailboxDashBoardController.selectedMailbox.value?.role);

      mailboxDashBoardController.goToComposer(arguments);

      if (BuildUtils.isWeb && Get.currentRoute == AppRoutes.EMAIL) {
        popBack();
      }
    }
  }

  void deleteEmailPermanently(BuildContext context, PresentationEmail email) {
    if (responsiveUtils.isMobile(context)) {
      (ConfirmationDialogActionSheetBuilder(context)
          ..messageText(DeleteActionType.single.getContentDialog(context))
          ..onCancelAction(AppLocalizations.of(context).cancel, () => popBack())
          ..onConfirmAction(DeleteActionType.single.getConfirmActionName(context), () => _deleteEmailPermanentlyAction(context, email)))
        .show();
    } else {
      showDialog(
          context: context,
          barrierColor: AppColor.colorDefaultCupertinoActionSheet,
          builder: (BuildContext context) => PointerInterceptor(child: (ConfirmDialogBuilder(imagePaths)
              ..key(const Key('confirm_dialog_delete_email_permanently'))
              ..title(DeleteActionType.single.getTitleDialog(context))
              ..content(DeleteActionType.single.getContentDialog(context))
              ..addIcon(SvgPicture.asset(imagePaths.icRemoveDialog, fit: BoxFit.fill))
              ..colorConfirmButton(AppColor.colorConfirmActionDialog)
              ..styleTextConfirmButton(const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColor.colorActionDeleteConfirmDialog))
              ..onCloseButtonAction(() => popBack())
              ..onConfirmButtonAction(DeleteActionType.single.getConfirmActionName(context), () => _deleteEmailPermanentlyAction(context, email))
              ..onCancelButtonAction(AppLocalizations.of(context).cancel, () => popBack()))
            .build()));
    }
  }

  void _deleteEmailPermanentlyAction(BuildContext context, PresentationEmail email) {
    popBack();
    closeEmailView(context);
    mailboxDashBoardController.deleteEmailPermanently(email);
  }

  void closeEmailView(BuildContext context) {
    mailboxDashBoardController.clearSelectedEmail();

    if (mailboxDashBoardController.searchController.isSearchEmailRunning) {
      if (responsiveUtils.isWebDesktop(context)) {
        mailboxDashBoardController.dispatchRoute(AppRoutes.THREAD);
      } else {
        mailboxDashBoardController.dispatchRoute(AppRoutes.SEARCH_EMAIL);
      }
    } else {
      mailboxDashBoardController.dispatchRoute(AppRoutes.THREAD);
    }
  }

  void pressEmailAction(EmailActionType emailActionType) {
    if (emailActionType == EmailActionType.compose) {
      mailboxDashBoardController.goToComposer(ComposerArguments());
      if (BuildUtils.isWeb && Get.currentRoute == AppRoutes.EMAIL) {
        popBack();
      }
    } else {
      final arguments = ComposerArguments(
          emailActionType: emailActionType,
          presentationEmail: mailboxDashBoardController.selectedEmail.value!,
          emailContents: initialEmailContents,
          attachments: emailActionType == EmailActionType.forward ? attachments : null,
          mailboxRole: mailboxDashBoardController.selectedMailbox.value?.role);

      mailboxDashBoardController.goToComposer(arguments);
      if (BuildUtils.isWeb && Get.currentRoute == AppRoutes.EMAIL) {
        popBack();
      }
    }
  }
}