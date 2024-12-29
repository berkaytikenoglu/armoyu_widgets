import 'package:armoyu_services/armoyu_services.dart';
import 'package:armoyu_services/core/models/ARMOYU/API/post/post_detail.dart';
import 'package:armoyu_services/core/models/ARMOYU/_response/response.dart';
import 'package:armoyu_widgets/core/armoyu.dart';
import 'package:armoyu_widgets/core/widgets.dart';
import 'package:armoyu_widgets/data/models/ARMOYU/media.dart';
import 'package:armoyu_widgets/data/models/Social/like.dart';
import 'package:armoyu_widgets/data/models/user.dart';
import 'package:armoyu_widgets/data/services/accountuser_services.dart';
import 'package:armoyu_widgets/sources/photoviewer/views/photoviewer_view.dart';
import 'package:armoyu_widgets/sources/postscomment/views/postcomment_view.dart';
import 'package:armoyu_widgets/translations/app_translation.dart';
import 'package:armoyu_widgets/widgets/post_likers/post_likers_view.dart';
import 'package:armoyu_widgets/widgets/shimmer/placeholder.dart';
import 'package:armoyu_widgets/widgets/text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:video_player/video_player.dart';

class PostController extends GetxController {
  final ARMOYUServices service;
  PostController(this.service);

  final Rxn<List<APIPostList>> postsList = Rxn<List<APIPostList>>(null);
  var postscount = 1.obs;
  var postsProccess = false.obs;
  var likeunlikeProcces = false.obs;
  var fetchCommentStatus = false.obs;
  var fetchlikersStatus = false.obs;

  User? currentUser;

  @override
  void onInit() {
    super.onInit();
    log("Post Widget Init");
    final findCurrentAccountController = Get.find<AccountUserController>();
    currentUser =
        findCurrentAccountController.currentUserAccounts.value.user.value;
    fetchsocailposts();
  }

  Future<void> fetchsocailposts() async {
    if (postsProccess.value) {
      return;
    }
    postsProccess.value = true;

    PostFetchListResponse response =
        await service.postsServices.getPosts(page: postscount.value);

    if (!response.result.status) {
      postsProccess.value = false;
      return;
    }

    postsList.value ??= [];
    for (APIPostList element in response.response!) {
      postsList.value!.add(element);
    }
    postsList.refresh();
    postsProccess.value = false;
  }

  //// This function is used to add new post to the list
  void likepost(APIPostList post) async {
    if (likeunlikeProcces.value) {
      return;
    }

    likeunlikeProcces.value = true;

    PostLikeResponse response =
        await service.postsServices.like(postID: post.postID);
    if (!response.result.status) {
      log(response.result.description.toString());
      return;
    }

    post.didilikeit = 1;
    post.likeCount++;
    likeunlikeProcces.value = false;
  }

  void unlikepost(APIPostList post) async {
    if (likeunlikeProcces.value) {
      return;
    }
    likeunlikeProcces.value = true;

    PostUnLikeResponse response =
        await service.postsServices.unlike(postID: post.postID);
    if (!response.result.status) {
      log(response.result.description.toString());
      return;
    }

    post.didilikeit = 0;
    post.likeCount--;

    likeunlikeProcces.value = false;
  }

  Future<bool> postLike(bool isLiked, APIPostList post) async {
    if (isLiked) {
      if (likeunlikeProcces.value) {
        return isLiked;
      }
      //Beğenmeme fonksiyonu
      unlikepost(post);
    } else {
      likepost(post);
    }
    return !isLiked;
  }

  Future<void> removepost(APIPostList post) async {
    PostRemoveResponse response =
        await service.postsServices.remove(postID: post.postID);

    ARMOYUWidget.toastNotification(response.result.description.toString());

    if (!response.result.status) {
      return;
    }

    Get.back();
  }

