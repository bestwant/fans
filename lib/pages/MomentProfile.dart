import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:fans/cloudbase/function/FunctionMomentQuery.dart';
import 'package:fans/models/moment.dart';
import 'package:fans/models/user.dart';
import 'package:fans/routes.dart';
import 'package:fans/utils/number-extension.dart';
import 'package:fans/widgets/UserAvatarWidget.dart';
import 'package:fans/widgets/buttons/RowBadgeButton.dart';
import 'package:fans/widgets/cloudbase/database/collections/TcbDbMomentDocBuilder.dart';
import 'package:fans/widgets/cloudbase/database/collections/TcbDbMomentLikeStatusBuilder.dart';
import 'package:fans/widgets/cloudbase/database/collections/TcbDbUserDocBuilder.dart';
import 'package:fans/widgets/cloudbase/storage/TcbStorageImageFileBuilder.dart';
import 'package:fans/widgets/empty.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'login.dart';

typedef Widget _PanelWidgetBuilder(ScrollController controller);

class MomentProfileController with ChangeNotifier {
  MomentProfileController(
    this.momentId, {
    this.mediaAutoPlay = false,

    /// 分页控制器，指定 images 初始位置很有用
    PageController pageController,
  })  : this._pageController = (pageController is PageController
            ? pageController
            : PageController(initialPage: 0, keepPage: true)),
        this._pageViewChildrenIndex = (pageController?.initialPage ?? 0) + 1;

  /// 必须，动态 ID
  final String momentId;

  /// 是否自动播放媒体
  final bool mediaAutoPlay;

  final PageController _pageController;
  PageController get pageController => _pageController;

  bool _hasPanelIsOpen = false;
  bool get hasPanelIsOpen => _hasPanelIsOpen;
  set hasPanelIsOpen(bool newValue) {
    _hasPanelIsOpen = newValue;
    notifyListeners();
  }

  int _pageViewChildrenTotal = 0;
  int get pageViewChildrenTotal => _pageViewChildrenTotal;
  set pageViewChildrenTotal(int newValue) {
    _pageViewChildrenTotal = newValue;
    notifyListeners();
  }

  int _pageViewChildrenIndex = 1;
  int get pageViewChildrenIndex => _pageViewChildrenIndex;
  set pageViewChildrenIndex(int newValue) {
    _pageViewChildrenIndex = newValue;
    notifyListeners();
  }
}

class _MomentProfilePanelSettings {
  const _MomentProfilePanelSettings._();

  static bool get parallaxEnabled => true;
  static double get parallaxOffset => .4;
  static BorderRadius get borderRadius => const BorderRadius.vertical(
        top: const Radius.circular(24.0),
      );
  static double get minHeight => 100.0;
  static double get maxHeightRatio => .7;
  static double get tapBarContainerHeight => 24.0;
}

class MomentProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final MomentProfileController controller =
        ModalRoute.of(context).settings.arguments;
    return ChangeNotifierProvider<MomentProfileController>.value(
      value: controller,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: appBarBuilder(context),
        body: bodyBuilder(context),
      ),
    );
  }

  SlidingUpPanel bodyBuilder(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height *
        _MomentProfilePanelSettings.maxHeightRatio;

    return SlidingUpPanel(
      parallaxEnabled: _MomentProfilePanelSettings.parallaxEnabled,
      parallaxOffset: _MomentProfilePanelSettings.parallaxOffset,
      borderRadius: _MomentProfilePanelSettings.borderRadius,
      minHeight: _MomentProfilePanelSettings.minHeight,
      maxHeight: maxHeight,
      color: Theme.of(context).cardColor,
      panelBuilder: panelBuilder(context),
      header: _MomentProfilePanelTapBar(),
      body: _MomentProfilePageView(),
    );
  }

  _PanelWidgetBuilder panelBuilder(BuildContext context) {
    return (ScrollController controller) {
      return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Padding(
          padding: EdgeInsets.only(
              top: _MomentProfilePanelSettings.tapBarContainerHeight),
          child: _MomentProfilePanel(controller),
        ),
      );
    };
  }

  AppBar appBarBuilder(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.color.withOpacity(0.12),
      leading: BackButton(
        onPressed: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            return navigator.pop();
          }

          navigator.pushReplacementNamed(R_initialRoute);
        },
      ),
      centerTitle: false,
      title: _ProgressIndicator(),
      actions: [
        _MomentProfileHeaderUserAction(),
        IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }
}

class _MomentProfileSelector extends StatelessWidget {
  final AsyncWidgetBuilder<Moment> builder;

