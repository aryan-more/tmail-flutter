
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:model/extensions/account_id_extensions.dart';
import 'package:tmail_ui_user/features/caching/state_cache_client.dart';
import 'package:tmail_ui_user/features/caching/utils/cache_utils.dart';
import 'package:tmail_ui_user/features/mailbox/data/datasource/state_datasource.dart';
import 'package:tmail_ui_user/features/mailbox/data/model/state_cache.dart';
import 'package:tmail_ui_user/features/mailbox/data/model/state_type.dart';
import 'package:tmail_ui_user/features/mailbox/data/extensions/state_cache_extension.dart';
import 'package:tmail_ui_user/main/exceptions/exception_thrower.dart';

class StateDataSourceImpl extends StateDataSource {

  final StateCacheClient _stateCacheClient;
  final ExceptionThrower _exceptionThrower;

  StateDataSourceImpl(this._stateCacheClient, this._exceptionThrower);

  @override
  Future<State?> getState(StateType stateType) {
    return Future.sync(() async {
      final stateCache = await _stateCacheClient.getItem(stateType.value);
      return stateCache?.toState();
    }).catchError(_exceptionThrower.throwException);
  }

  @override
  Future<void> saveState(AccountId accountId, StateCache stateCache) {
    return Future.sync(() async {
      final stateCacheExist = await _stateCacheClient.isExistTable();
      final stateKey = TupleKey(stateCache.type.value, accountId.asString).toString();
      if (stateCacheExist) {
        return await _stateCacheClient.updateItem(stateKey, stateCache);
      } else {
        return await _stateCacheClient.insertItem(stateKey, stateCache);
      }
    }).catchError(_exceptionThrower.throwException);
  }
}