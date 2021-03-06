import 'package:flutter/material.dart';
import 'package:flutter_ion_conference/providers/ion.dart';
import 'package:flutter_ion_conference/screens/meeting_screen.dart';
import 'package:flutter_ion_conference/screens/settings_page.dart';
import 'package:flutter_ion_conference/utils/validators.dart';
import 'package:flutter_ion_conference/widgets/error_dialog.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _sid;
  bool _isLoading = false;

  _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<IonController>(context, listen: false)
          .connect(_name!, _sid!);
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pushNamed(MeetingScreen.routeName);

      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showErrorDialog(e.toString(), context);
    }
  }

  Widget buildJoinView(context) {
    return Align(
      alignment: const Alignment(0, 0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 260.0,
              child: TextFormField(
                  initialValue: 'Guest',
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  validator: Validator.validateAlphanumeric,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black12)),
                      hintText: 'Enter Name.'),
                  onSaved: (value) {
                    _name = value;
                  }),
            ),
            SizedBox(
              width: 260.0,
              child: TextFormField(
                initialValue: 'test room',
                keyboardType: TextInputType.text,
                textAlign: TextAlign.center,
                validator: Validator.validateRequired,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(10.0),
                  border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12)),
                  hintText: 'Enter RoomID.',
                ),
                onSaved: (value) {
                  _sid = value;
                },
              ),
            ),
            const SizedBox(width: 260.0, height: 48.0),
            _isLoading
                ? const CircularProgressIndicator()
                : InkWell(
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
                          'Join',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    onTap: _submit),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Scaffold(
          appBar: orientation == Orientation.portrait
              ? AppBar(
                  title: const Text('PION'),
                )
              : null,
          body: Stack(children: <Widget>[
            Center(child: buildJoinView(context)),
            Positioned(
              bottom: 6.0,
              right: 6.0,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(SettingsScreen.routeName);
                },
                child: const Text(
                  "Settings",
                  style: TextStyle(fontSize: 16.0, color: Colors.black54),
                ),
              ),
            ),
          ]));
    });
  }
}