  const _MomentProfileSelector({
    @required this.builder,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<MomentProfileController, String>(
      builder: (BuildContext context, String momentId, _) {
        return TcbDbMomentDocBuilder(momentId: momentId, builder: builder);
      },
      selector: selector,
    );
  }

  String selector(BuildContext context, MomentProfileController controller) {
    return controller.momentId;
  }
}

class _MomentProfileUserSelector extends StatelessWidget {
  final AsyncWidgetBuilder<User> builder;
  const _MomentProfileUserSelector({
    Key key,
    @required this.builder,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return _MomentProfileSelector(builder: userChildBuilder);
  }

  Widget userChildBuilder(
      BuildContext context, AsyncSnapshot<Moment> snapshot) {
    if (snapshot.hasError) {
      return builder(
        context,
        AsyncSnapshot.withError(snapshot.connectionState, snapshot.error),
      );
    } else if (snapshot.connectionState == ConnectionState.done &&
        snapshot.hasData) {
      return TcbDbUserDocBuilder(
          userId: snapshot.data.userId, builder: builder);
    }

    return builder(
      context,
      AsyncSnapshot.withData(snapshot.connectionState, null),
    );
  }
}

class _MomentProfileHeaderUserAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MomentProfileUserSelector(builder: builder);
  }

  Widget builder(BuildContext context, AsyncSnapshot<User> snapshot) {
    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
      return childBuilder(context, snapshot.data);
    }

    return SizedBox.shrink();
  }

  Widget childBuilder(BuildContext context, User user) {
    return Align(
      alignment: Alignment.centerRight,
      child: UnconstrainedBox(
        child: Container(
          constraints: BoxConstraints(maxWidth: 140.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white24
                : Colors.black12,
            borderRadius: BorderRadius.circular(36.0),
          ),
          height: 36.0,
          // margin: EdgeInsets.only(right: 14.0),
          padding: EdgeInsets.only(left: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              UserAvatarWidget(
                radius: 18.0,
              ),
              Expanded(
                child: Text(
                  user.nickName.isNotEmpty ? user.nickName : user.id,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.button,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<MomentProfileController, MapEntry<int, int>>(
      shouldRebuild: (oldValue, newValue) {
        return oldValue != newValue;
      },
      selector: (_, provider) {
        return MapEntry(
          provider.pageViewChildrenIndex,
          provider.pageViewChildrenTotal,
        );
      },
      builder: (_, progress, __) {
        final index = progress.key;
        final total = progress.value;

        if (total is int && total > 1) {
          return Text(
            '$index/$total',
            style: Theme.of(context).textTheme.bodyText1,
          );
        }

        return SizedBox.shrink();
      },
    );
  }
}

class _MomentProfilePanelTapBar extends StatelessWidget {
  const _MomentProfilePanelTapBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final Color tapBarColor = media.platformBrightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final double tabBarHeight = 6.0;
    final double tabBarWidget = 64.0;
    return Container(
      width: media.size.width,
      height: _MomentProfilePanelSettings.tapBarContainerHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: _MomentProfilePanelSettings.borderRadius,
      ),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: tabBarWidget,
          height: tabBarHeight,
          decoration: BoxDecoration(
            color: tapBarColor,
            borderRadius: BorderRadius.circular(tabBarHeight),
          ),
        ),
      ),
    );
  }
}

class _MomentProfilePageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: _MomentProfilePanelSettings.minHeight -
            _MomentProfilePanelSettings.tapBarContainerHeight,
      ),
      child: Selector<MomentProfileController, String>(
        builder: momentBuilder,
        selector: momentIdSelector,
      ),
    );
  }

  Widget momentBuilder(BuildContext context, String momentId, _) {
    return TcbDbMomentDocBuilder(
      momentId: momentId,
      builder: asyncSnapshotBuilder,
    );
  }

  Widget asyncSnapshotBuilder(
    BuildContext context,
    AsyncSnapshot<Moment> snapshot,
  ) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return Empty(
          type: EmptyTypes.network,
          text: '网络貌似发生了错误',
        );
        break;
      case ConnectionState.active:
      case ConnectionState.waiting:
        return Empty(
          type: EmptyTypes.package,
          child: GFLoader(
            type: GFLoaderType.circle,
          ),
        );
        break;
      case ConnectionState.done:
        return selectorBuilder(snapshot.data);
        break;
    }

    return Empty(
      type: EmptyTypes.ghost,
      text: '当前动态貌似走丢了',
    );
  }

  Widget selectorBuilder(Moment moment) {
    return Selector<MomentProfileController, PageController>(
      shouldRebuild: (_, __) => false,
      selector: pageControllerSelector,
      builder: (BuildContext context, PageController controller, __) {
        final List<Widget> children = mediaBuilder(context, moment);
        return PageView(
          children: children,
          controller: controller,
          onPageChanged: (int page) {
            context.read<MomentProfileController>().pageViewChildrenIndex =
                page + 1;
          },
        );
      },
    );
  }

  List<Widget> mediaBuilder(BuildContext context, Moment moment) {
    if (moment.images != null || moment.images.isNotEmpty) {
      return mediaImagesBuilder(context, moment.images.toList());
    }

    return [Text('22222')];
  }

  List<Widget> mediaImagesBuilder(BuildContext context, List<String> images) {
    final provider =
        Provider.of<MomentProfileController>(context, listen: false);
    Future.delayed(Duration(seconds: 1)).then((value) {
      provider.pageViewChildrenTotal = images.length;
    });

    return images.map<Widget>(mediaImagesChildBuilder).toList();
  }

  Widget mediaImagesChildBuilder(String fileId) {
    return TcbStorageImageFileBuilder(
      fileId: fileId,
      progressIndicatorBuilder: (context, _, __) {
        return UnconstrainedBox(
          child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        );
      },
      builder: (context, image) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image(
                image: image,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: PhotoView(
                  imageProvider: image,
                  backgroundDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.contained * 4.0,
                  enableRotation: false,
                  tightMode: false,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ],
        );
        // return PhotoView(
        //   imageProvider: image,
        //   backgroundDecoration: BoxDecoration(
        //     color: Colors.transparent,
        //   ),
        //   initialScale: PhotoViewComputedScale.contained,
        //   minScale: PhotoViewComputedScale.contained,
        //   maxScale: PhotoViewComputedScale.contained * 4.0,
        //   enableRotation: false,
        //   tightMode: false,
        //   gaplessPlayback: true,
        // );
      },
    );
  }

  PageController pageControllerSelector(
    BuildContext context,
    MomentProfileController controller,
  ) {
    return controller.pageController;
  }

  String momentIdSelector(
      BuildContext context, MomentProfileController controller) {
    return controller.momentId;
  }
}

