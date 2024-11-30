import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Arete Office Lat or Long
  final double targetLatitude = 28.5640244;
  final double targetLongitude = 77.2197382;

  // Eiffel Tower Office Lat or Long
  // final double targetLatitude = 48.8583736;
  // final double targetLongitude = 2.2919064;
  final double allowedDistance = 100;
  String message = "Checking your location...";

  String dropdownvalue = 'Office';

  var items = [
    'Office',
    'Client',
    'Work From Home',
  ];

  final ImagePicker _picker = ImagePicker();

  Future<void> openCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // Use the front camera
    );

    if (photo != null) {
      print('Image captured: ${photo.path}');
      // Do something with the captured image (e.g., upload or display it)
    }
  }

  String empName = "Loading...";
  String empProfileImage = ""; // To store the profile image URL

  String getCurrentTime() {
    return DateFormat('hh:mm a').format(DateTime.now());
  }

  String getCurrentDate() {
    return DateFormat('MMMM dd, yyyy - EEEE').format(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _loadEmpName();
    _loadEmployeeProfile();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        message = "Location permission denied. Please enable it in settings.";
      });
    } else {
      setState(() {
        message = "Ready to check location.";
      });
    }
  }

  Future<void> _checkDistance() async {
    try {
      // Get the current position of the user
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate the distance between the target and the user's location
      double distanceInMeters = Geolocator.distanceBetween(
        targetLatitude,
        targetLongitude,
        position.latitude,
        position.longitude,
      );

      // Check if the distance is within the allowed range
      if (distanceInMeters <= allowedDistance) {
        setState(() {
          message =
              "Success! You are within $allowedDistance meters of the target location.";
        });
        print("User is within range!");
        // Proceed to open camera
        openCamera();
      } else {
        setState(() {
          message =
              "You are too far from the target location. Distance: ${distanceInMeters.toStringAsFixed(2)} meters.";
        });
        print("User is out of the range!");
        // Show error message in Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You are too far from the target location.")),
        );
      }
    } catch (e) {
      setState(() {
        message = "Error getting location: $e";
      });
    }
  }

  // Retrieve the employee name from SharedPreferences
  Future<void> _loadEmpName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      empName = prefs.getString('emp_name') ?? "Guest";
    });
  }

  // Fetch employee profile data from the API
  Future<void> _loadEmployeeProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empId =
        prefs.getString('emp_id'); // Fetch Emp_id from SharedPreferences

    if (empId != null) {
      try {
        final response = await http.post(
          Uri.parse(
              'https://acpldemo.co.in/attendance/acpl/employee_profile_api.php'),
          body: {
            'api_key': '123#',
            'Emp_id': empId,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            setState(() {
              empName = data[0]['emp_name'] ?? "Guest";
              empProfileImage =
                  data[0]['emp_profile'] ?? ''; // Set the profile image URL
            });
          }
        } else {
          // Handle API error
          print("Failed to load employee profile.");
        }
      } catch (e) {
        // Handle network or API call error
        print("Error: $e");
      }
    }
  }

  // Logout functionality
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data
    print("Logout pressed, navigating to login...");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logout button and dynamic welcome text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Arete HRMS',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: _logout, // Call logout function
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Header with profile and dynamic employee name
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: empProfileImage.isNotEmpty
                        ? NetworkImage(empProfileImage)
                        : const NetworkImage(
                            'https://acpldemo.co.in/attendance/acpl/assets/img/img-sample.png'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome, $empName', // Display the dynamic name
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mark Your Attendance!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Click In Button
              Center(
                child: Column(
                  children: [
                    Text(
                      getCurrentTime(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      getCurrentDate(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        // print("Punch In Click");

                        // Open the modal bottom sheet when the button is clicked
                        showModalBottomSheet<void>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          elevation: 5, // Set elevation for the bottom sheet
                          builder: (BuildContext context) {
                            // Local variable to track dropdown value
                            String localDropdownValue = dropdownvalue;

                            return StatefulBuilder(
                              builder: (BuildContext context,
                                  StateSetter setModalState) {
                                return SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start, // Align content to the start
                                      children: <Widget>[
                                        // Header Title
                                        const Center(
                                          child: Text(
                                            'Punch In Details',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        const Divider(
                                          height: 5,
                                          thickness: 2,
                                          indent: 20,
                                          endIndent: 0,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(height: 10),

                                        // Dropdown Label
                                        const Text(
                                          'Select Work Type',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Dropdown for selecting type of work
                                        SizedBox(
                                          width: double
                                              .infinity, // Make dropdown full width
                                          child: DropdownButton<String>(
                                            isExpanded:
                                                true, // Ensure dropdown is expanded
                                            value: localDropdownValue,
                                            icon: const Icon(
                                                Icons.keyboard_arrow_down),
                                            items: items.map((String item) {
                                              return DropdownMenuItem<String>(
                                                value: item,
                                                child: Text(item),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setModalState(() {
                                                localDropdownValue = newValue!;
                                              });
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Punch In Button
                                        Center(
                                          child: ElevatedButton(
                                            child: const Text('Punch In'),
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      Colors.blue),
                                              minimumSize:
                                                  MaterialStateProperty.all(
                                                      const Size(200, 40)),
                                            ),
                                            onPressed: () {
                                              // Update the parent widget's dropdown value
                                              setState(() {
                                                dropdownvalue =
                                                    localDropdownValue;
                                              });

                                              // Close the modal
                                              Navigator.pop(context);

                                              // Check if the selected value is not 'Work From Home'
                                              if (dropdownvalue !=
                                                  'Work From Home') {
                                                // Open the camera if not 'Work From Home'
                                                openCamera();
                                              } else {
                                                // You can optionally show a message here if needed
                                                print(
                                                    'Camera is not opened for Work From Home');
                                              }
                                              _checkDistance();
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        // Close Button
                                        Center(
                                          child: ElevatedButton(
                                            child: const Text('Close'),
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                      const Color.fromARGB(
                                                          255, 179, 183, 187)),
                                              minimumSize:
                                                  MaterialStateProperty.all(
                                                      const Size(200, 40)),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade300,
                              Colors.purple.shade300,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 8), // Optional space between the icon and text
                    const Text(
                      'Click In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Attendance Stats
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Current Month',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '08',
                      'Early Leave',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '03',
                      'Absents',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '05',
                      'Late Entry',
                      Colors.pink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '05',
                      'Work From Home',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
