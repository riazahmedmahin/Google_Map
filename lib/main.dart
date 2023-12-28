import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Location location = Location();
  late LatLng myPosition;
  late StreamSubscription<LocationData> locationSubscription;

  List<LatLng> polylineCoordinates = [];
  late GoogleMapController _controller;

  @override
  void initState() {
    super.initState();
    listenToLocation();
  }

  void updateLocation(double latitude, double longitude) {
    setState(() {
      myPosition = LatLng(latitude, longitude);
      polylineCoordinates.add(myPosition); // Add current position to polyline
    });
  }

  void listenToLocation() {
    locationSubscription = location.onLocationChanged.listen((LocationData locationData) {
      myPosition = LatLng(locationData.latitude!, locationData.longitude!);
      if (mounted) {
        setState(() {});
        updateLocation(myPosition.latitude, myPosition.longitude);
      }
    });

    // Fetch the user's current location every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
      LocationData currentLocation = await location.getLocation();
      updateLocation(currentLocation.latitude!, currentLocation.longitude!);
      _updatePolyline(); // Update polyline on the map
    });
  }

  void _updatePolyline() {
    if (polylineCoordinates.isNotEmpty && _controller != null) {
      _controller.animateCamera(
        CameraUpdate.newLatLng(polylineCoordinates.last),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(
        initialLatitude: myPosition.latitude,
        initialLongitude: myPosition.longitude,
        polylineCoordinates: polylineCoordinates,
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final List<LatLng> polylineCoordinates;

  const MapScreen({
    Key? key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.polylineCoordinates,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Location Tracker'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.initialLatitude, widget.initialLongitude),
          zoom: 15,
        ),
        markers: Set<Marker>.of([
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(widget.initialLatitude, widget.initialLongitude),
            infoWindow: InfoWindow(
              title: 'My Current Location',
              snippet:
              '${widget.initialLatitude}, ${widget.initialLongitude}',
            ),
            onTap: () {
              // Handle marker tap if needed
            },
          ),
        ]),
        polylines: Set<Polyline>.of([
          Polyline(
            polylineId: PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: widget.polylineCoordinates,
          ),
        ]),
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      ),
    );
  }
}
