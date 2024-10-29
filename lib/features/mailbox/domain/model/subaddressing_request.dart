import 'package:equatable/equatable.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_state.dart';

class SubaddressingRequest with EquatableMixin {

  final MailboxSubaddressingState subaddressingState;
  final MailboxSubaddressingAction subaddressingAction;
  final MailboxId mailboxId;
  final Map<String, List<String>?>? currentRights;

  SubaddressingRequest(
      this.mailboxId,
      this.currentRights,
      this.subaddressingState,
      this.subaddressingAction
  );

  @override
  List<Object?> get props => [
    mailboxId,
    currentRights,
    subaddressingState,
    subaddressingAction,
  ];
}
