import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subaddressing_request.dart';

class SubaddressingMailboxRequest extends SubaddressingRequest {

  final MailboxId mailboxId;
  final Map<String, List<String>?>? currentRights;

  SubaddressingMailboxRequest(
    this.mailboxId,
    this.currentRights,
    MailboxSubaddressingState subaddressingState,
    MailboxSubaddressingAction subaddressingAction,
  ) : super(subaddressingState, subaddressingAction);
  
  @override
  List<Object?> get props => [
    mailboxId,
    super.props
  ];
}
