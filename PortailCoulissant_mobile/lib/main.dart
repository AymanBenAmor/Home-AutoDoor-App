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

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Appuyez et maintenez pour parler!";
  double _confidence = 1.0;
  double _buttonRadius = 40; // Default button radius

  // Method to change the value of 'state' in Firebase
  void _updateStateInFirebase(String newState) {
    _dbRef.child('state').set({
      'state': newState,
    });
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
      duration: Duration(seconds: 3), // Display the Snackbar for 3 seconds
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16), // Optional: set margin to avoid edges
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();

    // Initialize speech recognition
    _speech = stt.SpeechToText();

    // Read data in real-time from Firebase
    _dbRef.child('state').onValue.listen((event) {
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
          "No internet connection. Please connect to the internet or try again later.");
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
          onResult: (val) => setState(() {
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
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _text = "Appuyez et maintenez pour parler!"; // Reset text
        });
      }
    });
  }

  String checked_text(String text) {
    if (text.contains('صغير')) {
      _handleImageTap('open walker');
      return "افتح الباب الصغير";
    } else if (text.contains('كبير')) {
      _handleImageTap('open all');
      return "افتح الباب الكبير";
    } else {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  SizedBox(height: 50),
                  // Display current value read from Firebase
                  Text(
                    'Welcome Home',
                    style: TextStyle(
                      fontSize: 45,
                      color: Colors.white,
                    ),
                  ),

                  // Image button for "Open All"
                  GestureDetector(
                    onTap: () {
                      _handleImageTap('open all');
                    },
                    child: Image.asset(
                      'assets/images/portail.jpg', // Your icon for "Open All"
                      width: 250,
                      height: 235,
                    ),
                  ),

                  // Image button for "Open Walker"
                  GestureDetector(
                    onTap: () {
                      _handleImageTap('open walker');
                    },
                    child: Image.asset(
                      'assets/images/portail.jpg',
                      width: 250,
                      height: 250,
                    ),
                  ),

                  SizedBox(height: 25,),

                  GestureDetector(
                    onLongPress: _startListening, // Start listening when the button is pressed
                    onLongPressUp: _stopListening, // Stop listening when the button is released
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300), // Smooth animation duration
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
                    checked_text(_text),
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
