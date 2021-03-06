class ApiEndPoint {
  //192.168.43.72
  //192.168.1.10
  static const REQUEST_URL = 'http://192.168.1.10:3000';

  static const SIGN_UP = REQUEST_URL + '/account/signup';
  static const LOGIN = REQUEST_URL + '/account/login';
  static const ALTERNATE_LOGIN = REQUEST_URL + '/account/alternateLogin';
  static const DELETE_ACCOUNT = REQUEST_URL + '/account/deleteAccount';
  static const UPLOAD_PROFILE_PIC = REQUEST_URL + '/account/uploadProfilePic';
  static const UPDATE_PROFILE_DATA = REQUEST_URL + '/account/updateProfileData';
  static const UPDATE_USER_RANK = REQUEST_URL + '/account/updateUserRank';

  static const SEARCH_FOR_USERS = REQUEST_URL + '/users/search';
  static const FOLLOW = REQUEST_URL + '/users/follow';
  static const UNFOLLOW = REQUEST_URL + '/users/unFollow';

  static const LOAD_FOLLOWING_USERS = REQUEST_URL + '/users/loadFollowingUsers';
  static const LOAD_FOLLOWERS_USERS = REQUEST_URL + '/users/loadFollowersUsers';

  static const DELETE_POST = REQUEST_URL + '/posts/deletePost';
  static const GET_POSTS = REQUEST_URL + '/posts/getPosts';

  static const GET_NOTIFICATIONS = REQUEST_URL + '/posts/getNotifications';
}
