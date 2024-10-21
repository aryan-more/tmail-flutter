import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subaddressing_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/repository/mailbox_repository.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subaddressing_mailbox_state.dart';

class SubaddressingMailboxInteractor {
  final MailboxRepository _mailboxRepository;

  SubaddressingMailboxInteractor(this._mailboxRepository);

  Stream<Either<Failure, Success>> execute(Session session, AccountId accountId, SubaddressingMailboxRequest request) async* {
    try {
      yield Right<Failure, Success>(LoadingSubaddressingMailbox());

      final currentMailboxState = await _mailboxRepository.getMailboxState(session, accountId);

      final result = await _mailboxRepository.subaddressingMailbox(session, accountId, request);

      if (result) {
        yield Right<Failure, Success>(SubaddressingMailboxSuccess(
          request.mailboxId, 
          currentMailboxState: currentMailboxState,
          request.subaddressingAction));
      } else {
        yield Left<Failure, Success>(SubaddressingMailboxFailure(null));
      }

    } catch (exception) {
      yield Left<Failure, Success>(SubaddressingMailboxFailure(exception));
    }
  }
}