import 'package:post/apiEndpoint.dart';
import 'package:post/di/injection.dart';
import 'package:post/models/user.dart';
import 'package:post/repositories/abstract/currentUserRepository.dart';
import 'package:post/services/currentUser.dart';
import 'package:post/services/socketService.dart';
import 'package:post/utils/requestException.dart';
import 'package:rxdart/rxdart.dart';

class CurrentUserRepositoryRemoteImpl implements CurrentUserRepository {
  final _networkService = Injector().networkService;
  SocketService _socketService;
  CurrentUserRepositoryRemoteImpl() {
    _socketService = SocketService()
      ..onNewUserConnect = this._onNewUserConnect
      ..onPaused = this._onPaused
      ..onDisconnect = this._onDisconnect
      ..onFollow = this._onFollow
      ..onUnFollow = this._onUnFollow;
  }
  @override
  Stream<void> login(String email, String password) {
    Map data = {'email': email, 'password': password};
    String jsonData = _networkService.convertMapToJson(data);
    return Stream.fromFuture(_networkService.post(ApiEndPoint.LOGIN, jsonData))
        .flatMap((response) {
      Map responseMap = _networkService.convertJsonToMap(response.body);
      if (response.statusCode != 200 || null == response.statusCode) {
        throw new RequestException(responseMap["message"]);
      } else {
        User user = User.fromMap(responseMap);
        return CurrentUser().saveUserToPreference(user);
      }
    });
  }

  @override
  Stream<void> singup(User user) {
    String userJson = _networkService.convertMapToJson(user.toMap());

    return Stream.fromFuture(
            _networkService.post(ApiEndPoint.SIGN_UP, userJson))
        .flatMap((response) {
      Map responseMap = _networkService.convertJsonToMap(response.body);
      if (response.statusCode != 200 || null == response.statusCode) {
        throw new RequestException(responseMap["message"]);
      } else {
        return login(user.email, user.password);
      }
    });
  }

  @override
  Stream<void> alternateLogin(User user) {
    String userJson = changeUserIDKeyTo_id(user);
    return Stream.fromFuture(
            _networkService.post(ApiEndPoint.ALTERNATE_LOGIN, userJson))
        .flatMap((response) {
      Map responseMap = _networkService.convertJsonToMap(response.body);
      if (response.statusCode != 200 || null == response.statusCode) {
        throw new RequestException(responseMap["message"]);
      } else {
        User user = User.fromMap(responseMap);
        return CurrentUser().saveUserToPreference(user);
      }
    });
  }

  // ignore: non_constant_identifier_names
  String changeUserIDKeyTo_id(User user) {
    Map userMap = user.toMap()
      ..remove("userID") //to change userID key to _id
      ..addAll({"_id": user.userID});

    String userJson = _networkService.convertMapToJson(userMap);
    return userJson;
  }

//TODO: make the password required with the email to delete the account, like we did with delete post
  @override
  Stream<String> deleteAccount(String email) {
    String emailParam = '/$email';
    return Stream.fromFuture(
            _networkService.delete(ApiEndPoint.DELETE_ACCOUNT + emailParam))
        .flatMap((response) {
      if (response.statusCode != 200 || null == response.statusCode) {
        Map responseMap = _networkService.convertJsonToMap(response.body);
        throw new RequestException(responseMap["message"]);
      } else {
        return logout().map((_) {
          return response.body.toString();
        });
      }
    });
  }

  @override
  Stream<void> logout() {
    SocketServiceFacade().destroy();
    return CurrentUser().logout();
  }

