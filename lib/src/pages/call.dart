import 'package:agora_flutter/src/utils/settings.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/material.dart';

class CallPage extends StatefulWidget {
  final String? channelName;
  final ClientRole? role;
  const CallPage({super.key, required this.channelName, required this.role});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final users = <int>[];
  final infoStrings = <String>[];
  bool muted = false;
  bool viewPanel = false;
  late RtcEngine engine;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    users.clear();
    engine.leaveChannel();
    engine.destroy();
    super.dispose();
  }

  init() async {
    if (appId.isEmpty) {
      setState(() {
        infoStrings.add("App ID is missing");
        infoStrings.add("Agora Engine is not starting");
      });
      return;
    }
    // Init Agora RTC Engine
    engine = await RtcEngine.create(appId);
    await engine.enableVideo();
    await engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await engine.setClientRole(widget.role!);
    addAgoraEventHandlers();

    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(height: 1920, width: 1080);
    await engine.setVideoEncoderConfiguration(configuration);
    await engine.joinChannel(token, widget.channelName!, null, 0);
  }

  void addAgoraEventHandlers() async {
    engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          infoStrings.add("Error: $code");
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          infoStrings.add("Join Channel: $channel, uid $uid");
        });
      },
      leaveChannel: (stats) {
        setState(() {
          infoStrings.add("Leave Channel");
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          infoStrings.add("User Joined $uid");
        });
      },
      userOffline: (uid, reason) {
        setState(() {
          infoStrings.add("User Offline $uid");
          users.remove(uid);
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          infoStrings.add("First Remote Video: $uid, ${widget}x$height");
        });
      },
    ));
  }

  Widget viewRow() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(const rtc_local_view.SurfaceView());
    }

    for (var uid in users) {
      list.add(rtc_remote_view.SurfaceView(
        uid: uid,
        channelId: widget.channelName!,
      ));
    }
    final views = list;
    return Column(
      children:
          List.generate(views.length, (index) => Expanded(child: views[index])),
    );
  }

  Widget toolBar() {
    if (widget.role == ClientRole.Audience) return const SizedBox();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() {
                muted = !muted;
              });
              engine.muteLocalAudioStream(muted);
            },
            shape: const CircleBorder(),
            elevation: 2,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              engine.switchCamera();
            },
            shape: const CircleBorder(),
            elevation: 2,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget panel() {
    return Visibility(
      visible: viewPanel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: ListView.builder(
              reverse: true,
              itemCount: infoStrings.length,
              itemBuilder: (context, index) {
                if (infoStrings.isEmpty) {
                  return const Text("null");
                }
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            infoStrings[index],
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agora"),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  viewPanel = !viewPanel;
                });
              },
              icon: const Icon(Icons.info_outline))
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            viewRow(),
            panel(),
            toolBar(),
          ],
        ),
      ),
    );
  }
}
