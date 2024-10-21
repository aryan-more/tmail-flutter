import 'package:equatable/equatable.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subaddressing_state.dart';

abstract class SubaddressingRequest with EquatableMixin {

  final MailboxSubaddressingState subaddressingState;
  final MailboxSubaddressingAction subaddressingAction;

  SubaddressingRequest(this.subaddressingState, this.subaddressingAction);
  
  @override
  List<Object?> get props => [subaddressingState, subaddressingAction];
}