  @override
  Stream<void> uploadProfilePic(Map<String, String> imageMap) {
    imageMap.addAll({'userID': CurrentUser().userID});
    String imageJson = _networkService.convertMapToJson(imageMap);
    return Stream.fromFuture(
            _networkService.post(ApiEndPoint.UPLOAD_PROFILE_PIC, imageJson))
        .flatMap((response) {
      Map responseMap = _networkService.convertJsonToMap(response.body);
      if (response.statusCode != 200 || null == response.statusCode) {
        throw new RequestException(responseMap["message"]);
      } else {
        CurrentUser()
          ..userProfilePicURL = User()
              .fixUserProfilePicURLIfNeeded(responseMap['userProfilePicURL'])
          ..notify();
        return CurrentUser().saveUserToPreference();
      }
    });
  }

  @override
  Stream<String> updateProfileData(String newUserName, String newBio) {
    var newProfileDataMap = {
      'userID': CurrentUser().userID,
      'userName': newUserName,
      'bio': newBio
    };
    var newProfileData = _networkService.convertMapToJson(newProfileDataMap);
    return Stream.fromFuture(_networkService.patch(
            ApiEndPoint.UPDATE_PROFILE_DATA, newProfileData))
        .flatMap((response) {
      if (response.statusCode != 200 || null == response.statusCode) {
        Map responseMap = _networkService.convertJsonToMap(response.body);
        throw new RequestException(responseMap["message"]);
      } else {
        CurrentUser()
          ..userName = newUserName
          ..bio = newBio
          ..notify();
        return CurrentUser().saveUserToPreference().map((_) {
          return response.body.toString();
        });
      }
    });
  }

  @override
  Stream<String> updateRank(
      String currentUserID, String targetUserID, int oldRank, int newRank) {
    final data = {
      'currentUserID': currentUserID,
      'targetUserID': targetUserID,
      'newRank': newRank,
    };
    final dataJSON = _networkService.convertMapToJson(data);
    return Stream.fromFuture(
            _networkService.post(ApiEndPoint.UPDATE_USER_RANK, dataJSON))
        .flatMap((response) {
      if (response.statusCode != 200 || null == response.statusCode) {
        Map responseMap = _networkService.convertJsonToMap(response.body);
        throw new RequestException(responseMap["message"]);
      } else {
        CurrentUser()
          ..changeRankOfUser(targetUserID, oldRank, newRank)
          ..notify();
        return CurrentUser().saveUserToPreference().map((_) => response.body);
      }
    });
  }

  @override
  Stream<void> follow(String currentUserID, String targetUserID, int rank) {
    return Stream.fromFuture(
        _socketService.follow(currentUserID, targetUserID, rank));
  }

  @override
  Stream<void> unFollow(String currentUserID, String targetUserID, int rank) {
    return Stream.fromFuture(
        _socketService.unFollow(currentUserID, targetUserID, rank));
  }

  void _onFollow(data) {
    String fromUserID = data['from'];
    String toUserID = data['to'];
    int rank = data['rank'];

    if (_isTheCurrentUser(fromUserID))
      CurrentUser()
        ..followingRankedList.insert(rank, toUserID)
        ..saveUserToPreference().listen((_) {})
        ..notify();
    else
      CurrentUser()
        ..followersList.add(toUserID)
        ..saveUserToPreference().listen((_) {})
        ..notify();
  }

  bool _isTheCurrentUser(String fromUserID) =>
      fromUserID == CurrentUser().userID;

  void _onUnFollow(data) {
    String fromUserID = data['from'];
    String toUserID = data['to'];
    //int rank = data['rank'];

    if (_isTheCurrentUser(fromUserID))
      CurrentUser()
        ..followingRankedList.remove(toUserID)
        ..saveUserToPreference().listen((_) {})
        ..notify();
    else
      CurrentUser()
        ..followersList.remove(toUserID)
        ..saveUserToPreference().listen((_) {})
        ..notify();
  }

  void _onNewUserConnect(userID) {
    if (CurrentUser().userID == userID)
      CurrentUser()
        ..active = true
        ..notify();
  }

  void _onPaused(usedID) {}

  void _onDisconnect(data) {}

  @override
  void dispose() {}
}
