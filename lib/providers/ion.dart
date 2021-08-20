import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ion_conference/screens/chat_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Participant {
  Participant._internal(this.mid, this.stream, this.remote);
  String mid;
  bool remote;
  Object stream;
  double? bitrate;
  String get id => remote
      ? (stream as RemoteStream).stream.id
      : (stream as LocalStream).stream.id;

  MediaStream get mediaStream =>
      remote ? (stream as RemoteStream).stream : (stream as LocalStream).stream;

  String get title => (remote ? 'Remote' : 'Local') + ' ' + id.substring(0, 8);

  RTCVideoRenderer? renderer;
  RTCVideoViewObjectFit _objectFit =
      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;

  static Future<Participant> create(
      String mid, Object stream, bool local) async {
    var renderer = Participant._internal(mid, stream, local);
    await renderer.setupSrcObject();
    return renderer;
  }

  setupSrcObject() async {
    if (renderer == null) {
      renderer = RTCVideoRenderer();
      await renderer?.initialize();
    }
    renderer?.srcObject = mediaStream;
    if (!remote) {
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

  Future<void> dispose() async {
    renderer?.srcObject = null;
    await renderer?.dispose();
  }

  void preferLayer(Layer layer) {
    if (remote) {
      (stream as RemoteStream).preferLayer?.call(layer);
    }
  }

  void mute(String kind) {
    if (remote) {
      (stream as RemoteStream).mute?.call(kind);
    }
  }

  void unmute(String kind) {
    if (remote) {
      (stream as RemoteStream).unmute?.call(kind);
    }
  }

  void getStats(Client client, MediaStreamTrack track) async {
    dynamic bytesPrev;
    double? timestampPrev;
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      var results = await client.getSubStats(track);
      for (var report in results) {
        var now = report.timestamp;
        if ((report.type == 'ssrc' || report.type == 'inbound-rtp') &&
            report.values['mediaType'] == 'video') {
          var bytes = report.values['bytesReceived'];
          if (timestampPrev != null) {
            bitrate = (8 *
                    (WebRTC.platformIsWeb
                        ? bytes - bytesPrev
                        : (int.tryParse(bytes)! - int.tryParse(bytesPrev)!))) /
                (now - timestampPrev!);
          }
          bytesPrev = bytes;
          timestampPrev = now;
        }
      }
    });
  }
}

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
  // String get uid => _uid;
  // String? get name => _name;
  // IonAppBiz? get biz => _biz;
  // IonSDKSFU? get sfu => _sfu;
  bool get cameraOff => _cameraOff;
  bool get microphoneOff => _microphoneOff;
  bool get speakerOn => _speakerOn;
  List<ChatMessage> get messages => [..._messages];
  bool get isInit => !(_biz == null || _sfu == null || _sid == null);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences prefs() {
    return _prefs;
  }

  Participant? get localVideo {
    final index = _participants.indexWhere((value) => !value.remote);
    return index < 0 ? null : _participants[index];
  }

  List<Participant> get remoteVideos {
    return _participants.takeWhile((value) => value.remote).toList();
  }

  Future<void> connect(String name, String sid) async {
    _name = name;
    _sid = sid;

    _connector =
        IonBaseConnector('https://ion.wmtech.cc:5551', token: 'token123123123');
    _biz = IonAppBiz(_connector!);
    _sfu = IonSDKSFU(_connector!);

    _biz?.onJoin = (bool success, String reason) async {
      if (success) {
        try {
          await _sfu!.join(_sid!, _name!);
          var resolution = _prefs.getString('resolution') ?? 'hd';
          var codec = _prefs.getString('codec') ?? 'vp8';
          _localStream = await LocalStream.getUserMedia(
              constraints: Constraints.defaults
                ..simulcast = false
                ..resolution = resolution
                ..codec = codec);
          _sfu!.publish(_localStream!);
          _addParticipant(await Participant.create(
              _localStream!.stream.id, _localStream!, false));
          print('Stream added');
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
          break;
        case PeerState.UPDATE:
          state = 'upate';
          break;
        case PeerState.LEAVE:
          state = 'leave';
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
          }
          break;
        case StreamState.REMOVE:
          if (event.streams.isNotEmpty) {
            var mid = event.streams[0].id;
            print(":::stream-remove [$mid]:::");
            _removeParticipant(mid);
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
      //print('message: sender = ' + sender + ', text = ' + text);
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

    _sfu!.ontrack = (MediaStreamTrack track, RemoteStream stream) async {
      if (track.kind == 'video' &&
          _participants.indexWhere((element) => element.id == stream.id) < 0) {
        _addParticipant(await Participant.create(stream.id, stream, true));
      }
    };

    _sfu!.onspeaker = (Map<String, dynamic> list) {
      print('onspeaker: $list');
    };

    await _biz!.connect();
    await _sfu!.connect();
    _biz?.join(sid: _sid!, uid: _uid, info: <String, String>{'name': _name!});
  }

  Future<void> close() async {
    for (var item in _participants) {
      try {
        _sfu!.close();
        await item.dispose();
      } catch (error) {}
    }
    _participants.clear();
    _biz?.leave(_uid);
    _biz?.close();
    _biz = null;
  }

  _removeParticipant(String mid) {
    _participants.removeWhere((element) => element.mid == mid);
    notifyListeners();
  }

  _addParticipant(Participant participant) {
    _participants.add(participant);
    notifyListeners();
  }

  swapParticipant(adapter) {
    final index =
        _participants.indexWhere((element) => element.mid == adapter.mid);
    if (index != -1) {
      final temp = _participants.elementAt(index);
      _participants[index] = _participants[0];
      _participants[0] = temp;
    }
  }

  //Switch speaker/earpiece
  switchSpeaker() {
    if (localVideo != null) {
      _speakerOn = !_speakerOn;
      MediaStreamTrack audioTrack = localVideo!.mediaStream.getAudioTracks()[0];
      audioTrack.enableSpeakerphone(_speakerOn);
      print(":::Switch to " + (_speakerOn ? "speaker" : "earpiece") + ":::");
    }
  }

  //Switch local camera
  switchCamera() {
    if (localVideo != null &&
        localVideo!.mediaStream.getVideoTracks().isNotEmpty) {
      final track = localVideo?.mediaStream.getVideoTracks()[0];
      Helper.switchCamera(track!);
    } else {
      print(":::Unable to switch the camera:::");
    }
  }

  //Open or close local video
  turnCamera() {
    if (localVideo != null &&
        localVideo!.mediaStream.getVideoTracks().isNotEmpty) {
      var muted = !_cameraOff;
      _cameraOff = muted;
      localVideo?.mediaStream.getVideoTracks()[0].enabled = !muted;
      // notifyListeners();
    } else {
      print(":::Unable to operate the camera:::");
    }
  }

  //Open or close local audio
  turnMicrophone() {
    if (localVideo != null &&
        localVideo!.mediaStream.getAudioTracks().isNotEmpty) {
      var muted = !_microphoneOff;
      _microphoneOff = muted;
      localVideo?.mediaStream.getAudioTracks()[0].enabled = !muted;
      print(":::The microphone is ${muted ? 'muted' : 'unmuted'}:::");
      // setState(() {});
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
