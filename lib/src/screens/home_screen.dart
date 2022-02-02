import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todo/blocs/application_bloc.dart';
import 'package:todo/models/place.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription? locationSubscription;

  @override
  void initState() {
    final applicationBloc =
        Provider.of<ApplicationBloc>(context, listen: false);

    locationSubscription =
        applicationBloc.selectedLocation.stream.listen((place) {
      _goToPlace(place);
    });
    super.initState();
  }

  @override
  void dispose() {
    final applicatoinBloc =
        Provider.of<ApplicationBloc>(context, listen: false);
    applicatoinBloc.dispose();
    locationSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationBloc = Provider.of<ApplicationBloc>(context);

    return Scaffold(
        body: (applicationBloc.currentLocation == null)
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "search location",
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => applicationBloc.searchPlaces(value),
                    ),
                  ),
                  Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                              target: LatLng(
                                  applicationBloc.currentLocation!.latitude,
                                  applicationBloc.currentLocation!.longitude),
                              zoom: 14),
                          mapType: MapType.normal,
                          myLocationEnabled: true,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController.complete(controller);
                          },
                        ),
                      ),
                      if (applicationBloc.searchResults.isNotEmpty)
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.6),
                              backgroundBlendMode: BlendMode.darken),
                        ),
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                            itemCount: applicationBloc.searchResults.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                    applicationBloc
                                        .searchResults[index].description,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                onTap: () {
                                  applicationBloc.setSelectedLocation(
                                      applicationBloc
                                          .searchResults[index].placeId);
                                },
                              );
                            }),
                      )
                    ],
                  )
                ],
              ));
  }

  Future<void> _goToPlace(Place place) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target:
            LatLng(place.geometry.location.lat, place.geometry.location.lng),
        zoom: 14)));
  }
}
