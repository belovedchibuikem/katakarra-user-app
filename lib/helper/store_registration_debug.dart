import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

/// Debug helpers for vendor/store registration map + zone flow (web & mobile).
class StoreRegistrationDebug {
  static const String _prefix = '[StoreRegDebug]';

  static bool get active => kDebugMode;

  static void log(String step, [Map<String, Object?>? data]) {
    if (!active) return;
    final buffer = StringBuffer('$_prefix $step');
    data?.forEach((key, value) => buffer.write(' | $key=$value'));
    debugPrint(buffer.toString());
  }

  static void logZoneApi({
    required String source,
    required String lat,
    required String lng,
    int? statusCode,
    bool? success,
    List<int>? zoneIds,
    String? message,
  }) {
    log('zone-api/$source', {
      'lat': lat,
      'lng': lng,
      'status': statusCode,
      'success': success,
      'zoneIds': zoneIds?.join(','),
      'message': message,
    });
  }
}

/// Floating debug panel (debug web builds only). Open DevTools console for full logs.
class StoreRegistrationDebugPanel extends StatelessWidget {
  final int polygonCount;
  final bool mapCreated;
  final String? lastZoneDetect;

  const StoreRegistrationDebugPanel({
    super.key,
    required this.polygonCount,
    required this.mapCreated,
    this.lastZoneDetect,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !kIsWeb) {
      return const SizedBox.shrink();
    }

    return GetBuilder<StoreRegistrationController>(builder: (controller) {
      final config = Get.find<SplashController>().configModel?.defaultLocation;
      return Positioned(
        left: 8,
        bottom: 8,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withValues(alpha: 0.82),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.35, fontFamily: 'monospace'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Store registration debug', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  Text('zones loaded: ${controller.zoneList?.length ?? 0}'),
                  Text('selected zone idx: ${controller.selectedZoneIndex}'),
                  Text('in zone: ${controller.inZone}'),
                  Text('map ready: $mapCreated | polygons: $polygonCount'),
                  Text('default lat/lng: ${config?.lat}, ${config?.lng}'),
                  Text('restaurant: ${controller.restaurantLocation?.latitude}, ${controller.restaurantLocation?.longitude}'),
                  if (lastZoneDetect != null) Text('last detect: $lastZoneDetect'),
                  const SizedBox(height: 4),
                  const Text('See browser console for [StoreRegDebug] logs'),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
