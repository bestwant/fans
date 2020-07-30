import 'dart:ui';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:snsmax/cloudbase/commands/MomentVoteSelectCommand.dart';
import 'package:snsmax/cloudbase/commands/moment-like-toggle-command.dart';
import 'package:snsmax/models/MomentVoteUserSelected.dart';
import 'package:snsmax/models/media.dart';
import 'package:snsmax/models/moment-like-history.dart';
import 'package:snsmax/models/moment.dart';
import 'package:snsmax/models/user.dart' hide UserBuilder;
import 'package:snsmax/models/vote.dart';
import 'package:snsmax/pages/login.dart';
import 'package:snsmax/provider/MomentHasLikedProvider.dart';
import 'package:snsmax/provider/MomentVoteHasSelectedProvider.dart';
import 'package:snsmax/provider/cached-network-file.dart';
import 'package:snsmax/widgets/UserAvatarWidget.dart';
import 'package:snsmax/widgets/docs/MomentVoteUserSelectedDocBuilder.dart';

import '../cloudbase.dart';
import 'CachedNetworkImageBuilder.dart';
import 'MomentLikedHistoryDocBuilder.dart';
import 'UserDocBuilder.dart';
import '../utils/date-time-extension.dart';
import '../utils/number-extension.dart';

class MomentListTile extends StatelessWidget {
  const MomentListTile(
    this.moment, {
    Key key,
  }) : super(key: key);

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UserDocBuilder(
              id: moment.userId,
              builder: (BuildContext context, User user) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatarWidget(
                    radius: 24,
                    fileId: user.avatar,
                  ),
                  title:
                      Text(user.nickName ?? "用户" + user.id.hashCode.toString()),
                  subtitle: Text(moment.createdAt.formNow),
                  trailing: Icon(Icons.more_vert),
                );
              },
            ),
            buildText(moment),
            MomentImageCard(
              moment: moment,
              margin: EdgeInsets.symmetric(vertical: 6),
            ),
            MomentVideoCard(
              moment: moment,
              margin: EdgeInsets.symmetric(vertical: 6),
            ),
            MomentAudioCard(
              moment: moment,
              margin: EdgeInsets.symmetric(vertical: 6),
            ),
            MomentVoteCard(
              moment: moment,
              margin: EdgeInsets.symmetric(vertical: 6),
            ),
            _MomentCardToolBar(moment: moment),
          ],
        ),
      ),
    );
  }

  Widget buildText(Moment moment) {
    if (moment.audio is MediaAudio) {
      return SizedBox();
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(moment.text),
    );
  }
}

class _MomentCardToolBar extends StatelessWidget {
  const _MomentCardToolBar({
    Key key,
    @required this.moment,
  }) : super(key: key);

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        FlatButton.icon(
          onPressed: () {},
          icon: Icon(Icons.share),
          label: Text('分享'),
        ),
        FlatButton.icon(
          onPressed: () {},
          icon: Icon(Icons.forum),
          label: Text((moment.count?.comment ?? 0) > 0
              ? moment.count.comment.compact
              : '评论'),
        ),
        buildLikeButton(context),
      ],
    );
  }

  Widget buildLikeButton(BuildContext context) {
    Widget childBuinder(hasLiked) {
      return FlatButton.icon(
        onPressed: () => onLikeToggle(context),
        icon: Icon(hasLiked == true ? Icons.favorite : Icons.favorite_border),
        label: Text(
            (moment.count?.like ?? 0) > 0 ? moment.count.like.compact : '喜欢'),
        textColor: hasLiked == true ? Colors.red : null,
      );
    }

    return MomentLikedHistoryDocBuilder(
      id: moment.id,
      builder: (BuildContext context, MomentLikeHistory history) =>
          childBuinder(history != null),
      loadingBuilder: (_) => childBuinder(false),
      errorBuilder: (_, __) => childBuinder(false),
    );
  }

  onLikeToggle(BuildContext context) async {
    final hasLogin = await LoginPage.route(context);
    if (!hasLogin) {
      return BotToast.showText(text: '请先登录');
    }
    final command = MomentLikeToggleCommand(moment.id);
    CloudBase().command(command);
  }
}

class MomentVoteCard extends StatelessWidget {
  const MomentVoteCard({
    Key key,
    @required this.moment,
    this.margin,
  }) : super(key: key);

  final Moment moment;
  final EdgeInsets margin;

  List<Vote> get vote => moment.vote?.toList();
  int get voteCount =>
      vote?.fold<int>(0,
          (previousValue, element) => previousValue + (element.count ?? 0)) ??
      0;

