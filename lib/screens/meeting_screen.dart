import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ion_conference/screens/chat_screen.dart';
import 'package:flutter_ion_conference/screens/home_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:flutter_ion_conference/providers/ion.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// class VideoRendererAdapter {
//   String mid;
//   bool local;
//   RTCVideoRenderer? renderer;
//   Object stream;
//   MediaStream get mediaStream =>
//       local ? (stream as LocalStream).stream : (stream as RemoteStream).stream;
//   RTCVideoViewObjectFit _objectFit =
//       RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
//   VideoRendererAdapter._internal(this.mid, this.stream, this.local);

//   static Future<VideoRendererAdapter> create(
//       String mid, Object stream, bool local) async {
//     var renderer = VideoRendererAdapter._internal(mid, stream, local);
//     await renderer.setupSrcObject();
//     return renderer;
//   }

//   setupSrcObject() async {
//     if (renderer == null) {
//       renderer = RTCVideoRenderer();
//       await renderer?.initialize();
//     }
//     renderer?.srcObject = mediaStream;
//     if (local) {
//       _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
//     }
//   }

//   switchObjFit() {
//     _objectFit =
//         (_objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
//             ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
//             : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
//   }

//   RTCVideoViewObjectFit get objFit => _objectFit;

//   set objectFit(RTCVideoViewObjectFit objectFit) {
//     _objectFit = objectFit;
//   }

//   Future<void> dispose() async {
//     if (renderer != null) {
//       print('dispose for texture id ' + renderer!.textureId.toString());
//       renderer?.srcObject = null;
//       await renderer?.dispose();
//       if (local) {
//         await (stream as LocalStream).unpublish();
//         mediaStream.getTracks().forEach((element) {
//           element.stop();
//         });
//         await mediaStream.dispose();
//       }
//     }
//   }
// }

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
    return OrientationBuilder(builder: (context, orientation) {
      return SafeArea(
        child: Scaffold(
          body: Consumer<IonController>(
            builder: (context, controller, _) {
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
                                child: controller.remoteVideos.isEmpty
                                    ? Image.asset(
                                        'assets/images/loading.jpeg',
                                        fit: BoxFit.cover,
                                      )
                                    : GestureDetector(
                                        onDoubleTap: () {
                                          controller.remoteVideos[0]
                                              .switchObjFit();
                                        },
                                        child: RTCVideoView(
                                            controller
                                                .remoteVideos[0].renderer!,
                                            objectFit: RTCVideoViewObjectFit
                                                .RTCVideoViewObjectFitContain)),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 48,
                              child: Container(
                                child: controller.localVideo == null
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
                                                controller.localVideo
                                                    ?.switchObjFit();
                                              },
                                              child: RTCVideoView(
                                                  controller
                                                      .localVideo!.renderer!,
                                                  objectFit: controller
                                                      .localVideo!.objFit)),
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
                                child: controller.remoteVideos.length <= 1
                                    ? Container()
                                    : ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: controller.remoteVideos
                                            .getRange(1,
                                                controller.remoteVideos.length)
                                            .map((participant) {
                                          participant.objectFit =
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
                                              child: GestureDetector(
                                                  onTap: () => controller
                                                      .swapParticipant(
                                                          participant),
                                                  onDoubleTap: () => participant
                                                      .switchObjFit(),
                                                  child: RTCVideoView(
                                                      participant.renderer!,
                                                      objectFit:
                                                          participant.objFit)),
                                            ),
                                          );
                                        }).toList()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    (controller.remoteVideos.isEmpty)
                        ? _buildLoading()
                        : Container(),
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
                                                Navigator.of(ctx)
                                                    .pop();
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
                                                Navigator.of(ctx)
                                                    .pop(true);
                                              },
                                            )
                                          ],
                                        ),
                                      );
                                      if(res == true){
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
                                onPressed: () {},
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
