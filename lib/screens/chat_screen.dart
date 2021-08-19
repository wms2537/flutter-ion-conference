import 'package:flutter/material.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:flutter_ion_conference/providers/ion.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage extends StatelessWidget {
  final bool _isMe;
  final String _uid;
  final String _text;
  final String _name;
  final String _createAt;

  const ChatMessage(this._uid, this._text, this._name, this._createAt,
      {isMe = false, Key? key})
      : _isMe = isMe,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_isMe) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Container(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_name, style: Theme.of(context).textTheme.bodyText1),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(_text),
                )
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 16.0),
              child: const CircleAvatar(
                child: Text('Me'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: Text(_name),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_createAt, style: Theme.of(context).textTheme.bodyText1),
              Container(
                margin: const EdgeInsets.only(top: 5.0),
                child: Text(_text),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController textEditingController = TextEditingController();
  FocusNode textFocusNode = FocusNode();
  // @override
  // void initState() {
  //   prefs = Provider.of<IonController>(context, listen: false).prefs();
  //   final biz = Provider.of<IonController>(context, listen: false).biz;
  //   _uid = Provider.of<IonController>(context, listen: false).uid;
  //   _name = Provider.of<IonController>(context, listen: false).name;
  //   _sid = Provider.of<IonController>(context, listen: false).sid;
  //   for (int i = 0; i < _historyMessage.length; i++) {
  //     var hisMsg = _historyMessage[i];
  //     ChatMessage message = ChatMessage(
  //       hisMsg['uid'],
  //       hisMsg['text'],
  //       hisMsg['name'],
  //       DateFormat.jms().format(DateTime.now()),
  //       isMe: hisMsg['uid'] == _uid ? true : false,
  //     );
  //     _messages.insert(0, message);
  //   }
  //   biz?.onMessage = _messageProcess;
  //   super.initState();
  // }

  // void _messageProcess(Message msg) async {
  //   if (msg.from == _uid) {
  //     return;
  //   }
  //   var info = msg.data;
  //   var sender = info['name'];
  //   var text = info['text'];
  //   var uid = info['uid'] as String;
  //   //print('message: sender = ' + sender + ', text = ' + text);
  //   ChatMessage message = ChatMessage(
  //     uid,
  //     text,
  //     sender,
  //     DateFormat.jms().format(DateTime.now()),
  //     isMe: uid == _uid,
  //   );

  //   setState(() {
  //     _messages.insert(0, message);
  //   });
  // }

  void _handleSubmit(String text) {
    textEditingController.clear();

    if (text.isEmpty || text == '') {
      return;
    }

    // var info = {
    //   'uid': _uid,
    //   'name': _name,
    //   'text': text,
    // };
    Provider.of<IonController>(context, listen: false).sendMessage(text);
    // var msg = ChatMessage(
    //   _uid,
    //   text,
    //   _displayName,
    //   DateFormat.jms().format(DateTime.now()),
    //   isMe: true,
    // );
    // setState(() {
    //   _messages.insert(0, msg);
    // });
  }

  Widget textComposerWidget() {
    return IconTheme(
      data: const IconThemeData(color: Colors.blue),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                decoration: const InputDecoration.collapsed(
                    hintText: 'Please input message'),
                controller: textEditingController,
                onSubmitted: _handleSubmit,
                focusNode: textFocusNode,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmit(textEditingController.text),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Consumer<IonController>(builder: (context, controller, _) {
            return Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) => controller.messages[index],
                itemCount: controller.messages.length,
              ),
            );
          }),
          const Divider(
            height: 1.0,
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: textComposerWidget(),
          )
        ],
      ),
    );
  }
}
