import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/services/location_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../widgets/app_header_bar.dart';
import '../../prayer/presentation/providers/aladhan_providers.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  double _smoothedHeading = 0.0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  final MapController _mapController = MapController();
  bool _hasVibrated = false;

  @override
  void initState() {
    super.initState();
    _initCompassSensor();
  }

  void _initCompassSensor() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        _handleHeadingUpdate((event.heading! + 360.0) % 360.0);
      }
    });

    if (FlutterCompass.events == null) {
      _magnetometerSubscription = magnetometerEventStream().listen((event) {
        final angle = math.atan2(event.y, event.x) * (180.0 / math.pi);
        _handleHeadingUpdate((angle + 360.0) % 360.0);
      });
    }
  }

  void _handleHeadingUpdate(double rawHeading) {
    final diff = (rawHeading - _smoothedHeading + 540.0) % 360.0 - 180.0;
    final newSmoothed = (_smoothedHeading + diff * 0.18 + 360.0) % 360.0;

    if (mounted && (newSmoothed - _smoothedHeading).abs() > 0.08) {
      setState(() {
        _smoothedHeading = newSmoothed;
      });
      try {
        _mapController.rotate(-_smoothedHeading);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final location = locationAsync.value ?? LocationService.defaultLocation;

    // Fetch Qibla direction from AlAdhan API GET /qibla/{lat}/{lng} with local fallback
    final qiblaAsync = ref.watch(
      qiblaDirectionProvider((
        latitude: location.latitude,
        longitude: location.longitude,
      )),
    );

    final qiblaAngle =
        qiblaAsync.value ??
        LocationService.calculateQiblaDirection(
          location.latitude,
          location.longitude,
        );

    final distanceToMakkah = LocationService.calculateDistanceToMakkah(
      location.latitude,
      location.longitude,
    );

    final angleDiff = (qiblaAngle - _smoothedHeading + 360.0) % 360.0;
    final isAligned = angleDiff < 5.0 || angleDiff > 355.0;

    if (isAligned && !_hasVibrated) {
      _hasVibrated = true;
      HapticFeedback.lightImpact();
    } else if (!isAligned && _hasVibrated) {
      _hasVibrated = false;
    }

    final rotateDegree = angleDiff > 180
        ? (360 - angleDiff).round()
        : angleDiff.round();
    final rotateDirection = angleDiff > 180 ? 'right' : 'left';

    final screenHeight = MediaQuery.of(context).size.height;
    final topMapHeight = screenHeight * 0.50;

    final userLatLng = LatLng(location.latitude, location.longitude);
    const makkahLatLng = LatLng(21.422487, 39.826206);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      extendBodyBehindAppBar: true,
      appBar: const AppHeaderBar(
        title: 'QIBLA FINDER',
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // 1. Top Half High-HD Map View (CartoDB Retina @2x crisp tile render)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topMapHeight + 75,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints([userLatLng, makkahLatLng]),
                  padding: const EdgeInsets.all(52),
                ),
                initialRotation: -_smoothedHeading,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'com.sprnt.adhkar',
                  retinaMode: true,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [userLatLng, makkahLatLng],
                      color: const Color(0xFF2A531D),
                      strokeWidth: 3.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // User Location Marker
                    Marker(
                      point: userLatLng,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9A925),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Makkah Kaaba Marker
                    Marker(
                      point: makkahLatLng,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A531D),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 10),
                          ],
                        ),
                        child: const Icon(
                          FlutterIslamicIcons.kaaba,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Floating Instruction Banner on top of Map View
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 20,
            right: 20,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isAligned
                      ? const Color(0xFF2A531D)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAligned
                        ? const Color(0xFF2A531D)
                        : const Color(0xFFC8E6C9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAligned
                          ? Icons.check_circle_rounded
                          : Icons.explore_rounded,
                      color: isAligned ? Colors.white : const Color(0xFF2A531D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAligned
                          ? 'Aligned! Facing Makkah.'
                          : 'Rotate phone $rotateDegree° to the $rotateDirection',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isAligned
                            ? Colors.white
                            : const Color(0xFF2A531D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Container Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: topMapHeight + 45,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                top: 100,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Column(
                children: [
                  const Spacer(),

                  // Clean Unboxed Location Text directly above metrics (No box / background)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF2A531D),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${location.city}, ${location.country}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A531D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' • ${location.latitude.toStringAsFixed(2)}°, ${location.longitude.toStringAsFixed(2)}°',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8C6D53),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bottom Metrics Summary Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MetricItem(
                        label: 'Qibla Direction',
                        value: '${qiblaAngle.round()}° N',
                        icon: FlutterIslamicIcons.kaaba,
                      ),
                      _MetricItem(
                        label: 'Phone Facing',
                        value: '${_smoothedHeading.round()}°',
                        icon: Icons.compass_calibration_rounded,
                      ),
                      _MetricItem(
                        label: 'Distance to Makkah',
                        value: '${distanceToMakkah.round()} km',
                        icon: Icons.straighten_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Overlapping Arch Compass Dial (1/3 Top Map, 2/3 Bottom Container)
          Positioned(
            top: topMapHeight - 110,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 280,
                height: 180,
                child: CustomPaint(
                  painter: _CompassArchPainter(
                    smoothedHeading: _smoothedHeading,
                    qiblaAngle: qiblaAngle,
                    isAligned: isAligned,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2A531D), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A531D),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8C6D53),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter for rendering the Arch Compass dial with N, E, S, W labels and orange Qibla arrowhead
class _CompassArchPainter extends CustomPainter {
  final double smoothedHeading;
  final double qiblaAngle;
  final bool isAligned;

  _CompassArchPainter({
    required this.smoothedHeading,
    required this.qiblaAngle,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width * 0.44;

    // 1. Draw Outer Glowing Background Arc Container
    final bgPaint = Paint()
      ..color = isAligned
          ? const Color(0xFF2A531D)
          : const Color(0xFF2A531D).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius + 4, shadowPaint);
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Draw Outer Border Ring
    final borderPaint = Paint()
      ..color = isAligned ? const Color(0xFFD9A925) : const Color(0xFFC8E6C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 3.5 : 2.0;

    canvas.drawCircle(center, radius - 2, borderPaint);

    // 3. Draw 8 Major Directions (4 Cardinal + 4 Intercardinal) & 10 Small Thin Ticks between each pair
    final majorTickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final subTickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int k = 0; k < 8; k++) {
      final majorDeg = k * 45.0; // 0, 45, 90, 135, 180, 225, 270, 315

      // 3a. Draw Major Tick (Large & Thick)
      final majorAngleRad =
          (majorDeg - smoothedHeading - 90) * (math.pi / 180.0);
      final innerRMajor = radius - 8;
      final outerRMajor = innerRMajor - 14.0;

      final startMajor = Offset(
        center.dx + innerRMajor * math.cos(majorAngleRad),
        center.dy + innerRMajor * math.sin(majorAngleRad),
      );
      final endMajor = Offset(
        center.dx + outerRMajor * math.cos(majorAngleRad),
        center.dy + outerRMajor * math.sin(majorAngleRad),
      );

      canvas.drawLine(startMajor, endMajor, majorTickPaint);

      // Draw Cardinal Labels ONLY for N, E, S, W (0°, 90°, 180°, 270°)
      if (k % 2 == 0) {
        String text;
        Color textColor = Colors.white;

        if (k == 0) {
          text = 'N';
          textColor = const Color(0xFFFF5252);
        } else if (k == 2) {
          text = 'E';
        } else if (k == 4) {
          text = 'S';
        } else {
          text = 'W';
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final textR = innerRMajor - 28;
        final textPos = Offset(
          center.dx + textR * math.cos(majorAngleRad) - textPainter.width / 2,
          center.dy + textR * math.sin(majorAngleRad) - textPainter.height / 2,
        );

        textPainter.paint(canvas, textPos);
      }

      // 3b. Draw 10 Small Thin Ticks between majorDeg and majorDeg + 45°
      for (int i = 1; i <= 14; i++) {
        final subDeg = majorDeg + i * (45.0 / 15.0);
        final subAngleRad = (subDeg - smoothedHeading - 90) * (math.pi / 180.0);

        final innerRSub = radius - 8;
        final outerRSub = innerRSub - 6.0;

        final startSub = Offset(
          center.dx + innerRSub * math.cos(subAngleRad),
          center.dy + innerRSub * math.sin(subAngleRad),
        );
        final endSub = Offset(
          center.dx + outerRSub * math.cos(subAngleRad),
          center.dy + outerRSub * math.sin(subAngleRad),
        );

        canvas.drawLine(startSub, endSub, subTickPaint);
      }
    }

    // 4. Draw Qibla Target Line & Sharp Orange Arrowhead Mark at the end
    final qiblaRad = (qiblaAngle - smoothedHeading - 90) * (math.pi / 180.0);
    final needleColor = isAligned
        ? const Color(0xFF4CAF50)
        : const Color(0xFFD9A925);

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final needleStart = center;
    final needleEnd = Offset(
      center.dx + (radius - 18) * math.cos(qiblaRad),
      center.dy + (radius - 18) * math.sin(qiblaRad),
    );

    canvas.drawLine(needleStart, needleEnd, needlePaint);

    // Draw Arrowhead Mark pointing outwards
    const arrowSize = 14.0;
    const arrowAngle = 0.45;

    final arrowTip = Offset(
      center.dx + (radius - 6) * math.cos(qiblaRad),
      center.dy + (radius - 6) * math.sin(qiblaRad),
    );

    final leftWing = Offset(
      arrowTip.dx - arrowSize * math.cos(qiblaRad - arrowAngle),
      arrowTip.dy - arrowSize * math.sin(qiblaRad - arrowAngle),
    );

    final rightWing = Offset(
      arrowTip.dx - arrowSize * math.cos(qiblaRad + arrowAngle),
      arrowTip.dy - arrowSize * math.sin(qiblaRad + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();

    final arrowPaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);

    // 5. Draw Center Pivot Knob
    final pivotPaint = Paint()..color = needleColor;
    canvas.drawCircle(center, 10, pivotPaint);

    final pivotInnerPaint = Paint()..color = const Color(0xFF2A531D);
    canvas.drawCircle(center, 5, pivotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassArchPainter oldDelegate) {
    return oldDelegate.smoothedHeading != smoothedHeading ||
        oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.isAligned != isAligned;
  }
}
