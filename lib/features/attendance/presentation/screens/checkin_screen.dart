import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/attendance_repository.dart';
import '../../../dashboard/data/dashboard_repository.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  Position? _position;
  String _locationLabel = 'Resolving location…';
  String? _error;
  bool _busy = false;
  CheckInResult? _result;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadLocation();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _locationLabel = 'Location services are off');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _locationLabel = 'Location permission denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = pos;
        _locationLabel = _formatPosition(pos);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationLabel = 'Could not get location');
    }
  }

  String _formatPosition(Position p) {
    if (Env.hasGeofence) {
      final dist = Geolocator.distanceBetween(
        Env.officeLatitude,
        Env.officeLongitude,
        p.latitude,
        p.longitude,
      );
      final inside = dist <= Env.officeRadiusMeters;
      return '${inside ? 'Inside office' : 'Outside office'} • ${dist.toStringAsFixed(0)} m';
    }
    return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  Future<void> _submit({required bool isCheckIn}) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final repo = ref.read(attendanceRepositoryProvider);
    try {
      final res = isCheckIn
          ? await repo.checkIn(
              latitude: _position?.latitude,
              longitude: _position?.longitude,
            )
          : await repo.checkOut(
              latitude: _position?.latitude,
              longitude: _position?.longitude,
            );

      if (!mounted) return;
      setState(() {
        _result = res;
        _busy = false;
      });

      ref.invalidate(employeeDashboardProvider);
      ref.invalidate(monthlyAttendanceProvider);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(employeeDashboardProvider);
    final hasIn = dashboard.maybeWhen(data: (d) => d.hasCheckedIn, orElse: () => false);
    final isCheckIn = !hasIn;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(isCheckIn ? 'Check In' : 'Check Out'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: _result != null
              ? _SuccessView(result: _result!, isCheckIn: isCheckIn)
              : Column(
                  children: <Widget>[
                    const Spacer(),
                    Text(
                      DateFormatter.displayTime(_now),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 64,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      DateFormatter.displayDateLong(_now),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.location_on_outlined, color: AppColors.gold, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _locationLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.18),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: PrimaryButton(
                        label: isCheckIn ? 'Tap to Check In' : 'Tap to Check Out',
                        icon: isCheckIn ? Icons.login : Icons.logout,
                        loading: _busy,
                        variant: PrimaryButtonVariant.gold,
                        onPressed: () => _submit(isCheckIn: isCheckIn),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result, required this.isCheckIn});
  final CheckInResult result;
  final bool isCheckIn;

  @override
  Widget build(BuildContext context) {
    final hasLate = result.lateMinutes > 0;
    final hasEarly = result.earlyExitMinutes > 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 64, color: AppColors.black),
          ),
          const SizedBox(height: 28),
          Text(
            isCheckIn ? 'Checked in successfully' : 'Checked out successfully',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'at ${DateFormatter.displayTime(result.time)}',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (hasLate)
            _Banner(
              icon: Icons.schedule,
              text: '${result.lateMinutes.toStringAsFixed(0)} minutes late',
              color: AppColors.warning,
            ),
          if (hasEarly)
            _Banner(
              icon: Icons.exit_to_app,
              text: '${result.earlyExitMinutes.toStringAsFixed(0)} minutes early exit',
              color: AppColors.warning,
            ),
          if (!hasLate && !hasEarly && isCheckIn)
            const _Banner(
              icon: Icons.thumb_up_alt_outlined,
              text: 'You\'re right on time. Have a great day!',
              color: AppColors.success,
            ),
          const Spacer(),
          PrimaryButton(
            label: 'Done',
            variant: PrimaryButtonVariant.gold,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
