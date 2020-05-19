import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LocationSelectPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    List<LatLng> arguments = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Directions'),
      ),
      body: arguments == null ||
              arguments.length < 2 ||
              arguments[0] == null ||
              arguments[1] == null
          ? Center(
              child: Text('No arguments supplied'),
            )
          : buildGoogleMap(
              arguments[0],
              arguments[1],
            ),
    );
  }

  Widget buildGoogleMap(LatLng origin, LatLng destination) {
    final polylinePoints = PolylinePoints();
    return FutureBuilder<PolylineResult>(
      future: polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyCQRDdvSih-9QqcNcaJOUc5pKhSYoY4mKc',
        PointLatLng(origin.latitude, origin.longitude),
        PointLatLng(destination.latitude, destination.longitude),
      ),
      builder: (BuildContext context, AsyncSnapshot<PolylineResult> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final points = snapshot.data.points;
            if (points.length == 0) {
              return Center(child: Text('No routes found'));
            }
            return GoogleMap(
              initialCameraPosition: CameraPosition(target: origin, zoom: 10),
              polylines: Set()
                ..add(
                  Polyline(
                    polylineId: PolylineId('id'),
                    color: Colors.blue,
                    width: 2,
                    visible: true,
                    points: toLatLan(points),
                  ),
                ),
            );
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
          default:
            return Center(child: Text('Finding routes'));
        }
      },
    );
  }

  List<LatLng> toLatLan(List<PointLatLng> points) {
    return List<LatLng>.generate(
      points.length,
      (index) {
        return LatLng(points[index].latitude, points[index].longitude);
      },
    );
  }
}

class LocationSelectPage extends StatefulWidget {
  @override
  _LocationSelectPageState createState() => _LocationSelectPageState();
}

class _LocationSelectPageState extends State<LocationSelectPage> {
  LatLng origin;
  LatLng destination;
  bool selectOrigin = false;
  final CameraPosition initPos = CameraPosition(
    target: LatLng(5.941407, 80.549028),
    zoom: 10.0,
  );
  GoogleMapController controller;
  Set<Marker> markers = Set();

  @override
  Widget build(BuildContext context) {
    initMarkers();
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                selectOrigin = true;
              });
            },
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.all(16),
              color: selectOrigin ? Colors.lightBlueAccent : Colors.white,
              child: Text(
                'Origin: ' +
                    (origin != null
                        ? '${origin.latitude}, ${origin.longitude}'
                        : 'Please select origin'),
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                selectOrigin = false;
              });
            },
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.all(16),
              color: !selectOrigin ? Colors.lightBlueAccent : Colors.white,
              child: Text(
                'Destination: ' +
                    (destination != null
                        ? '${destination.latitude}, ${destination.longitude}'
                        : 'Please select destination'),
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              zoomControlsEnabled: false,
              initialCameraPosition: initPos,
              onMapCreated: (controller) {
                this.controller = controller;
                getCurrentLocation();
              },
              onTap: (argument) {
                setState(
                  () {
                    if (selectOrigin) {
                      origin = argument;
                    } else {
                      destination = argument;
                    }
                  },
                );
              },
              markers: markers,
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) {
                  return HomePage();
                },
                settings: RouteSettings(arguments: [origin, destination])),
          );
        },
        child: Icon(Icons.directions),
      ),
    );
  }

  Marker getMarker(LatLng latLng) {
    return Marker(
      markerId: MarkerId('${latLng.latitude}${latLng.longitude}'),
      position: latLng,
    );
  }

  getCurrentLocation() {
    Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then(
          (value) => {
            if (value != null)
              {
                setState(
                  () {
                    origin = LatLng(value.latitude, value.longitude);
                    controller.animateCamera(CameraUpdate.newLatLng(origin));
                  },
                )
              }
          },
        );
  }

  void initMarkers() {
    markers = Set();
    if (origin != null) {
      markers.add(getMarker(origin));
    }
    if (destination != null) {
      markers.add(getMarker(destination));
    }
  }
}
