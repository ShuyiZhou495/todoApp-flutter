import 'package:http/http.dart' as http;
import 'package:todo/models/place.dart';
import 'dart:convert' as convert;

import 'package:todo/models/place_search.dart';

class PlacesService {
  final key = "AIzaSyCrBW807howWe2902I04LzW-eF7lfUvfZY";

  Future<List<PlaceSearch>> getAutocomplete(String search) async {
    var url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${search}&language=ja&types=establishment&key=${key}";
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var jsonResults = json['predictions'] as List;
    return jsonResults.map((place) => PlaceSearch.fromJson(place)).toList();
  }

  Future<Place> getPlace(String placeId) async {
    var url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&key=${key}";
    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var jsonResult = json['result'] as Map<String, dynamic>;
    return Place.fromJson(jsonResult);
  }
}
