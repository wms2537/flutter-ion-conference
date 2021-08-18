import 'package:flutter/material.dart';
import 'package:flutter_ion_conference/providers/ion.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences prefs;
  late String _resolution;
  late String _bandwidth;
  late String _codec;
  late String _displayName;

  @override
  void initState() {
    prefs = Provider.of<IonController>(context, listen: false).prefs();
    _resolution = prefs.getString('resolution') ?? 'vga';
    _bandwidth = prefs.getString('bandwidth') ?? '512';
    _displayName = prefs.getString('display_name') ?? 'Guest';
    _codec = prefs.getString('codec') ?? 'vp8';
    super.initState();
  }

  _save() {
    prefs.setString('resolution', _resolution);
    prefs.setString('bandwidth', _bandwidth);
    prefs.setString('display_name', _displayName);
    prefs.setString('codec', _codec);
    Navigator.of(context).pop();
  }

  final _codecItems = [
    {
      'name': 'H264',
      'value': 'h264',
    },
    {
      'name': 'VP8',
      'value': 'vp8',
    },
    {
      'name': 'VP9',
      'value': 'VP9',
    },
  ];

  final _bandwidthItems = [
    {
      'name': '256kbps',
      'value': '256',
    },
    {
      'name': '512kbps',
      'value': '512',
    },
    {
      'name': '768kbps',
      'value': '768',
    },
    {
      'name': '1Mbps',
      'value': '1024',
    },
  ];

  final _resolutionItems = [
    {
      'name': 'QVGA',
      'value': 'qvga',
    },
    {
      'name': 'VGA',
      'value': 'vga',
    },
    {
      'name': 'HD',
      'value': 'hd',
    },
  ];

  Widget _buildRowFixTitleRadio(List<Map<String, dynamic>> items, var value,
      ValueChanged<String> onValueChanged) {
    return SizedBox(
        width: 320,
        height: 100,
        child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            childAspectRatio: 2.8,
            children: items
                .map((item) => ConstrainedBox(
                      constraints: const BoxConstraints.tightFor(
                          width: 120.0, height: 36.0),
                      child: RadioListTile<String>(
                        value: item['value'],
                        title: Text(item['name']),
                        groupValue: value,
                        onChanged: (value) => onValueChanged(value!),
                      ),
                    ))
                .toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: Align(
            alignment: const Alignment(0, 0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('DisplayName:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(48.0, 0.0, 48.0, 0),
                          child: TextField(
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10.0),
                              border: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.black12)),
                              hintText: _displayName,
                            ),
                            onChanged: (value) {
                              _displayName = value;
                            },
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('Codec:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0),
                          child: _buildRowFixTitleRadio(_codecItems, _codec,
                              (value) {
                            _codec = value;
                          }),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('Resolution:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0),
                          child: _buildRowFixTitleRadio(
                              _resolutionItems, _resolution, (value) {
                            _resolution = value;
                          }),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(46.0, 18.0, 48.0, 0),
                          child: Align(
                            child: Text('Bandwidth:'),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0),
                          child: _buildRowFixTitleRadio(
                              _bandwidthItems, _bandwidth, (value) {
                            _bandwidth = value;
                          }),
                        ),
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(0.0, 18.0, 0.0, 0.0),
                        child: SizedBox(
                            height: 48.0,
                            width: 160.0,
                            child: InkWell(
                              child: Container(
                                width: 220.0,
                                height: 48.0,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xffe13b3f),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () => _save(),
                            )))
                  ]),
            )));
  }
}
