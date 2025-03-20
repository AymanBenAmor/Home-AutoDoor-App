import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portail coulissant Slim Ben Amor',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String _firebaseValue = "Aucune donnée"; // Current Firebase value
  String _alarmValue = "No alarm"; // Store alarm state

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Appuyez et maintenez pour parler!";
  double _confidence = 1.0;
  double _buttonRadius = 40; // Default button radius

  String _displayed_text = "Appuyez et maintenez pour parler!";
  String _alarm_indicator_text = "";


  Color alarmIconColor = Colors.white;
  Timer? _alarmTimer;





  // Method to change the value of 'state' in Firebase
  void _updateStateInFirebase(String newState) {
    _dbRef.child('state').set({
      'state': newState,
    });
  }


  // Method to change the value of 'alarm' in Firebase
  Future<void> _updateAlarmInFirebase(String newState) async {
    if (await _checkInternetConnection()){
    _dbRef.child('alarm').set({
    'alarm': newState,
    });
    }else{
      _showAlert("Pas de connexion internet. Vous devez connecter a un WiFi ou utiliser les données mobiles.");
    }

  }


  BuildContext? _dialogContext; // Track the alert dialog context


  void _listenToAlarm() {
    _dbRef.child('alarm').onValue.listen((event) {
      if (event.snapshot.value != null) {
        String alarmState = event.snapshot.value.toString();



        // Extract the alarm value correctly
        if (alarmState.length >= 14) {
          alarmState = alarmState.substring(8, 14);
        }


        setState(() {
          _alarmValue = alarmState;
        });


        // Show or close alert based on alarm state
        if (_alarmValue == "opened") {
          //_closeBlockingAlert();
          //_showBlockingAlert();
          setState(() {
            alarmIconColor = Color(0xFF670902);
            _alarm_indicator_text = "Alarme est ouverte!";
          });

        } else if (_alarmValue == "closed") {
          //_closeBlockingAlert();
          setState(() {
            alarmIconColor = Colors.white;
            _alarm_indicator_text = "";
          });

        }

        // Handle "open request" case with a timer
        if (_alarmValue == "OpnReq") {

          _alarmTimer?.cancel(); // Cancel any existing timer
          _alarmTimer = Timer(Duration(seconds: 4), () {
            if (_alarmValue == "OpnReq") {
              _updateAlarmInFirebase("closed");
              _showSnackbar("ECHEC : Probléme de connexion ou d'alimentation");
            }
          });
        }


        if (_alarmValue == "ClsReq") {

          _alarmTimer?.cancel(); // Cancel any existing timer
          _alarmTimer = Timer(Duration(seconds: 4), () {
            if (_alarmValue == "ClsReq") {
              _updateAlarmInFirebase("opened");
              _showSnackbar("ECHEC : Probléme de connexion ou d'alimentation.");
            }
          });
        }


      }
    });
  }

  void _showBlockingAlert() {
    showDialog(
      context: context,

      barrierColor: Colors.black.withOpacity(0.9), // Darken background
      builder: (BuildContext dialogContext) {
        _dialogContext = dialogContext; // Store the dialog context

        return AlertDialog(
          backgroundColor: Color(0xFF670902), // Red background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Rounded corners
            side: BorderSide(color: Colors.white, width: 2), // White border
          ),
          title: Text(
            "⚠️ Alarme ouverte!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "Click OK pour la désactiver",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  _updateAlarmInFirebase("ClsReq");
                  _closeBlockingAlert(); // Close alert
                },
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontSize: 40),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  void _closeBlockingAlert() {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop(); // Close dialog
      _dialogContext = null; // Reset context
    }
  }






  // Function to check internet connection
  Future<bool> _checkInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    return (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi);
  }

  // Show alert dialog
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Information"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Show snackbar message
  void _showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2), // Display the Snackbar for 3 seconds
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16), // Optional: set margin to avoid edges
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();

    _listenToAlarm(); // Start listening for alarm changes

    // Initialize speech recognition
    _speech = stt.SpeechToText();

    // Read data in real-time from Firebase
    _dbRef
        .child('state')
        .onValue
        .listen((event) {
      setState(() {
        _firebaseValue = event.snapshot.value != null
            ? event.snapshot.value.toString()
            : "Aucune donnée";
      });
    });
  }

  // Handler for image tap
  Future<void> _handleImageTap(String action) async {
    if (await _checkInternetConnection()) {
      // Update the state in Firebase
      _updateStateInFirebase(action);
      _showSnackbar("$action executed successfully!");

      // Wait for 5 seconds before checking the state again
      await Future.delayed(Duration(seconds: 5));

      _updateStateInFirebase("null");
    } else {
      _showAlert(
          "Pas de connexion internet. Vous devez connecter a un WiFi ou utiliser les données mobiles.");
    }
  }

  Future<void> _startListening() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('onStatus: $status'),
        onError: (error) => print('onError: $error'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _buttonRadius = 60; // Grow the button radius on press
        });

        _speech.listen(
          onResult: (val) =>
              setState(() {
                _text = val.recognizedWords;
                if (val.hasConfidenceRating && val.confidence > 0) {
                  _confidence = val.confidence;
                }
              }),
          localeId: 'ar_AR', // Set the locale to Arabic
        );
      } else {
        print("Speech recognition not available.");
      }
    } catch (e) {
      print("Speech recognition error: $e");
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _buttonRadius = 40; // Shrink the button radius on release
    });


    // Delay to reset _text after 3 seconds when stop listening
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _text = "Appuyez et maintenez pour parler!";
          _displayed_text = "Appuyez et maintenez pour parler!"; // Reset text
        });
      }
    });
  }

  String checked_text() {
    if (_text.contains('صغير')) {
      _handleImageTap('open walker');
      _text = "porte pieton ouverte";
      _displayed_text = "تم فتح الباب الصغير";
    } else if (_text.contains('كبير')) {
      _handleImageTap('open all');
      _text = "porte coullisant ouverte";
      _displayed_text = "تم فتح الباب الكبير";
    }

    return _displayed_text;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Home",
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            Text(
              _alarm_indicator_text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: alarmIconColor,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        //centerTitle: true, // Centers the title
        toolbarHeight: 100, // Increases the AppBar height (default is 56)
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active, color: alarmIconColor , size: 50,),
            onPressed: () {
              // Handle alarm button tap (you can show an alert, navigate, etc.)

              if(_alarmValue == "closed"){
                _updateAlarmInFirebase("OpnReq");
              }

              if(_alarmValue == "opened"){
                _updateAlarmInFirebase("ClsReq");
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background color (Grey)
          Container(
            color: Colors.blueGrey, // Set the background color to grey
          ),
          // Foreground content (Scrollable)
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
                  // Image button for "Open All"
                  GestureDetector(
                    onTap: () {
                      _handleImageTap('open all');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white, // Set the border color
                          width: 3.0, // Set the border width
                        ),
                        borderRadius: BorderRadius.circular(0.0), // Optional: Add rounded corners
                      ),
                      child: Image.asset(
                        'assets/images/kbir.jpg',
                        width: 230,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Image button for "Open Walker"
                  GestureDetector(
                    onTap: () {
                      _handleImageTap('open walker');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white, // Set the border color
                          width: 3.0, // Set the border width
                        ),
                        borderRadius: BorderRadius.circular(0.0), // Optional: Add rounded corners
                      ),
                      child: Image.asset(
                        'assets/images/sghir.jpg',
                        width: 180,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  GestureDetector(
                    onLongPress: _startListening,
                    // Start listening when the button is pressed
                    onLongPressUp: _stopListening,
                    // Stop listening when the button is released
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      // Smooth animation duration
                      curve: Curves.easeInOut,
                      width: _buttonRadius * 2,
                      height: _buttonRadius * 2,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.blueGrey,
                        size: 30,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    checked_text(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
