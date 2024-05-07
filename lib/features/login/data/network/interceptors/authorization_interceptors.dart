import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/utils/app_logger.dart';
import 'package:core/utils/platform_info.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:model/account/authentication_type.dart';
import 'package:model/account/password.dart';
import 'package:model/account/personal_account.dart';
import 'package:model/oidc/oidc_configuration.dart';
import 'package:model/oidc/token_oidc.dart';
import 'package:tmail_ui_user/features/login/data/local/account_cache_manager.dart';
import 'package:tmail_ui_user/features/login/data/local/token_oidc_cache_manager.dart';
import 'package:tmail_ui_user/features/login/data/network/authentication_client/authentication_client_base.dart';
import 'package:tmail_ui_user/features/login/domain/extensions/oidc_configuration_extensions.dart';
import 'package:tmail_ui_user/features/upload/data/network/file_uploader.dart';
import 'package:tmail_ui_user/main/utils/ios_sharing_manager.dart';

class AuthorizationInterceptors extends QueuedInterceptorsWrapper {

  final Dio _dio;
  final AuthenticationClientBase _authenticationClient;
  final TokenOidcCacheManager _tokenOidcCacheManager;
  final AccountCacheManager _accountCacheManager;
  final IOSSharingManager _iosSharingManager;

  AuthenticationType _authenticationType = AuthenticationType.none;
  OIDCConfiguration? _configOIDC;
  TokenOIDC? _token;
  String? _authorization;

  AuthorizationInterceptors(
    this._dio,
    this._authenticationClient,
    this._tokenOidcCacheManager,
    this._accountCacheManager,
    this._iosSharingManager,
  );

  void setBasicAuthorization(UserName userName, Password password) {
    _authorization = base64Encode(utf8.encode('${userName.value}:${password.value}'));
    _authenticationType = AuthenticationType.basic;
  }

  void setTokenAndAuthorityOidc({TokenOIDC? newToken, OIDCConfiguration? newConfig}) {
    _token = newToken;
    _configOIDC = newConfig;
    _authenticationType = AuthenticationType.oidc;
    log('AuthorizationInterceptors::setTokenAndAuthorityOidc: INITIAL_TOKEN = ${newToken?.token} | EXPIRED_TIME = ${newToken?.expiredTime}');
  }

  void _updateNewToken(TokenOIDC newToken) {
    log('AuthorizationInterceptors::_updateNewToken: NEW_TOKEN = ${newToken.token} | EXPIRED_TIME = ${newToken.expiredTime}');
    FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_updateNewToken', parameters: {'new_token': newToken.token, 'expired_time': newToken.expiredTime.toString()});
    _token = newToken;
  }

  OIDCConfiguration? get oidcConfig => _configOIDC;