  void postfeedback(APIPostList post) {
    showModalBottomSheet<void>(
      backgroundColor: Get.theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      context: Get.context!,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      width: ARMOYU.screenWidth / 4,
                      height: 5,
                    ),
                  ),
                  Visibility(
                    child: InkWell(
                      onTap: () async {
                        PostRemoveResponse response = await service
                            .postsServices
                            .remove(postID: post.postID);
                        if (!response.result.status) {
                          log(response.result.description);
                          return;
                        }
                        log(response.result.description);
                      },
                      child: ListTile(
                        leading: const Icon(
                          Icons.star_rate_sharp,
                        ),
                        title: Text(SocialKeys.socialAddFavorite.tr),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: post.postOwner.ownerID == currentUser!.userID,
                    child: InkWell(
                      onTap: () async {},
                      child: ListTile(
                        leading: const Icon(
                          Icons.edit_note_sharp,
                        ),
                        title: Text(SocialKeys.socialedit.tr),
                      ),
                    ),
                  ),
                  const Visibility(
                    //Çizgi ekler
                    child: Divider(),
                  ),
                  Visibility(
                    visible: post.postOwner.ownerID != currentUser!.userID,
                    child: InkWell(
                      onTap: () {},
                      child: ListTile(
                        textColor: Colors.red,
                        leading: const Icon(
                          Icons.flag,
                          color: Colors.red,
                        ),
                        title: Text(SocialKeys.socialReport.tr),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: post.postOwner.ownerID != currentUser!.userID,
                    child: InkWell(
                      onTap: () async {
                        Get.back();

                        BlockingAddResponse response =
                            await service.blockingServices.add(
                          userID: post.postOwner.ownerID,
                        );

                        ARMOYUWidget.toastNotification(
                          response.result.description,
                        );
                      },
                      child: ListTile(
                        textColor: Colors.red,
                        leading: const Icon(
                          Icons.person_off_outlined,
                          color: Colors.red,
                        ),
                        title: Text(SocialKeys.socialBlock.tr),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: post.postOwner.ownerID == currentUser!.userID,
                    child: InkWell(
                      onTap: () async => ARMOYUWidget.showConfirmationDialog(
                        context,
                        accept: removepost,
                      ),
                      child: ListTile(
                        textColor: Colors.red,
                        leading: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        title: Text(SocialKeys.socialdelete.tr),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> getcommentsfetch(Rxn<List<APIPostComments>> comments, int postID,
      {bool fetchRestart = false}) async {
    if (!fetchRestart && comments.value != null) {
      return;
    }

    if (fetchCommentStatus.value) {
      return;
    }
    fetchCommentStatus.value = true;

    if (fetchRestart) {
      comments.value = null;
    }
    PostCommentsFetchResponse response =
        await service.postsServices.commentsfetch(postID: postID);
    if (!response.result.status) {
      log(response.result.description);
      fetchCommentStatus.value = false;

      return;
    }

    //Eğer veri null ise nullu boz Yorumları başlatma dizisi eşitle
    comments.value ??= [];

    //Veriler çek
    for (APIPostComments element in response.response!) {
      //Post yorumlarına ekler
      comments.value!.add(element);
    }
    comments.refresh();
    fetchCommentStatus.value = false;
  }

  Future<void> postcomments(
      APIPostList post, TextEditingController messageController,
      {required Function profileFunction}) async {
    Rxn<List<APIPostComments>> comments = Rxn<List<APIPostComments>>();

    //Yorumları Çekmeye başla
    getcommentsfetch(comments, post.postID);

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Get.theme.cardColor,
      context: Get.context!,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: RefreshIndicator(
            onRefresh: () async => await getcommentsfetch(
              comments,
              post.postID,
              fetchRestart: true,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CustomText.costum1(
                    SocialKeys.socialComments.tr.toUpperCase(),
                  ),
                  const SizedBox(height: 5),
                  const Divider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        alignment: Alignment.center,
                        child: Obx(
                          () => comments.value == null
                              ? Column(
                                  children: [
                                    ShimmerPlaceholder.listTilePlaceholder(
                                      trailingIcon: const Icon(Icons.favorite),
                                    ),
                                    ShimmerPlaceholder.listTilePlaceholder(
                                      trailingIcon: const Icon(Icons.favorite),
                                    ),
                                    ShimmerPlaceholder.listTilePlaceholder(
                                      trailingIcon: const Icon(Icons.favorite),
                                    ),
                                    ShimmerPlaceholder.listTilePlaceholder(
                                      trailingIcon: const Icon(Icons.favorite),
                                    ),
                                    ShimmerPlaceholder.listTilePlaceholder(
                                      trailingIcon: const Icon(Icons.favorite),
                                    ),
                                  ],
                                )
                              : comments.value!.isEmpty
                                  ? CustomText.costum1(
                                      SocialKeys.socialWriteFirstComment.tr,
                                    )
                                  : ListView.builder(
                                      itemCount: comments.value!.length,
                                      itemBuilder: (context, index) {
                                        return PostcommentView
                                            .postCommentsWidgetV2(
                                          context,
                                          service,
                                          comments.value![index],
                                          profileFunction: profileFunction,
                                          deleteFunction: () {
                                            comments.value!.removeAt(index);

                                            comments.refresh();
                                          },
                                        );
                                      },
                                    ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(Get.context!).viewInsets.bottom,
                    ),
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            foregroundImage: CachedNetworkImageProvider(
                              currentUser!.avatar!.mediaURL.minURL.value,
                            ),
                            radius: 20,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(5),
                            height: 55,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.only(left: 5),
                                decoration: BoxDecoration(
                                  color: Get.theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: TextField(
                                  controller: messageController,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: SocialKeys.socialWriteComment.tr,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              PostCreateCommentResponse response =
                                  await service.postsServices.createcomment(
                                postID: post.postID,
                                text: messageController.text,
                              );
                              if (!response.result.status) {
                                ARMOYUWidget.toastNotification(
                                    response.result.description.toString());
                                return;
                              }
                              await getcommentsfetch(
                                comments,
                                post.postID,
                                fetchRestart: true,
                              );
                              messageController.text = "";
                            },
                            child: const Icon(
                              Icons.send,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return;
  }

  Future<void> postlikesfetch(Rxn<List<Like>> likers, APIPostList post,
      {bool fetchRestart = false}) async {
    if (!fetchRestart && likers.value != null) {
      return;
    }

    if (fetchlikersStatus.value) {
      return;
    }
    fetchlikersStatus.value = true;

    if (fetchRestart) {
      likers.value = null;
    }
    PostLikesListResponse response =
        await service.postsServices.postlikeslist(postID: post.postID);
    if (!response.result.status) {
      log(response.result.description.toString());
      fetchlikersStatus.value = false;
      return;
    }

    //Eğer veri null ise nullu boz Yorumları başlatma dizisi eşitle
    likers.value ??= [];

    for (APIPostLiker element in response.response!) {
      String displayname = element.likerdisplayname.toString();
      String avatar = element.likeravatar.minURL.toString();
      String date = element.likedate.toString();
      int userID = element.likerID;
      log(userID.toString());
      Like like = Like(
        likeID: 1,
        user: User(
          userID: userID,
          displayName: displayname.obs,
          avatar: Media(
            mediaID: userID,
            mediaURL: MediaURL(
              bigURL: Rx<String>(avatar),
              normalURL: Rx<String>(avatar),
              minURL: Rx<String>(avatar),
            ),
          ),
        ),
        date: date,
      );

      likers.value!.add(like);
    }
    // postInfo.value.likers = likers.value;

    likers.refresh();
    fetchlikersStatus.value = false;
  }

  void showpostlikers(APIPostList post) {
    Rxn<List<Like>> likerList = Rxn<List<Like>>();

    postlikesfetch(likerList, post);

    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Get.theme.cardColor,
      context: Get.context!,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: RefreshIndicator(
            onRefresh: () => postlikesfetch(
              likerList,
              post,
              fetchRestart: true,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    SocialKeys.socialLikers.tr.toUpperCase(),
                  ),
                  const SizedBox(height: 5),
                  const Divider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        alignment: Alignment.center,
                        child: Obx(
                          () => likerList.value == null
                              ? Column(
                                  children: [
                                    ShimmerPlaceholder.listTilePlaceholder(),
                                    ShimmerPlaceholder.listTilePlaceholder(),
                                    ShimmerPlaceholder.listTilePlaceholder(),
                                    ShimmerPlaceholder.listTilePlaceholder(),
                                    ShimmerPlaceholder.listTilePlaceholder(),
                                    ShimmerPlaceholder.listTilePlaceholder(),
                                  ],
                                )
                              : likerList.value!.isEmpty
                                  ? CustomText.costum1(CommonKeys.empty.tr)
                                  : ListView.builder(
                                      itemCount: likerList.value!.length,
                                      itemBuilder: (context, index) {
                                        return WidgetPostLikersView(
                                          date: likerList.value![index].date,
                                          islike: 1,
                                          user: likerList.value![index].user,
                                        ).build(context, profileFunction: () {
                                          log(likerList
                                              .value![index].user.userID
                                              .toString());
                                        });
                                      },
                                    ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return;
  }

  Widget buildMediaContent(BuildContext context, Rx<APIPostList> postInfo) {
    Widget mediaSablon(
      String mediaUrl, {
      required int indexlength,
      BoxFit? fit = BoxFit.cover,
      double? width = 100,
      double? height = 100,
      bool? isvideo = false,
      bool islastmedia = false,
    }) {
      if (isvideo == true) {
        log(mediaUrl);

        final videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
        );

        final chewieController = ChewieController(
          videoPlayerController: videoPlayerController,
          autoInitialize: true,
          autoPlay: false,
          aspectRatio: 9 / 16,
          // isLive: true,
          looping: false,
        );

        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            height: 500,
            width: ARMOYU.screenWidth - 20,
            child: chewieController.videoPlayerController.value.isInitialized
                ? const CupertinoActivityIndicator()
                : Chewie(
                    controller: chewieController,
                  ),
          ),
        );
      }
      if (islastmedia && indexlength > 4) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.dstATop,
              ),
              image: CachedNetworkImageProvider(
                mediaUrl,
                errorListener: (p0) => const Icon(Icons.error),
              ),
              fit: fit,
            ),
          ),
          child: Center(
              child: Text(
            "+${indexlength - 4}",
            style: const TextStyle(fontSize: 50),
          )),
        );
      } else {
        return PinchZoom(
          child: CachedNetworkImage(
            imageUrl: mediaUrl,
            fit: fit,
            // width: width, Genişlik Kafayı yediği için yorum satırına aldık
            height: height,
            placeholder: (context, url) => const CupertinoActivityIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );
      }
    }

    Widget mediayerlesim = const Row();

    if (postInfo.value.media != null) {
      List<Row> mediaItems = [];

      List<Widget> mediarow1 = [];
      List<Widget> mediarow2 = [];
      for (int i = 0; i < postInfo.value.media!.length; i++) {
        if (i > 3) {
          continue;
        }

        List media = postInfo.value.media![i].mediaType!.split('/');

        if (media[0] == "video") {
          mediarow1.clear();
          mediarow1.add(
            mediaSablon(
              indexlength: postInfo.value.media!.length,
              postInfo.value.media![i].mediaURL.normalURL,
              isvideo: true,
            ),
          );
          break;
        }

        BoxFit mediadirection = BoxFit.cover;
        if (postInfo.value.media![i].mediaDirection.toString() == "yatay" &&
            postInfo.value.media!.length == 1) {
          mediadirection = BoxFit.contain;
        }

        double mediawidth = ARMOYU.screenWidth;
        double mediaheight = ARMOYU.screenHeight;
        if (postInfo.value.media!.length == 1) {
          mediawidth = mediawidth / 1;

          mediaheight = mediaheight / 2;
        } else if (postInfo.value.media!.length == 2) {
          mediawidth = mediawidth / 2;
          mediaheight = mediaheight / 4;
        } else if (postInfo.value.media!.length == 3) {
          if (i == 0) {
            mediawidth = mediawidth / 1;
            mediaheight = mediaheight / 2.5;
          } else {
            mediawidth = mediawidth / 2;
            mediaheight = mediaheight / 4;
          }
        } else if (postInfo.value.media!.length >= 4) {
          mediawidth = mediawidth / 2;
          mediaheight = mediaheight / 4;
        }

        GestureDetector aa = GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PhotoviewerView(
                  service: service,
                  currentUserID: currentUser!.userID!,
                  media: postInfo.value.media!
                      .map(
                        (e) => Media(
                          mediaID: e.mediaID,
                          mediaURL: MediaURL(
                            bigURL: Rx(e.mediaURL.bigURL),
                            normalURL: Rx(e.mediaURL.normalURL),
                            minURL: Rx(e.mediaURL.minURL),
                          ),
                        ),
                      )
                      .toList(),
                  initialIndex: i,
                ),
              ),
            );
          },
          child: mediaSablon(
            indexlength: postInfo.value.media!.length,
            postInfo.value.media![i].mediaURL.normalURL,
            width: mediawidth,
            height: mediaheight,
            fit: mediadirection,
            islastmedia: i == 3,
          ),
        );

        if (postInfo.value.media!.length == 3) {
          if (i == 0) {
            mediarow1.add(aa);
          } else {
            mediarow2.add(aa);
          }
        } else if (postInfo.value.media!.length >= 4) {
          if (i == 0 || i == 1) {
            mediarow1.add(aa);
          } else {
            mediarow2.add(aa);
          }
        } else {
          mediarow1.add(aa);
        }
      }

      mediaItems.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: mediarow1,
      ));
      mediaItems.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: mediarow2,
      ));
      /////////////////////////////////////////////////

      /////////////////////////////////////////////////
      mediayerlesim = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: mediaItems,
      );
    }
    return mediayerlesim;
  }
}
