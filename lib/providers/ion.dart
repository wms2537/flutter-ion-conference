import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ion_conference/screens/chat_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class VideoRendererAdapter {
  bool local;
  RTCVideoRenderer? renderer;
  MediaStream stream;
  RTCVideoViewObjectFit _objectFit =
      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;

  VideoRendererAdapter._internal(this.stream, this.local);

  static Future<VideoRendererAdapter> create(
      MediaStream stream, bool local) async {
    var renderer = VideoRendererAdapter._internal(stream, local);
    await renderer.setupSrcObject();
    return renderer;
  }

  setupSrcObject() async {
    if (renderer == null) {
      renderer = new RTCVideoRenderer();
      await renderer?.initialize();
    }
    renderer?.srcObject = stream;
    if (local) {
      _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
  }

  switchObjFit() {
    _objectFit =
        (_objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
            ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
            : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  }

  RTCVideoViewObjectFit get objFit => _objectFit;

  set objectFit(RTCVideoViewObjectFit objectFit) {
    _objectFit = objectFit;
  }

  dispose() async {
    if (renderer != null) {
      print('dispose for texture id ' + renderer!.textureId.toString());
      renderer?.srcObject = null;
      await renderer?.dispose();
      renderer = null;
    }
  }
}

class Participant {
  final String uid;
  final String name;
  final bool local;
  String? webcamMid;
  String? screenMid;
  VideoRendererAdapter? webcamStream;
  VideoRendererAdapter? screenStream;
  Participant(this.uid, this.name, this.local);
}

// void getStats(Client client, MediaStreamTrack track) async {
//   dynamic bytesPrev;
//   double? timestampPrev;
//   Timer.periodic(const Duration(seconds: 1), (timer) async {
//     var results = await client.getSubStats(track);
//     for (var report in results) {
//       var now = report.timestamp;
//       if ((report.type == 'ssrc' || report.type == 'inbound-rtp') &&
//           report.values['mediaType'] == 'video') {
//         var bytes = report.values['bytesReceived'];
//         if (timestampPrev != null) {
//           bitrate = (8 *
//                   (WebRTC.platformIsWeb
//                       ? bytes - bytesPrev
//                       : (int.tryParse(bytes)! - int.tryParse(bytesPrev)!))) /
//               (now - timestampPrev!);
//         }
//         bytesPrev = bytes;
//         timestampPrev = now;
//       }
//     }
//   });
// }

class IonController with ChangeNotifier {
  late SharedPreferences _prefs;
  IonBaseConnector? _connector;
  IonAppBiz? _biz;
  IonSDKSFU? _webcamsfu;
  IonSDKSFU? _screensfu;
  String? _sid;
  String? _name;
  final String _uid = const Uuid().v4();
  final List<Participant> _participants = [];
  final List<ChatMessage> _messages = [];
  Participant? _localParticipant;
  LocalStream? _webcamLocalStream;
  LocalStream? _screenLocalStream;
  Map<String, MediaStream> _waitingStreams = {};
  bool _cameraOff = false;
  bool _microphoneOff = false;
  bool _speakerOn = true;

  String? get sid => _sid;
  bool get cameraOff => _cameraOff;
  bool get microphoneOff => _microphoneOff;
  bool get speakerOn => _speakerOn;
  Participant? get localParticipant => _localParticipant;
  List<ChatMessage> get messages => [..._messages];
  bool get isInit => !(_biz == null || _webcamsfu == null || _sid == null);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    print('[INFO] $_uid');
  }

  SharedPreferences prefs() {
    return _prefs;
  }

  List<Participant> get participants {
    return [..._participants];
  }

  Future<void> connect(String name, String sid) async {
    _name = name;
    _sid = sid;

    _connector = IonBaseConnector('https://ion.wmtech.cc:5551');
    _biz = IonAppBiz(_connector!);
    _webcamsfu = IonSDKSFU(_connector!);
    _screensfu = IonSDKSFU(_connector!);
    _localParticipant = new Participant(_uid, _name!, true);

    _webcamsfu!.ontrack = (MediaStreamTrack track, RemoteStream stream) async {
      if (track.kind == 'video') {
        print(
            '[INFO][ontrack] track kind: ${track.label} ${stream.stream.ownerTag}');
        int index = _participants
            .indexWhere((element) => element.webcamMid == stream.id);
        if (index >= 0) {
          _participants[index].webcamStream =
              await VideoRendererAdapter.create(stream.stream, false);
          notifyListeners();
          return;
        }
        index = _participants
            .indexWhere((element) => element.screenMid == stream.id);
        if (index >= 0) {
          _participants[index].screenStream =
              await VideoRendererAdapter.create(stream.stream, false);
          notifyListeners();
          return;
        }
        print(
            '[INFO][ontrack] remote stream [${stream.id}] not registered, adding to waiting stream list');
        _waitingStreams[stream.id] = stream.stream;
      }
    };

    _webcamsfu!.onspeaker = (Map<String, dynamic> list) {
      print('onspeaker: $list');
    };
    _biz?.onJoin = (bool success, String reason) async {
      if (success) {
        try {
          await enableCamera();
        } catch (error) {
          print(error);
        }
      }
    };

    _biz?.onLeave = (String reason) {
      print(":::Leave success:::");
    };

    _biz?.onPeerEvent = (PeerEvent event) {
      var name = event.peer.info['name'];
      var state = '';
      switch (event.state) {
        case PeerState.NONE:
          break;
        case PeerState.JOIN:
          state = 'join';
          _participants.add(new Participant(event.peer.uid, name, false));
          notifyListeners();
          break;
        case PeerState.UPDATE:
          state = 'upate';
          break;
        case PeerState.LEAVE:
          state = 'leave';
          _participants.removeWhere((element) => element.uid == event.peer.uid);
          notifyListeners();
          break;
      }
      print(":::Peer [${event.peer.uid}:$name] $state:::");
    };

    _biz?.onStreamEvent = (StreamEvent event) async {
      switch (event.state) {
        case StreamState.NONE:
          break;
        case StreamState.ADD:
          if (event.streams.isNotEmpty) {
            var mid = event.streams[0].id;
            final elements = event.uid.split(':');
            print("[INFO][onStreamEvent] stream-add [$mid] [$elements]:::");
            if (elements.first == _uid) return;
            if (elements.last == 'webcam') {
              _participants
                  .firstWhere((element) => element.uid == elements.first)
                    ..webcamMid = mid
                    ..webcamStream = _waitingStreams[mid] != null
                        ? await VideoRendererAdapter.create(
                            _waitingStreams[mid]!, false)
                        : null;
              print('[INFO] webcam stream registered');
              if (_waitingStreams[mid] != null) {
                _waitingStreams.remove(mid);
                notifyListeners();
                print('[INFO] remote stream added');
              }
            } else if (elements.last == 'screen') {
              _participants
                  .firstWhere((element) => element.uid == elements.first)
                    ..screenMid = mid
                    ..screenStream = _waitingStreams[mid] != null
                        ? await VideoRendererAdapter.create(
                            _waitingStreams[mid]!, false)
                        : null;
              print('[INFO] screen stream registered');
              if (_waitingStreams[mid] != null) {
                _waitingStreams.remove(mid);
                notifyListeners();
              }
            }
            if (_webcamLocalStream != null)
              _biz?.message(_uid, _sid!, {
                'type': 'ADD_WEBCAM_STREAM',
                'uid': _uid,
                'name': _name,
                'mid': _webcamLocalStream!.stream.id,
              });
            if (_screenLocalStream != null)
              _biz?.message(_uid, _sid!, {
                'type': 'ADD_SCREEN_STREAM',
                'uid': _uid,
                'name': _name,
                'mid': _screenLocalStream!.stream.id,
              });
          }
          break;
        case StreamState.REMOVE:
          if (event.streams.isNotEmpty) {
            var mid = event.streams[0].id;
            print(":::stream-remove [$mid]:::");
            int index =
                _participants.indexWhere((element) => element.webcamMid == mid);
            if (index >= 0) {
              _participants[index]
                ..webcamMid = null
                ..webcamStream = null;
              return;
            }
            index =
                _participants.indexWhere((element) => element.screenMid == mid);
            if (index >= 0) {
              _participants[index]
                ..screenMid = null
                ..screenStream = null;
              return;
            }
          }
          break;
      }
    };

    _biz?.onMessage = (Message msg) async {
      if (msg.from == _uid) {
        return;
      }
      var info = msg.data;
      switch (info['type']) {
        case 'MESSAGE':
          var sender = info['name'];
          var text = info['text'];
          var uid = info['uid'] as String;
          ChatMessage message = ChatMessage(
            uid,
            text,
            sender,
            DateFormat.jms().format(DateTime.now()),
            isMe: uid == _uid,
          );

          _messages.insert(0, message);
          notifyListeners();
          break;
        case 'ADD_SCREENSHARE':
          _participants.firstWhere((element) => element.uid == info['uid'])
            ..screenMid = info['mid'];
          break;
        case 'ADD_WEBCAM_STREAM':
          _participants.firstWhere((element) => element.uid == info['uid'])
            ..webcamMid = info['mid'];
          break;
        default:
      }
    };

    await _biz!.connect();
    await _webcamsfu!.connect();

    _biz?.join(sid: _sid!, uid: _uid, info: <String, String>{'name': _name!});
  }

  Future<void> close() async {
    if (_webcamLocalStream != null) {
      await _webcamLocalStream!.unpublish();
    }
    if (_screenLocalStream != null) {
      await _screenLocalStream!.unpublish();
    }
    _webcamsfu!.close();
    if (_screensfu!.connected) _screensfu!.close();
    await _localParticipant?.webcamStream?.stream.dispose();
    await _localParticipant?.screenStream?.stream.dispose();
    await Future.wait(_participants.map((item) async {
      try {
        await item.webcamStream?.stream.dispose();
        await item.screenStream?.stream.dispose();
      } catch (error) {}
    }));
    _participants.clear();
    _biz?.leave(_uid);
    _biz?.close();
    _biz = null;
    _screenLocalStream = null;
    _webcamLocalStream = null;
    _localParticipant = null;
  }

  Future<void> enableCamera() async {
    await _webcamsfu!.join(_sid!, '$_uid:webcam');
    var resolution = _prefs.getString('resolution') ?? 'hd';
    var codec = _prefs.getString('codec') ?? 'vp8';
    _webcamLocalStream = await LocalStream.getUserMedia(
        constraints: Constraints.defaults
          ..simulcast = false
          ..resolution = resolution
          ..codec = codec);
    // _biz?.message(_uid, _sid!, {
    //   'type': 'ADD_WEBCAM_STREAM',
    //   'uid': _uid,
    //   'name': _name,
    //   'mid': _webcamLocalStream!.stream.id,
    // });
    _webcamsfu!.publish(_webcamLocalStream!);

    _localParticipant!.webcamMid = _webcamLocalStream!.stream.id;
    _localParticipant!.webcamStream =
        await VideoRendererAdapter.create(_webcamLocalStream!.stream, true);
    notifyListeners();
  }

  Future<void> enableScreenShare() async {
    await _screensfu!.connect();
    await _screensfu!.join(_sid!, '$_uid:screen');
    var resolution = _prefs.getString('resolution') ?? 'hd';
    var codec = _prefs.getString('codec') ?? 'vp8';
    _screenLocalStream = await LocalStream.getDisplayMedia(
        constraints: Constraints.defaults
          ..simulcast = false
          ..resolution = resolution
          ..codec = codec);
    // _biz?.message(_uid, _sid!, {
    //   'type': 'ADD_WEBCAM_STREAM',
    //   'uid': _uid,
    //   'name': _name,
    //   'mid': _webcamLocalStream!.stream.id,
    // });
    _screensfu!.publish(_screenLocalStream!);
    _localParticipant!.screenMid = _screenLocalStream!.stream.id;
    _localParticipant!.webcamStream =
        await VideoRendererAdapter.create(_screenLocalStream!.stream, true);
    notifyListeners();
  }

  swapParticipant(uid) {
    final index = _participants.indexWhere((element) => element.uid == uid);
    if (index != -1) {
      final temp = _participants.elementAt(index);
      _participants[index] = _participants[0];
      _participants[0] = temp;
      notifyListeners();
    }
  }

  //Switch speaker/earpiece
  switchSpeaker() {
    if (_localParticipant!.webcamStream != null) {
      _speakerOn = !_speakerOn;
      MediaStreamTrack audioTrack =
          _localParticipant!.webcamStream!.stream.getAudioTracks()[0];
      audioTrack.enableSpeakerphone(_speakerOn);
      print(":::Switch to " + (_speakerOn ? "speaker" : "earpiece") + ":::");
    }
  }

  //Switch local camera
  switchCamera() {
    if (_localParticipant!.webcamStream != null &&
        _localParticipant!.webcamStream!.stream.getVideoTracks().isNotEmpty) {
      final track = _localParticipant!.webcamStream!.stream.getVideoTracks()[0];
      Helper.switchCamera(track);
    } else {
      print(":::Unable to switch the camera:::");
    }
  }

  //Open or close local video
  turnCamera() {
    if (_localParticipant!.webcamStream != null &&
        _localParticipant!.webcamStream!.stream.getVideoTracks().isNotEmpty) {
      var muted = !_cameraOff;
      _cameraOff = muted;
      _localParticipant!.webcamStream!.stream.getVideoTracks()[0].enabled =
          !muted;
      // notifyListeners();
    } else {
      print(":::Unable to operate the camera:::");
    }
  }

  //Open or close local audio
  turnMicrophone() {
    if (_localParticipant!.webcamStream != null &&
        _localParticipant!.webcamStream!.stream.getAudioTracks().isNotEmpty) {
      var muted = !_microphoneOff;
      _microphoneOff = muted;
      _localParticipant!.webcamStream!.stream.getAudioTracks()[0].enabled =
          !muted;
      print(":::The microphone is ${muted ? 'muted' : 'unmuted'}:::");
    } else {}
  }

  sendMessage(String text) {
    _biz?.message(_uid, _sid!, {
      'type': 'MESSAGE',
      'uid': _uid,
      'name': _name,
      'text': text,
    });

    var msg = ChatMessage(
      _uid,
      text,
      _name!,
      DateFormat.jms().format(DateTime.now()),
      isMe: true,
    );
    _messages.insert(0, msg);
    notifyListeners();
  }
}
