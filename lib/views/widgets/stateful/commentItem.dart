import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:post/enums/commentTypeEnum.dart';
import 'package:post/enums/replyTypeEnum.dart';
import 'package:post/models/comment.dart';
import 'package:post/models/currentUser.dart';
import 'package:post/models/reply.dart';
import 'package:post/models/user.dart';
import 'package:post/style/appColors.dart';
import 'package:post/utils/dateTimeFormatHandler.dart';
import 'package:post/utils/sizeConfig.dart';
import 'package:post/views/widgets/stateful/commentReactButton.dart';
import 'package:post/views/widgets/stateful/reactButton.dart';
import 'package:post/views/widgets/stateful/replyItem.dart';
import 'package:post/views/widgets/stateless/timeTextFromTimestamp.dart';
import 'package:post/views/widgets/stateful/userProfilePicture.dart';
import 'package:post/views/widgets/stateless/replyButton.dart';
import 'package:post/views/widgets/stateless/userNameAndBio.dart';

class CommentItem extends StatefulWidget {
  Comment comment;
  CommentItem({this.comment});
  @override
  _CommentItemState createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  Comment _currentComment;
  User _currentUser = CurrentUserSingletone.getInstance();
  bool _expanded = false;
  bool _replyBarShowed = false;

  TextEditingController _replyTextController = TextEditingController();
  FocusNode _replyTextFocusNode = FocusNode();
  //just for testing
  User _commentOwner = User(
      active: true,
      bio: "mobile developer",
      userID: 45,
      userName: "Ahmed Mohamed",
      userProfilePicURL: "Default",
      following: true);

  //TODO:try to add a line for replies like twitter threads, convert bottom icons to a textbotton and add expand to show replies
  @override
  Widget build(BuildContext context) {
    _currentComment = widget.comment;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _createUserProfile(),
                _expanded ? _createStartOfThreadLine() : Container(),
              ],
            ),
            Container(
              //51=(35+(8*2)) is the width of the user profile picture, 8 is for right margin
              width: SizeConfig.screenWidth - (51 + 8),
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(
                top: 16,
              ),
              decoration: BoxDecoration(
                  color: AppColors.SECONDARY_COLOR.withOpacity(.15),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  )),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserNameAndBio(
                        userName: _commentOwner.userName,
                        bio: _commentOwner.bio,
                      ),
                      TimeTextFromTimestamp(_currentComment.timestamp),
                    ],
                  ),
                  _createCommentContent(
                    _currentComment.commentContent,
                    _currentComment.commentType,
                  ),
                  _createBottomPartOfComment(),
                ],
              ),
            ),
          ],
        ),
        _currentComment.repliesList.isNotEmpty
            ? _createRepliesListView()
            : Container(),
      ],
    );
  }

//TODO: find a solution for the height issue
  Widget _createStartOfThreadLine() {
    return Column(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: AppColors.PRIMARY_COLOR, shape: BoxShape.circle),
        ),
        Container(
          width: 1,
          height: 30,
          color: AppColors.PRIMARY_COLOR,
        ),
      ],
    );
  }

  Widget _createUserProfile() {
    return Container(
      width: 35,
      height: 35,
      margin: EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: UserProfilePicture(
        active: _commentOwner.active,
        imageURL: _commentOwner.userProfilePicURL,
        activeIndicatorSize: 10,
      ),
    );
  }

  Widget _createCommentContent(String content, CommentType type) {
    Widget w;

    type == CommentType.Text
        ? w = Text(content)
        : w = CachedNetworkImage(
            fit: BoxFit.contain,
            height: SizeConfig.screenWidth,
            imageUrl: content,
            progressIndicatorBuilder: (context, url, progress) => Center(
              child: CircularProgressIndicator(
                value: progress.totalSize != null
                    ? progress.downloaded / progress.totalSize
                    : null,
                valueColor: AlwaysStoppedAnimation(AppColors.SECONDARY_COLOR),
              ),
            ),
          );

    return Container(margin: EdgeInsets.only(top: 8, bottom: 8), child: w);
  }

  Widget _createBottomPartOfComment() {
    return Row(
      children: [
        CommentReactButton(),
        ReplyButton(onPressed: _showReplyBar),
        Spacer(),
        _createExpandButton()
      ],
    );
  }

  Widget _createExpandButton() {
    return Container(
      height: 15,
      alignment: Alignment.topCenter,
      child: FlatButton.icon(
        padding: EdgeInsets.all(0),
        minWidth: 0,
        icon: _expanded
            ? Icon(
                Icons.arrow_drop_up,
                color: AppColors.PRIMARY_COLOR,
                size: 17,
              )
            : Icon(
                Icons.arrow_drop_down,
                color: AppColors.PRIMARY_COLOR,
                size: 17,
              ),
        label: Text(
          _expanded ? "Collapse" : "Expand",
          style: TextStyle(color: AppColors.PRIMARY_COLOR, fontSize: 12),
        ),
        onPressed: _expandOrCollapse,
      ),
    );
  }

//TODO: convert it column wraped with animated continer for the expantion animation
  Widget _createRepliesListView() {
    List<Reply> repliesList = _currentComment.repliesList;
    List<Widget> children = List<Widget>();
    repliesList.forEach((reply) {
      children.add(Container(
        child: ReplyItem(
          reply: reply,
          onReplyButtonPressed: _showReplyBar,
        ),
      ));
    });
    return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: _expanded ? null : 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: children
            ..add(_replyBarShowed //show ReplyInputBar when reply button clicked
                ? _createReplyInput()
                : Container()),
        ));
  }

  Widget _createReplyInput() {
    return Container(
      width: SizeConfig.screenWidth - (27.5 + 4) * 2,
      child: Row(
        children: [
          _createCurrentUserProfilePicture(),
          _createReplyTextField(),
          _createSendReplyButton(),
        ],
      ),
    );
  }

  Widget _createCurrentUserProfilePicture() {
    return Container(
      width: 35,
      height: 35,
      margin: EdgeInsets.all(8),
      child: UserProfilePicture(
        imageURL: _currentUser.userProfilePicURL,
      ),
    );
  }

  Widget _createReplyTextField() {
    return Expanded(
      child: TextField(
        controller: _replyTextController,
        focusNode: _replyTextFocusNode,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        cursorColor: AppColors.SECONDARY_COLOR,
        style: TextStyle(fontSize: 14),
        scrollPhysics: ScrollPhysics(),
        decoration: InputDecoration(
          contentPadding:
              EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 16),
          hintText: 'Write a comment...',
          border: InputBorder.none,
          fillColor: AppColors.SECONDARY_COLOR.withOpacity(.15),
          filled: true,
          enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _createSendReplyButton() {
    return IconButton(
      icon: Icon(
        Icons.send,
        color: AppColors.SECONDARY_COLOR,
        size: 18,
      ),
      padding: EdgeInsets.all(8),
      onPressed: null,
    );
  }

  void _expandOrCollapse() => setState(() {
        _expanded = !_expanded;
        if (!_expanded) {
          _replyBarShowed = false;
          FocusScope.of(context).unfocus();
        }
      });
  void _showReplyBar() => setState(() {
        _expanded = true;
        _replyBarShowed = true;
        FocusScope.of(context).requestFocus(null);
        _replyTextFocusNode.requestFocus();
      });
}