  @override
  Widget build(BuildContext context) {
    if (vote == null || vote.isEmpty) {
      return SizedBox();
    }

    return ListView.builder(
      padding: margin,
      itemBuilder: itemBuilder,
      itemCount: vote.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    Vote item = vote[index];
    double value = (item.count ?? 0) / voteCount;
    if (value.isNaN) {
      value = 0;
    }

    final defaultProgress = createProgress(context, value, false);

    return GestureDetector(
      onTap: () => onSelectVote(context, item.name),
      child: Container(
        height: 32.0,
        margin: EdgeInsets.only(top: index == 0 ? 0 : 6),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              child: MomentVoteUserSelectedDocBuilder(
                id: moment.id,
                builder: (BuildContext context, MomentVoteUserSelected vote) {
                  return createProgress(context, value, vote.vote == item.name);
                },
                loadingBuilder: (_) => defaultProgress,
                errorBuilder: (_, __) => defaultProgress,
              ),
              borderRadius: BorderRadius.circular(32.0),
            ),
            Positioned(
              child: Align(
                alignment:
                    voteCount == 0 ? Alignment.center : Alignment.centerLeft,
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ),
              left: 12,
              top: 0,
              bottom: 0,
              right: voteCount == 0 ? 0 : null,
            ),
            buildPercentage(value, context),
          ],
        ),
      ),
    );
  }

  LinearProgressIndicator createProgress(
      BuildContext context, double value, bool selected) {
    Color color = selected
        ? Theme.of(context).primaryColor.withOpacity(0.8)
        : Colors.black.withOpacity(0.12);
    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.black.withOpacity(0.1),
      valueColor: AlwaysStoppedAnimation<Color>(color),
    );
  }

  Widget buildPercentage(double value, BuildContext context) {
    if (voteCount == 0) {
      return SizedBox();
    }
    return Positioned(
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          value.format("##.##%"),
          style: Theme.of(context).textTheme.caption,
        ),
      ),
      right: 12,
      top: 0,
      bottom: 0,
    );
  }

  onSelectVote(BuildContext context, String text) {
    if (context.read<MomentVoteHasSelectedProvider>().containsKey(moment.id)) {
      return;
    }
    CancelFunc cancel = BotToast.showLoading();
    final command = MomentVoteSelectCommand(moment.id, text);
    CloudBase().command(command).catchError((e) {
      BotToast.showText(text: '操作失败');
    }).whenComplete(() => cancel());
  }
}

class MomentAudioCard extends StatefulWidget {
  const MomentAudioCard({
    Key key,
    @required this.moment,
    this.margin,
  }) : super(key: key);

  final Moment moment;
  final EdgeInsets margin;

  @override
  _MomentAudioCardState createState() => _MomentAudioCardState();
}

class _MomentAudioCardState extends State<MomentAudioCard> {
  MediaAudio get audio => widget.moment.audio;

  bool get allowBuildWidget => audio is MediaAudio;

  AssetsAudioPlayer _player;

