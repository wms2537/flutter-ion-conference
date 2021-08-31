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
  String? mid;
  VideoRendererAdapter? webcamStream;
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
  IonSDKSFU? _sfu;
  String? _sid;
  String? _name;
  final String _uid = const Uuid().v4();
  final List<Participant> _participants = [];
  final List<ChatMessage> _messages = [];
  LocalStream? _localStream;
  bool _cameraOff = false;
  bool _microphoneOff = false;
  bool _speakerOn = true;

  String? get sid => _sid;
  bool get cameraOff => _cameraOff;
  bool get microphoneOff => _microphoneOff;
  bool get speakerOn => _speakerOn;
  List<ChatMessage> get messages => [..._messages];
  bool get isInit => !(_biz == null || _sfu == null || _sid == null);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    print(_uid);
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
    _sfu = IonSDKSFU(_connector!);

    _sfu!.ontrack = (MediaStreamTrack track, RemoteStream stream) async {
      if (track.kind == 'video') {
        print('track kind: ${track.label}');
        _participants
                .firstWhere((element) => element.mid == stream.id)
                .webcamStream =
            await VideoRendererAdapter.create(stream.stream, false);
        notifyListeners();
      }
    };

    _sfu!.onspeaker = (Map<String, dynamic> list) {
      print('onspeaker: $list');
    };
    _biz?.onJoin = (bool success, String reason) async {
      if (success) {
        try {
          await _sfu!.join(_sid!, _uid);
          var resolution = _prefs.getString('resolution') ?? 'hd';
          var codec = _prefs.getString('codec') ?? 'vp8';
          _localStream = await LocalStream.getUserMedia(
              constraints: Constraints.defaults
                ..simulcast = false
                ..resolution = resolution
                ..codec = codec);
          _sfu!.publish(_localStream!);
          final participant = new Participant(_uid, _name!, true);
          participant.webcamStream =
              await VideoRendererAdapter.create(_localStream!.stream, true);
          _participants.insert(0, participant);
          notifyListeners();
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
            print(":::stream-add [$mid]:::");
            _participants.firstWhere((element) => element.uid == event.uid)
              ..mid = mid;
          }
          break;
        case StreamState.REMOVE:
          if (event.streams.isNotEmpty) {
            var mid = event.streams[0].id;
            print(":::stream-remove [$mid]:::");
            _participants.firstWhere((element) => element.mid == mid)
              ..mid = null
              ..webcamStream = null;
          }
          break;
      }
    };

    _biz?.onMessage = (Message msg) async {
      if (msg.from == _uid) {
        return;
      }
      var info = msg.data;
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
    };

    await _biz!.connect();
    await _sfu!.connect();
    _biz?.join(sid: _sid!, uid: _uid, info: <String, String>{'name': _name!});
  }

  Future<void> close() async {
    await Future.wait(_participants.map((item) async {
      final stream = item.webcamStream?.stream;
      try {
        _sfu!.close();
        await stream?.dispose();
      } catch (error) {}
    }));
    _participants.clear();
    _biz?.leave(_uid);
    _biz?.close();
    _biz = null;
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
    if (_localStream != null) {
      _speakerOn = !_speakerOn;
      MediaStreamTrack audioTrack = _localStream!.stream.getAudioTracks()[0];
      audioTrack.enableSpeakerphone(_speakerOn);
      print(":::Switch to " + (_speakerOn ? "speaker" : "earpiece") + ":::");
    }
  }

  //Switch local camera
  switchCamera() {
    if (_localStream != null &&
        _localStream!.stream.getVideoTracks().isNotEmpty) {
      final track = _localStream?.stream.getVideoTracks()[0];
      Helper.switchCamera(track!);
    } else {
      print(":::Unable to switch the camera:::");
    }
  }

  //Open or close local video
  turnCamera() {
    if (_localStream != null &&
        _localStream!.stream.getVideoTracks().isNotEmpty) {
      var muted = !_cameraOff;
      _cameraOff = muted;
      _localStream?.stream.getVideoTracks()[0].enabled = !muted;
      // notifyListeners();
    } else {
      print(":::Unable to operate the camera:::");
    }
  }

  //Open or close local audio
  turnMicrophone() {
    if (_localStream != null &&
        _localStream!.stream.getAudioTracks().isNotEmpty) {
      var muted = !_microphoneOff;
      _microphoneOff = muted;
      _localStream?.stream.getAudioTracks()[0].enabled = !muted;
      print(":::The microphone is ${muted ? 'muted' : 'unmuted'}:::");
    } else {}
  }

  sendMessage(String text) {
    _biz?.message(_uid, _sid!, {
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