  AuthenticationType get authenticationType => _authenticationType;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    switch(_authenticationType) {
      case AuthenticationType.basic:
        if (_authorization != null) {
          options.headers[HttpHeaders.authorizationHeader] = _getAuthorizationAsBasicHeader(_authorization);
        }
        break;
      case AuthenticationType.oidc:
        if (_token != null && _token?.isTokenValid() == true) {
          options.headers[HttpHeaders.authorizationHeader] = _getTokenAsBearerHeader(_token!.token);
        }
        break;
      case AuthenticationType.none:
        break;
    }
    log('AuthorizationInterceptors::onRequest(): URL = ${options.uri} | HEADER = ${options.headers} | DATA = ${options.data} | METHOD = ${options.method}');
    super.onRequest(options, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    logError('AuthorizationInterceptors::onError(): TOKEN = ${_token?.expiredTime} | DIO_ERROR = $err | METHOD = ${err.requestOptions.method}');
    try {
      FirebaseAnalytics.instance.logEvent(
          name: 'AuthorizationIncp_onError',
          parameters: {
            'token_expired': _token?.expiredTime.toString(),
            'dio_error': err.toString(),
            'method': err.requestOptions.method
          });
    } catch (e) {
      log('AuthorizationInterceptors::onError(): Exception = $e');
    }
    try {
      final requestOptions = err.requestOptions;
      final extraInRequest = requestOptions.extra;
      bool isRetryRequest = false;

      if (validateToRefreshToken(
        responseStatusCode: err.response?.statusCode,
        tokenOIDC: _token
      )) {
        log('AuthorizationInterceptors::onError:_validateToRefreshToken');
        FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_onError', parameters: {'event': '_validateToRefreshToken'});
        final newTokenOidc = PlatformInfo.isIOS
          ? await _handleRefreshTokenOnIOSPlatform()
          : await _handleRefreshTokenOnOtherPlatform();

        FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_onError', parameters: {'event': 'completed refresh token'});

        if (newTokenOidc.token == _token?.token) {
          log('AuthorizationInterceptors::onError: TokenOIDC duplicated');
          FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_onError',
              parameters: {'event': 'TokenOIDC duplicated'});
          return super.onError(err, handler);
        }

        _updateNewToken(newTokenOidc);

        isRetryRequest = true;
      } else if (validateToRetryTheRequestWithNewToken(
        authHeader: requestOptions.headers[HttpHeaders.authorizationHeader],
        tokenOIDC: _token
      )) {
        log('AuthorizationInterceptors::onError:validateToRetryTheRequestWithNewToken');
        FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_onError', parameters: {'event': '_validateToRetryTheRequestWithNewToken'});
        isRetryRequest = true;
      } else {
        FirebaseAnalytics.instance.logEvent(
            name: 'AuthorizationIncp_onError',
            parameters: {'event': 'Call super.onError if it is not retryRequest'});
        return super.onError(err, handler);
      }

      if (isRetryRequest) {
        if (extraInRequest.containsKey(FileUploader.uploadAttachmentExtraKey)) {
          log('AuthorizationInterceptors::onError: Perform upload attachment request');
          final uploadExtra = extraInRequest[FileUploader.uploadAttachmentExtraKey];

          requestOptions.headers[HttpHeaders.authorizationHeader] = _getTokenAsBearerHeader(_token!.token);
          requestOptions.headers[HttpHeaders.contentTypeHeader] = uploadExtra[FileUploader.typeExtraKey];
          requestOptions.headers[HttpHeaders.contentLengthHeader] = uploadExtra[FileUploader.sizeExtraKey];

          final newOptions = Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
          );

          final response = await _dio.request(
            requestOptions.path,
            data: _getDataUploadRequest(uploadExtra),
            queryParameters: requestOptions.queryParameters,
            options: newOptions,
          );

          return handler.resolve(response);
        } else {
          log('AuthorizationInterceptors::onError: Perform normal request');
          FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_onError', parameters: {'event': 'Perform normal request'});
          requestOptions.headers[HttpHeaders.authorizationHeader] = _getTokenAsBearerHeader(_token!.token);

          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        }
      } else {
        FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_onError', parameters: {'event': 'Call super.onError if it is not retryRequest'});
        return super.onError(err, handler);
      }
    } catch (e) {
      logError('AuthorizationInterceptors::onError:Exception: $e');
      FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_onError', parameters: {'Exception': e});
      return super.onError(err.copyWith(error: e), handler);
    }
  }

  Stream<List<int>>? _getDataUploadRequest(dynamic mapUploadExtra) {
    final currentPlatform = mapUploadExtra[FileUploader.platformExtraKey];
    if (currentPlatform == 'web') {
      return BodyBytesStream.fromBytes(mapUploadExtra[FileUploader.bytesExtraKey]);
    } else {
      return File(mapUploadExtra[FileUploader.filePathExtraKey]).openRead();
    }
  }

  bool _isTokenExpired(TokenOIDC? tokenOIDC) => tokenOIDC?.isExpired == true;

  bool _isAuthenticationOidcValid() => _authenticationType == AuthenticationType.oidc && _configOIDC != null;

  bool _isTokenNotEmpty(TokenOIDC? tokenOIDC) => tokenOIDC?.token.isNotEmpty == true;

  bool _isRefreshTokenNotEmpty(TokenOIDC? tokenOIDC) => tokenOIDC?.refreshToken.isNotEmpty == true;

  bool validateToRefreshToken({
    required int? responseStatusCode,
    required TokenOIDC? tokenOIDC
  }) {
    return responseStatusCode == 401
      && _isAuthenticationOidcValid()
      && _isTokenNotEmpty(tokenOIDC)
      && _isRefreshTokenNotEmpty(tokenOIDC)
      && _isTokenExpired(tokenOIDC);
  }

  bool validateToRetryTheRequestWithNewToken({
    required String? authHeader,
    required TokenOIDC? tokenOIDC
  }) {
    return authHeader != null
      && _isTokenNotEmpty(tokenOIDC)
      && !_isTokenExpired(tokenOIDC)
      && !authHeader.contains(tokenOIDC!.token);
  }

  String _getAuthorizationAsBasicHeader(String? authorization) => 'Basic $authorization';

  String _getTokenAsBearerHeader(String token) => 'Bearer $token';

  bool get isAppRunning {
    switch(_authenticationType) {
      case AuthenticationType.basic:
        return _authorization != null;
      case AuthenticationType.oidc:
        return _configOIDC != null && _token != null;
      case AuthenticationType.none:
        return false;
    }
  }

  Future<PersonalAccount> _updateCurrentAccount({required TokenOIDC tokenOIDC}) async {
    final currentAccount = await _accountCacheManager.getCurrentAccount();

    await _accountCacheManager.deleteCurrentAccount(currentAccount.id);

    await _tokenOidcCacheManager.persistOneTokenOidc(tokenOIDC);

    final personalAccount = PersonalAccount(
      tokenOIDC.tokenIdHash,
      AuthenticationType.oidc,
      isSelected: true,
      accountId: currentAccount.accountId,
      apiUrl: currentAccount.apiUrl,
      userName: currentAccount.userName
    );
    await _accountCacheManager.setCurrentAccount(personalAccount);
    FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_updateCurrentAccount', parameters: {'personal_account': personalAccount.toString()});

    return personalAccount;
  }

  Future<TokenOIDC?> _getTokenInKeychain(TokenOIDC currentTokenOidc) async {
    final currentAccount = await _accountCacheManager.getCurrentAccount();
    log('AuthorizationInterceptors::_getTokenInKeychain:currentAccount: $currentAccount');
    if (currentAccount.accountId == null) {
      return null;
    }

    final keychainSharingSession = await _iosSharingManager.getKeychainSharingSession(currentAccount.accountId!);
    log('AuthorizationInterceptors::_getTokenInKeychain:keychainSharingSession: $keychainSharingSession');
    if (keychainSharingSession == null) {
      return null;
    }

    if (keychainSharingSession.tokenOIDC != null &&
        currentTokenOidc.token != keychainSharingSession.tokenOIDC!.token) {
      return keychainSharingSession.tokenOIDC!;
    }

    return null;
  }

  Future<TokenOIDC> _invokeRefreshTokenFromServer() async {
    final newToken = await _authenticationClient.refreshingTokensOIDC(
      _configOIDC!.clientId,
      _configOIDC!.redirectUrl,
      _configOIDC!.discoveryUrl,
      _configOIDC!.scopes,
      _token!.refreshToken
    );
    log('AuthorizationInterceptors::_invokeRefreshTokenFromServer:newToken: $newToken');
    FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_invokeRfshTknFrServer', parameters: {'new_token': newToken.toString()});
    return newToken;
  }

  Future<TokenOIDC> _handleRefreshTokenOnIOSPlatform() async {
    final keychainToken = await _getTokenInKeychain(_token!);

    if (keychainToken == null) {
      final newToken = await _invokeRefreshTokenFromServer();
      final newAccount = await _updateCurrentAccount(tokenOIDC: newToken);
      await _iosSharingManager.saveKeyChainSharingSession(newAccount);
      return newToken;
    } else {
      await _updateCurrentAccount(tokenOIDC: keychainToken);
      return keychainToken;
    }
  }

  Future<TokenOIDC> _handleRefreshTokenOnOtherPlatform() async {
    final newToken = await _invokeRefreshTokenFromServer();
    FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_hndlRfshTknOnOPltf', parameters: {'new_token': newToken.tokenIdHash});
    FirebaseAnalytics.instance.logEvent(name: 'AuthorizationIncp_hndlRfshTknOnOPltf', parameters: {'new_token': newToken.expiredTime});
    await _updateCurrentAccount(tokenOIDC: newToken);
    return newToken;
  }

  void clear() {
    _authorization = null;
    _token = null;
    _configOIDC = null;
    _authenticationType = AuthenticationType.none;
  }
}