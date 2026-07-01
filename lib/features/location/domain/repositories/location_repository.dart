import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/location/domain/models/zone_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/domain/repositories/location_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/helper/store_registration_debug.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class LocationRepository implements LocationRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  LocationRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    Response response = await apiClient.getData('${AppConstants.geocodeUri}?lat=${latLng.latitude}&lng=${latLng.longitude}', handleError: false);
    String address = 'Unknown Location Found';
    if(response.statusCode == 200 && response.body['status'] == 'OK') {
      address = response.body['results'][0]['formatted_address'].toString();
    }else {
      showCustomSnackBar(response.body['error_message'] ?? response.bodyString);
    }
    return address;
  }

  static const String _fallbackLat = '9.0765';
  static const String _fallbackLng = '7.3986';
  static const List<List<String>> _invalidTemplateDefaults = [
    ['23.02918734674459', '90.3515625'],
    ['23.757989', '90.360587'],
  ];

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng, {bool handleError = false}) async {
    Response response = await apiClient.getData('${AppConstants.zoneUri}?lat=$lat&lng=$lng', handleError: handleError);
    if(response.statusCode == 404 && _shouldUseFallback(lat, lng)) {
      StoreRegistrationDebug.log('getZone/fallback', {'fromLat': lat, 'fromLng': lng, 'toLat': _fallbackLat, 'toLng': _fallbackLng});
      response = await apiClient.getData(
        '${AppConstants.zoneUri}?lat=$_fallbackLat&lng=$_fallbackLng',
        handleError: handleError,
      );
    }
    StoreRegistrationDebug.logZoneApi(
      source: 'location_repository',
      lat: lat ?? '',
      lng: lng ?? '',
      statusCode: response.statusCode,
      success: response.statusCode == 200,
      zoneIds: response.statusCode == 200 ? ZoneModel.fromJson(response.body).zoneIds : null,
      message: response.statusCode == 200 ? null : response.statusText,
    );
    if(response.statusCode == 200) {
      ZoneResponseModel responseModel;
      List<int>? zoneIds = ZoneModel.fromJson(response.body).zoneIds;
      List<ZoneData>? zoneData = ZoneModel.fromJson(response.body).zoneData;
      responseModel = ZoneResponseModel(true, '' , zoneIds ?? [], zoneData??[], [], response.statusCode, null);
      return responseModel;
    } else {
      return ZoneResponseModel(false, response.statusText, [], [], [], response.statusCode, null);
    }
  }

  @override
  Future<Response> searchLocation(String text) async {
    return await apiClient.getData('${AppConstants.searchLocationUri}?search_text=$text');
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> get(String? id) async {
    Response response = await apiClient.getData('${AppConstants.placeDetailsUri}?placeid=$id');
    return response;
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
  @override
  String? getUserAddress() {
    return sharedPreferences.getString(AppConstants.userAddress);
  }

  bool _isFallbackCoordinate(String? lat, String? lng) {
    return lat == _fallbackLat && lng == _fallbackLng;
  }

  bool _shouldUseFallback(String? lat, String? lng) {
    if (_isFallbackCoordinate(lat, lng)) {
      return false;
    }
    for (final coords in _invalidTemplateDefaults) {
      if (lat == coords[0] && lng == coords[1]) {
        return true;
      }
    }
    return false;
  }

}
