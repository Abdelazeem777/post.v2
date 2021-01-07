import 'dart:async';

import 'package:post/di/injection.dart';
import 'package:post/models/post.dart';
import 'package:post/services/connectionChecker.dart';
import 'package:rxdart/rxdart.dart';
import 'abstract/postsRepository.dart';

class PostsRepositoryImpl implements PostsRepository {
  final _remote = Injector().postsRepositoryRemote;
  final _local = Injector().postsRepositoryLocal;

  @override
  Stream<Post> getCurrentUserPosts() async* {
    if (await _isConnected())
      yield* _remote.getCurrentUserPosts();
    else
      yield* _local.getCurrentUserPosts();
  }

  Future<bool> _isConnected() async =>
      await ConnectionChecker().checkConnection();

  @override
  Stream<Post> getFollowingUsersPosts(List<String> usersIDsList) =>
      _remote.getFollowingUsersPosts(usersIDsList);

  @override
  Stream<void> uploadNewPost(Post newPost) => _remote.uploadNewPost(newPost);

  @override
  Stream<String> deletePost(String postID, String userID, String userPassword) {
    return _remote
        .deletePost(postID, userID, userPassword)
        .concatWith([_local.deletePost(postID, userID, userPassword)]);
  }

  @override
  void dispose() {
    _remote.dispose();
  }
}
