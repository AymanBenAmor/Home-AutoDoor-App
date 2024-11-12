import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(); // Firebase Database reference
  String _firebaseValue = "Aucune donnée"; // Current Firebase value

  // Method to change the value of 'state' in Firebase
  void _updateStateInFirebase(String newState) {
    _dbRef.child('state').set({
      'state': newState,
    });
  }

  // Function to check internet connection
  Future<bool> _checkInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    return (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi);
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
      duration: Duration(seconds: 3), // Display the Snackbar for 2 seconds
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16), // Optional: set margin to avoid edges
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();

    // Read data in real time from Firebase
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
      _showAlert("No internet connection. Please connect to the internet or try again later.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg2.jpg'), // Your background image
                fit: BoxFit.cover, // Cover the whole screen
              ),
            ),
          ),
          // Foreground content (Scrollable)
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 220),
                  // Display current value read from Firebase


                  // Image button for "Open All"
                  GestureDetector(
                    onTap: () {
                      _handleImageTap('open all');
                    },
                    child: Image.asset(
                      'assets/images/portail.jpg', // Your icon for "Open All"
                      width: 250, // Set appropriate width and height for the image
                      height: 250,
                    ),
                  ),

                  // Image button for "Open Walker"
                  GestureDetector(
                    onTap: () {
                      _handleImageTap('open walker');
                    },
                    child: Image.asset(
                      'assets/images/portail.jpg', // Your icon for "Open Walker"
                      width: 250, // Set appropriate width and height for the image
                      height: 250,
                    ),
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