class _MomentProfilePanel extends StatelessWidget {
  final ScrollController controller;

  const _MomentProfilePanel(this.controller, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: CustomScrollView(
        controller: controller,
        slivers: [
          SliverToBoxAdapter(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                    'https://cdn.learnku.com/uploads/avatars/7973_1481866546.png!/both/400x400'),
              ),
              title: Text('#王者荣耀#'),
              subtitle: Text('上官婉儿 · 7564664个脑残儿'),
              trailing: OutlineButton(
                onPressed: () {},
                child: Text('去看看'),
                shape: StadiumBorder(),
                textColor: Theme.of(context).primaryColor,
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              title: _MomentProfileSelector(builder: (context, snapshot) {
                String number = '0';
                if (snapshot.data is Moment &&
                    snapshot.data.count?.comment != null &&
                    snapshot.data.count.comment > 0) {
                  number = snapshot.data.count.comment.compact;
                }
                return Text(
                  '当前共$number条评论',
                  style: Theme.of(context).textTheme.subtitle2,
                );
              }),
              // TODO: 暂不增加该功能
              // trailing: FlatButton.icon(
              //   onPressed: () {},
              //   icon: Icon(Icons.sort),
              //   label: Text('最新'),
              // ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Text('$index');
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: _PanelBottomAppBar(),
    );
  }
}

class _PanelBottomAppBar extends StatelessWidget {
  const _PanelBottomAppBar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      width: media.size.width,
      height: kBottomNavigationBarHeight + media.padding.bottom,
      child: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            // borderRadius: BorderRadius.vertical(
                            //     top: Radius.circular(24.0)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              TextField(
                                keyboardType: TextInputType.text,
                                autofocus: true,
                                maxLines: 3,
                                minLines: 1,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(12.0),
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 12.0,
                  ),
                  margin: EdgeInsets.only(left: 16.0, right: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).highlightColor,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.forum),
                      SizedBox(width: 6.0),
                      Text('喜欢Ta就评论下吧！'),
                    ],
                  ),
                ),
              ),
            ),
            momentLikeButtonBuilder(),
            SizedBox(width: 12.0),
            RowBadgeButton(
              icon: Icon(Icons.share),
              text: '分享',
            ),
            SizedBox(width: 12.0),
          ],
        ),
      ),
    );
  }

  Widget momentLikeButtonBuilder() {
    return _MomentProfileSelector(
        builder: (BuildContext context, AsyncSnapshot<Moment> snapshot) {
      String text = '喜欢';
      if (snapshot.hasData && snapshot.data is Moment) {
        final moment = snapshot.data;
        if (moment.count?.like != null && moment.count.like > 0) {
          text = moment.count.like.compact;
        }
        return TcbDbMomentLikeStatusBuilder(
          momentId: moment.id,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return RowBadgeButton(
                icon: Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                text: text,
                badgeColor: Colors.red,
                onTap: () => onLikeToggle(context, true, moment.id),
              );
            }
            return RowBadgeButton(
              icon: Icon(Icons.favorite_border),
              text: text,
              onTap: () => onLikeToggle(context, false, moment.id),
            );
          },
        );
      }
      return RowBadgeButton(
        icon: Icon(Icons.favorite_border),
        text: text,
      );
    });
  }

  onLikeToggle(BuildContext context, bool status, String momentId) async {
    final hasLogin = await LoginPage.route(context);
    if (!hasLogin) {
      return BotToast.showText(text: '请先登录');
    } else if (status) {
      FunctionMomentQuery.currentUserUnlikeMoment(momentId);
      return;
    }
    FunctionMomentQuery.currentUserLikeMoment(momentId);
  }
}
