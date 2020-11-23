import 'package:post/apiEndpoint.dart';
import 'package:post/di/injection.dart';
import 'package:post/models/user.dart';
import 'package:post/services/currentUser.dart';
import 'package:post/services/socketService.dart';
import 'package:post/utils/requestException.dart';
import 'package:rxdart/rxdart.dart';

abstract class CurrentUserRepository {
  Stream<void> login(String email, String password);
  Stream<void> singup(User user);
  Stream<void> alternateLogin(User user);
  Stream<String> deleteAccount(String email);
  Stream<void> logout();
  Stream<void> uploadProfilePic(Map<String, String> imageMap);
  Stream<String> updateProfileData(String newUserName, String newBio);
  Stream<void> follow(String currentUserID, String targetUserID, int rank);
  Stream<void> unFollow(String currentUserID, String targetUserID, int rank);

  void onFollow(userID);
  void onUnFollow(userID);
  void onNewUserConnect(data);
  void onDisconnect(data);
}

class CurrentUserRepositoryImpl implements CurrentUserRepository {
  final _networkService = Injector().networkService;
  SocketService _socketService;
  CurrentUserRepositoryImpl() {
    _socketService = SocketService()
      ..onNewUserConnect = this.onNewUserConnect
      ..onDisconnect = this.onDisconnect
      ..onFollow = this.onFollow
      ..onUnFollow = this.onUnFollow;
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
    print(userJson);
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

  String changeUserIDKeyTo_id(User user) {
    Map userMap = user.toMap()
      ..remove("userID") //to change userID key to _id
      ..addAll({"_id": user.userID});

    String userJson = _networkService.convertMapToJson(userMap);
    return userJson;
  }

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
    SocketService().disconnect();
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
  Stream<void> follow(String currentUserID, String targetUserID, int rank) {
    return Stream.fromFuture(
        _socketService.follow(currentUserID, targetUserID, rank));
  }

  @override
  Stream<void> unFollow(String currentUserID, String targetUserID, int rank) {
    return Stream.fromFuture(
        _socketService.unFollow(currentUserID, targetUserID, rank));
  }

  @override
  void onFollow(data) {
    String fromUserID = data['from'];
    String toUserID = data['to'];
    int rank = data['rank'];
    print('onFollowEvent' + data.toString());
    if (_isTheCurrentUser(fromUserID))
      CurrentUser()
        ..followingRankedMap.addAll({rank: toUserID})
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

  @override
  void onUnFollow(data) {
    String fromUserID = data['from'];
    String toUserID = data['to'];
    int rank = data['rank'];
    print('onUnFollowEvent' + data.toString());
    if (fromUserID == CurrentUser().userID)
      CurrentUser()
        ..followingRankedMap.remove(rank)
        ..saveUserToPreference().listen((_) {})
        ..notify();
    else
      CurrentUser()
        ..followersList.remove(toUserID)
        ..saveUserToPreference().listen((_) {})
        ..notify();
  }

  @override
  void onNewUserConnect(userID) {
    if (CurrentUser().userID == userID)
      CurrentUser()
        ..active = true
        ..notify();
    print("Connected user: " + userID.toString());
  }

  @override
  void onDisconnect(data) {
    print('Disconnected user: ' + data.toString());
  }
}