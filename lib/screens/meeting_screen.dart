import 'package:flutter/material.dart';
import 'package:flutter_ion_conference/screens/chat_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion_conference/providers/ion.dart';
import 'package:provider/provider.dart';

class BoxSize {
  BoxSize({required this.width, required this.height});
  double width;
  double height;
}

class MeetingScreen extends StatefulWidget {
  static const routeName = '/meeting';
  const MeetingScreen({Key? key}) : super(key: key);

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final double localWidth = 114.0;
  final double localHeight = 72.0;

  BoxSize localVideoBoxSize(Orientation orientation) {
    return BoxSize(
      width: (orientation == Orientation.portrait) ? localHeight : localWidth,
      height: (orientation == Orientation.portrait) ? localWidth : localHeight,
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Text(
            'Waiting for others to join...',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return OrientationBuilder(builder: (context, orientation) {
      return SafeArea(
        child: Scaffold(
          body: Consumer<IonController>(
            builder: (context, controller, _) {
              final remoteVideos = controller.participants;
              final index = remoteVideos.indexWhere((element) => element.local);
              final localVideo =
                  index < 0 ? null : remoteVideos.removeAt(index);
              return Container(
                color: Colors.black87,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: Container(
                                child: remoteVideos.isEmpty
                                    ? Image.asset(
                                        'assets/images/loading.jpeg',
                                        fit: BoxFit.cover,
                                      )
                                    : remoteVideos[0].webcamStream == null
                                        ? Container()
                                        : GestureDetector(
                                            onDoubleTap: () {
                                              remoteVideos[0]
                                                  .webcamStream!
                                                  .switchObjFit();
                                            },
                                            child: RTCVideoView(
                                                remoteVideos[0]
                                                    .webcamStream!
                                                    .renderer!,
                                                objectFit: RTCVideoViewObjectFit
                                                    .RTCVideoViewObjectFitContain)),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 48,
                              child: Container(
                                child: localVideo == null
                                    ? Container()
                                    : SizedBox(
                                        width: localVideoBoxSize(orientation)
                                            .width,
                                        height: localVideoBoxSize(orientation)
                                            .height,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: GestureDetector(
                                              onTap: () {
                                                controller.switchCamera();
                                              },
                                              onDoubleTap: () {
                                                localVideo.webcamStream!
                                                    .switchObjFit();
                                              },
                                              child: RTCVideoView(
                                                  localVideo
                                                      .webcamStream!.renderer!,
                                                  objectFit: localVideo
                                                      .webcamStream!.objFit)),
                                        )),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 48,
                              height: 90,
                              child: Container(
                                margin: const EdgeInsets.all(6.0),
                                child: remoteVideos.length <= 1
                                    ? Container()
                                    : ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: remoteVideos
                                            .getRange(1, remoteVideos.length)
                                            .map((participant) {
                                          participant.webcamStream?.objectFit =
                                              RTCVideoViewObjectFit
                                                  .RTCVideoViewObjectFitCover;
                                          return SizedBox(
                                            width: 120,
                                            height: 90,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: participant.webcamStream ==
                                                      null
                                                  ? Container()
                                                  : GestureDetector(
                                                      onTap: () => controller
                                                          .swapParticipant(
                                                              participant.uid),
                                                      onDoubleTap: () =>
                                                          participant
                                                              .webcamStream!
                                                              .switchObjFit(),
                                                      child: RTCVideoView(
                                                          participant
                                                              .webcamStream!
                                                              .renderer!,
                                                          objectFit: participant
                                                              .webcamStream!
                                                              .objFit)),
                                            ),
                                          );
                                        }).toList()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    (remoteVideos.isEmpty) ? _buildLoading() : Container(),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: Stack(
                        children: <Widget>[
                          Opacity(
                            opacity: 0.5,
                            child: Container(
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            height: 48,
                            margin: const EdgeInsets.all(0.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: RawMaterialButton(
                                    shape: const CircleBorder(
                                      side: BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      controller.cameraOff
                                          ? Icons.videocam_off_rounded
                                          : Icons.videocam_rounded,
                                      color: controller.cameraOff
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                    onPressed: controller.turnCamera,
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: RawMaterialButton(
                                    shape: const CircleBorder(
                                      side: BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.video_call,
                                      color: Colors.white,
                                    ),
                                    onPressed: controller.switchCamera,
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: RawMaterialButton(
                                    shape: const CircleBorder(
                                      side: BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      controller.microphoneOff
                                          ? Icons.mic_off_rounded
                                          : Icons.mic_rounded,
                                      color: controller.microphoneOff
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                    onPressed: controller.turnMicrophone,
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: RawMaterialButton(
                                    shape: const CircleBorder(
                                      side: BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      controller.speakerOn
                                          ? Icons.speaker
                                          : Icons.headphones,
                                      color: Colors.white,
                                    ),
                                    onPressed: controller.switchSpeaker,
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: RawMaterialButton(
                                    shape: const CircleBorder(
                                      side: BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.phone_disabled,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final res = await showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Hangup"),
                                          content: const Text(
                                              "Are you sure to leave the room?"),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text("Cancel"),
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text(
                                                "Hangup",
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onPressed: () async {
                                                await controller.close();
                                                Navigator.of(ctx).pop(true);
                                              },
                                            )
                                          ],
                                        ),
                                      );
                                      if (res == true) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 48,
                      child: Stack(
                        children: <Widget>[
                          Opacity(
                            opacity: 0.5,
                            child: Container(
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(0.0),
                            child: Center(
                              child: Text(
                                'ION Conference [${controller.sid}]',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(
                                  Icons.people,
                                  size: 28.0,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Participants'),
                                      content: Container(
                                        width: deviceSize.aspectRatio > 1
                                            ? deviceSize.width * 0.5
                                            : deviceSize.width * 0.8,
                                        height: deviceSize.height * 0.6,
                                        child: ListView.builder(
                                          itemCount:
                                              controller.participants.length,
                                          itemBuilder: (context, index) =>
                                              ListTile(
                                            leading: CircleAvatar(),
                                            title: Text(controller
                                                .participants[index].name),
                                            subtitle: Text(controller
                                                    .participants[index].mid ??
                                                'No video'),
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              //Chat message
                              IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 28.0,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(ChatScreen.routeName);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
