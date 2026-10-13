import 'package:flutter/material.dart' hide Text;
import 'localized_text.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/shift_attendance_screen.dart';
import '../screens/kilometer_screen.dart';

class WorkingHoursWidget extends StatefulWidget {
  const WorkingHoursWidget({super.key});

  @override
  State<WorkingHoursWidget> createState() => _WorkingHoursWidgetState();
}

class _WorkingHoursWidgetState extends State<WorkingHoursWidget> {
  Timer? _timer;
  bool isLoading = true;
  bool shiftStarted = false;
  bool shiftEnded = false;
  String shiftStartTime = '';
  String shiftEndTime = '';
  double totalHours = 0;
  double currentHours = 0;
  String calculatedStatus = 'not_started';
  bool isStarting = false;
  bool isEnding = false;
  bool isSendingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (shiftStarted && !shiftEnded) {
        _loadTodayData();
        _sendCurrentLocation();
      }
    });
  }

  Future<void> _sendCurrentLocation() async {
    if (isSendingLocation) return;

    isSendingLocation = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;
      if (technicianId == 0 || !await Geolocator.isLocationServiceEnabled()) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await ApiService.updateLocation(
        technicianId: technicianId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (_) {
      // Location heartbeats must not interrupt shift attendance.
    } finally {
      isSendingLocation = false;
    }
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'y';
    }
    return false;
  }

  Future<void> _loadTodayData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) return;

      final result = await ApiService.getTodayWorkingHours(technicianId);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final String startTimeValue =
            (data['shift_start_time'] ?? '').toString().trim();
        final String endTimeValue =
            (data['shift_end_time'] ?? '').toString().trim();
        final String statusValue =
            (data['status'] ?? data['calculated_status'] ?? 'not_started')
                .toString()
                .trim();
        final bool hasStartTime = startTimeValue.isNotEmpty;
        final bool hasEndTime = endTimeValue.isNotEmpty;
        final bool rawShiftStarted = _toBool(data['shift_started']);
        final bool rawShiftEnded = _toBool(data['shift_ended']);
        final bool apiShiftStarted = rawShiftStarted ||
            (statusValue == 'in_progress') ||
            (statusValue == 'started') ||
            hasStartTime;
        final bool apiShiftEnded = rawShiftEnded ||
            hasEndTime ||
            (statusValue == 'completed') ||
            (statusValue == 'present') ||
            (statusValue == 'half_day') ||
            (statusValue == 'absent');

        if (mounted) {
          setState(() {
            shiftStarted = apiShiftStarted;
            shiftEnded = apiShiftEnded;
            shiftStartTime = startTimeValue;
            shiftEndTime = endTimeValue;
            totalHours = (data['total_hours_worked'] ?? 0).toDouble();
            currentHours = (data['current_hours'] ?? 0).toDouble();
            calculatedStatus = apiShiftStarted && !apiShiftEnded
                ? 'in_progress'
                : (data['calculated_status'] ??
                    (apiShiftEnded ? 'completed' : 'not_started'));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _startShift() async {
    // Navigate to kilometer screen for start reading
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KilometerScreen(isStart: true),
      ),
    );

    // Reload data after returning
    if (result == true || mounted) {
      _loadTodayData();
    }
  }

  Future<void> _endShift() async {
    // Navigate to kilometer screen for end reading
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KilometerScreen(isStart: false),
      ),
    );

    // Reload data after returning
    if (result == true || mounted) {
      _loadTodayData();
    }
  }

  Color _getStatusColor() {
    if (!shiftStarted) return const Color(0xFFE88A25);
    if (shiftEnded) {
      switch (calculatedStatus) {
        case 'present':
          return const Color(0xFF328A4A);
        case 'half_day':
          return const Color(0xFFE88A25);
        case 'absent':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
    return const Color(0xFF2476C9);
  }

  String _getStatusText() {
    if (!shiftStarted) return 'Not Started';
    if (shiftEnded) {
      switch (calculatedStatus) {
        case 'present':
          return 'Present';
        case 'half_day':
          return 'Half Day';
        case 'absent':
          return 'Absent';
        default:
          return 'Completed';
      }
    }
    return 'In Progress';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE1E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D3553).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D3553).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and calendar icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Shift',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172B45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shiftEnded ? 'Shift completed' : 'Track your working hours',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShiftAttendanceScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAF3FC), Color(0xFFDCEBFA)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 24,
                    color: Color(0xFF2476C9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Hours display card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor().withValues(alpha: 0.08),
                  _getStatusColor().withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor().withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor().withValues(alpha: 0.2),
                        _getStatusColor().withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    shiftStarted && !shiftEnded
                        ? Icons.timer_rounded
                        : Icons.check_circle_rounded,
                    color: _getStatusColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shiftEnded
                            ? '${totalHours.toStringAsFixed(2)} hrs'
                            : shiftStarted
                                ? '${currentHours.toStringAsFixed(2)} hrs'
                                : '0.00 hrs',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w800,
                          color: _getStatusColor(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor().withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time info section
          if (shiftStarted && !shiftEnded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Started at $shiftStartTime',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            )
          else if (shiftEnded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 18,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'In: $shiftStartTime',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Out: $shiftEndTime',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Action buttons
          if (!shiftStarted)
            _buildModernActionButton(
              'START SHIFT',
              Colors.green[700]!,
              Icons.play_arrow_rounded,
              isStarting,
              _startShift,
            )
          else if (!shiftEnded)
            _buildModernActionButton(
              'END SHIFT',
              const Color(0xFFE88A25),
              Icons.stop_rounded,
              isEnding,
              _endShift,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F4EB), Color(0xFFF4FAF5)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFC9E5D0),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF328A4A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Shift Completed',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF328A4A),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    String label,
    Color color,
    IconData icon,
    bool isLoading,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
