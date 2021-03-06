import 'package:post/apiEndpoint.dart';
import 'package:post/di/injection.dart';
import 'package:post/models/post.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'currentUser.dart';

class SocketService {
  static const New_USER_CONNECT_EVENT = 'newUserConnect';
  static const USER_DISCONNECTING_EVENT = 'userDisconnecting';
  static const USER_PAUSED = 'userPaused';
  static const FOLLOW_EVENT = 'follow';
  static const UNFOLLOW_EVENT = 'unFollow';
  static const NEW_POST_EVENT = 'newPost';
  static const NOTIFICATION = 'notification';

  Function _onNewUserConnect;
  Function _onPaused;
  Function _onDisconnect;
  Function _onFollow;
  Function _onUnFollow;
  Function _onNewPost;
  Function _onNotification;

  set onNewUserConnect(Function onNewUserConnect) =>
      _onNewUserConnect = onNewUserConnect;
  set onPaused(Function onPaused) => _onPaused = onPaused;
  set onDisconnect(Function onDisconnect) => _onDisconnect = onDisconnect;
  set onFollow(Function onFollow) => _onFollow = onFollow;
  set onUnFollow(Function onUnFollow) => _onUnFollow = onUnFollow;
  set onNewPost(Function onNewPost) => _onNewPost = onNewPost;
  set onNotification(Function onNotification) =>
      _onNotification = onNotification;

  IO.Socket socket;
  static SocketService _singletone;

  factory SocketService() {
    if (_singletone == null) {
      _singletone = SocketService._internal();
    }
    return _singletone;
  }
  SocketService._internal() {
    if (_singletone != null) {
      throw Exception(
          "Trying to instantiate one more object from \"SocketService\".");
    }
  }
  connect() {
    if (isNotConnected()) {
      socket = IO.io(ApiEndPoint.REQUEST_URL, <String, dynamic>{
        'transports': ['websocket'],
        'query': {'userID': CurrentUser().userID},
      });
      socket.connect();
    } else
      reconnect();
    this.socket.on(New_USER_CONNECT_EVENT, _onNewUserConnect);
    this.socket.on(USER_PAUSED, _onPaused);
    this.socket.on(USER_DISCONNECTING_EVENT, _onDisconnect);

    this.socket.on(FOLLOW_EVENT, _onFollow);
    this.socket.on(UNFOLLOW_EVENT, _onUnFollow);

    this.socket.on(NEW_POST_EVENT, _onNewPost);

    this.socket.on(NOTIFICATION, _onNotification);
  }

  bool isNotConnected() => socket == null || !socket?.connected;

  void reconnect() {
    disconnect();
    connect();
  }

  Future<void> follow(
      String currentUserID, String targetUserID, int rank) async {
    final data = {
      'currentUserID': currentUserID,
      'targetUserID': targetUserID,
      'rank': rank
    };
    socket.emit(FOLLOW_EVENT, data);
  }

  Future<void> unFollow(
      String currentUserID, String targetUserID, int rank) async {
    final data = {
      'currentUserID': currentUserID,
      'targetUserID': targetUserID,
      'rank': rank
    };

    socket.emit(UNFOLLOW_EVENT, data);
  }

  void pause() {
    socket..emit(USER_PAUSED, CurrentUser().userID);

    CurrentUser()
      ..active = false
      ..saveUserToPreference().listen((_) {})
      ..notify();
  }

  void disconnect() {
    if (socket != null)
      socket
        ..emit(USER_DISCONNECTING_EVENT, CurrentUser().userID)
        ..dispose();
    socket = null;

    CurrentUser()
      ..active = false
      ..notify();
  }

  Future<void> uploadNewPost(Post newPost) async {
    var newPostMap = newPost.toMap();
    socket.emit(NEW_POST_EVENT, newPostMap);
  }
}

class SocketServiceFacade {
  void init() {
    _initRepositoriesObjects();
    SocketService().connect();
  }

  void _initRepositoriesObjects() {
    Injector().currentUserRepository;
    Injector().postsRepository;
    Injector().notificationsRepository;
  }

  void reconnect() => SocketService().reconnect();
  void pause() => SocketService().pause();

  void destroy() {
    Injector().dispose();
    SocketService().disconnect();
  }
}
