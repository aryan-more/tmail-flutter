import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:tmail_ui_user/features/base/state/ui_action_state.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_action.dart';

class LoadingSubaddressingMailbox extends UIState {}

class SubaddressingMailboxSuccess extends UIActionState {
  final MailboxId mailboxId;
  final MailboxSubaddressingAction subaddressingAction;

  SubaddressingMailboxSuccess(
    this.mailboxId, 
    this.subaddressingAction,
    {
      jmap.State? currentEmailState,
      jmap.State? currentMailboxState,
    }
  ) : super(currentEmailState, currentMailboxState);

  @override
  List<Object?> get props => [
    mailboxId,
    subaddressingAction,
    ...super.props
  ];
}

class SubaddressingMailboxFailure extends FeatureFailure {

  SubaddressingMailboxFailure(dynamic exception) : super(exception: exception);
}