  @override
  void deactivate() {
    _player?.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(MomentAudioCard oldWidget) {
    if (oldWidget.moment != widget.moment) {
      _player?.stop();
      _player?.dispose();
      _player = null;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _player?.stop();
    _player?.dispose();
    super.dispose();
  }

  _createAudioPlayer([bool autoStart = false]) async {
    AssetsAudioPlayer.allPlayers().values.forEach((element) => element.stop());
    final provider = context.read<CachedNetworkFileProvider>();
    DownloadMetadata meta = provider[audio.src];
    if (meta == null || !provider.containsKey(audio.src)) {
      CloudBaseStorageRes<List<DownloadMetadata>> result =
          await CloudBase().storage.getFileDownloadURL([audio.src]);
      provider.originInsertOrUpdate(result.data);

      meta = provider[audio.src];
    }
    setState(() {
      _player = AssetsAudioPlayer.withId(audio.src)
        ..open(
          Audio.network(meta.downloadUrl),
          autoStart: autoStart,
          loopMode: LoopMode.none,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (allowBuildWidget != true) {
      return SizedBox();
    }

    final ImageProvider defaultImage = AssetImage('assets/audio-bg.jpg');
    final defaultChild = builder(context, defaultImage);
    if (audio.cover != null && audio.cover.isNotEmpty) {
      return CachedNetworkImageBuilder(
        fileId: audio.cover,
        builder: builder,
        progressIndicatorBuilder: (BuildContext context, _) => defaultChild,
        errorBuilder: (BuildContext context, _) => defaultChild,
        placeholderBuilder: (BuildContext context) => defaultChild,
      );
    }

    return defaultChild;
  }

  Widget builder(BuildContext context, ImageProvider image) {
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AspectRatio(
          aspectRatio: 3,
          child: DecoratedBox(
            decoration: buildBackgroundBoxDecoration(image),
            child: buildChild(context, image),
          ),
        ),
      ),
    );
  }

  Widget buildChild(BuildContext context, ImageProvider image) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            buildText(context),
            SizedBox(width: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  playerLayoutBuilder(context, constraints, image),
            ),
          ],
        ),
      ),
    );
  }

  Widget playerLayoutBuilder(
      BuildContext context, BoxConstraints constraints, ImageProvider image) {
    return SizedBox(
      width: constraints.maxHeight,
      height: constraints.maxHeight,
      child: Stack(
        overflow: Overflow.clip,
        fit: StackFit.expand,
        children: <Widget>[
          buildProgress(context),
          buildAudioPlayer(image, constraints, context),
        ],
      ),
    );
  }

  Positioned buildAudioPlayer(
      ImageProvider image, BoxConstraints constraints, BuildContext context) {
    return Positioned.fill(
      child: CircleAvatar(
        backgroundImage: image,
        radius: constraints.maxHeight / 2,
        child: Stack(
          children: <Widget>[
//            buildAudioTime(context),
            buildAudioButton(),
          ],
        ),
      ),
    );
  }

  Widget buildAudioButton() {
    Widget child = Positioned.fill(
      child: UnconstrainedBox(
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white,
            ),
          ),
          child: buildAudioPlayOrSuspendButton(),
        ),
      ),
    );
    if (_player == null) {
      return child;
    }

    return _player.builderIsBuffering(
        builder: (BuildContext context, bool isBuffering) {
      if (isBuffering) {
        return GFLoader(
          type: GFLoaderType.circle,
        );
      }

      return child;
    });
  }

  Widget buildAudioPlayOrSuspendButton() {
    if (_player == null) {
      return GestureDetector(
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 28,
        ),
        onTap: () => _createAudioPlayer(true),
      );
    }

    return _player.builderIsPlaying(
        builder: (BuildContext context, bool isPlaying) {
      return GestureDetector(
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 28,
        ),
        onTap: () {
          if (isPlaying) {
            _player.stop();
          } else {
            AssetsAudioPlayer.allPlayers()
                .values
                .forEach((element) => element.stop());
            _player.play();
          }
        },
      );
    });
  }

  Widget buildProgress(BuildContext context) {
    if (_player == null) {
      return SizedBox();
    }

    return _player.builderCurrent(
      builder: (BuildContext context, Playing playing) {
        if (playing == null) {
          return SizedBox();
        }

        return _player.builderIsPlaying(
            builder: (BuildContext context, bool isPlaying) {
          if (isPlaying != true) {
            return SizedBox();
          }
          return _player.builderCurrentPosition(
              builder: (BuildContext context, Duration duration) {
            if ((playing.audio.duration.inSeconds - duration.inSeconds) <= 1) {
              return SizedBox();
            }
            return Positioned.fill(
              child: CircularProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
                value: duration.inMilliseconds /
                    playing.audio.duration.inMilliseconds,
              ),
            );
          });
        });
      },
    );
  }

  Expanded buildText(BuildContext context) {
    return Expanded(
      child: Text(
        widget.moment.text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: Theme.of(context).textTheme.caption.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  BoxDecoration buildBackgroundBoxDecoration(ImageProvider image) {
    return BoxDecoration(
      image: DecorationImage(
        image: image,
        fit: BoxFit.cover,
      ),
    );
  }
}

class MomentVideoCard extends StatelessWidget {
  const MomentVideoCard({
    Key key,
    @required this.moment,
    this.margin,
  }) : super(key: key);

  final Moment moment;
  final EdgeInsets margin;

  MediaVideo get video => moment.video;
  bool get allowBuild => video is MediaVideo;

  @override
  Widget build(BuildContext context) {
    if (!allowBuild) {
      return SizedBox();
    }
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: CachedNetworkImageBuilder(
                  fileId: video.cover,
                  fit: BoxFit.cover,
                  rule: "imageMogr2/scrop/854x480/cut/854x480/format/yjpeg",
                ),
              ),
              Positioned.fill(
                child: UnconstrainedBox(
                  child: FloatingActionButton(
                    backgroundColor: Colors.black45,
                    onPressed: () {},
                    child: Icon(
                      Icons.play_arrow,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MomentImageCard extends StatelessWidget {
  const MomentImageCard({
    Key key,
    @required this.moment,
    this.margin,
  }) : super(key: key);

  final Moment moment;
  final EdgeInsets margin;

  List<String> get images => moment.images?.toList();

  bool get allowRunBuild => images is List && images.isNotEmpty;

  int get length => images?.length ?? 0;

  double get childAspectRatio {
    switch (length) {
      case 1:
        return 16 / 9;
      case 2:
      case 4:
        return 1.5;
      default:
        return 1.0;
    }
  }

  int get crossAxisCount {
    if (length <= 2) {
      return length;
    } else if (length == 4) {
      return 2;
    }

    return 3;
  }

  String get rule {
    switch (length) {
      case 1:
        return "imageMogr2/scrop/854x480/cut/854x480/format/yjpeg";
      case 2:
      case 4:
        return "imageMogr2/scrop/432x288/cut/432x288/format/yjpeg";
      default:
        return "imageMogr2/scrop/360x360/cut/360x360/format/yjpeg";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (allowRunBuild != true) {
      return SizedBox();
    }

    return GridView.builder(
      padding: margin ?? EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (BuildContext context, int index) {
        return ClipRRect(
          child: CachedNetworkImageBuilder(
            fileId: images[index],
            fit: BoxFit.cover,
            rule: rule,
          ),
          borderRadius: BorderRadius.circular(6),
        );
      },
      itemCount: images.length,
    );
  }
}