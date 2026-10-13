import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import '../widgets/localized_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';
import '../models/job.dart';
import '../widgets/responsive_stats_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/working_hours_widget.dart';
import '../utils/neumorphic_style.dart';
import '../utils/date_formatter.dart';
import 'job_detail_screen.dart';
import 'survey_jobs_screen.dart';
import 'leave_apply_screen.dart';
import 'expense_screen.dart';
import 'petrol_allowance_screen.dart';
import 'kilometer_screen.dart';
import 'chemical_screen.dart';
import 'advance_apply_screen.dart';
import 'cash_submission_screen.dart';
import 'help_screen.dart';
import 'branches_screen.dart';
import 'tomorrow_jobs_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/app_language.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _autoRefreshInterval = Duration(seconds: 30);

  String _t(String text) => AppText.translate(context, text);

  Timer? _autoRefreshTimer;
  Timer? _clockTimer;
  StreamSubscription<Position>? _mobileGpsSubscription;
  final ValueNotifier<int> _refreshCountdown = ValueNotifier(30);
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  DateTime _currentTime = DateTime.now();

  String technicianName = '';
  String technicianCode = '';
  String technicianUserId = '';
  String? profilePictureUrl;
  bool isLoading = true;
  List<Job> myJobs = [];
  Map<String, dynamic> jobVisibility = {
    'limit': 1,
    'unlimited': false,
    'visible_count': 0,
    'locked_count': 0,
    'total_count': 0,
  };
  List<Map<String, dynamic>> surveyJobs = [];
  bool isLoadingSurveyJobs = true;
  String? surveyJobsError;
  List<Map<String, dynamic>> blockedSlots = [];
  Map<String, dynamic>? activeBlockedSlot;
  List<TechnicianNotificationItem> technicianNotifications = [];
  int unreadChatCount = 0;
  JobStats stats = JobStats(
    pending: 0,
    completed: 0,
    online: 0,
    cash: 0,
    cashPending: 0,
  );

  // Leave status
  bool isOnLeave = false;
  String? leaveStartDate;
  String? leaveEndDate;
  String? leaveType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadUserData());
    unawaited(_checkLeaveStatus());
    unawaited(_loadDashboardData());
    _startAutoRefresh();
    _startClock();
    _startMobileGpsStream();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final secondsLeft = _refreshCountdown.value;
      if (secondsLeft > 0) _refreshCountdown.value = secondsLeft - 1;

      final now = DateTime.now();
      if (now.minute != _currentTime.minute ||
          now.day != _currentTime.day ||
          now.month != _currentTime.month) {
        setState(() => _currentTime = now);
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _refreshCountdown.value = _autoRefreshInterval.inSeconds;
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) async {
      if (!mounted || _isRefreshing) return;
      _refreshCountdown.value = _autoRefreshInterval.inSeconds;
      _isRefreshing = true;
      try {
        await _loadDashboardData();
      } catch (e) {
        debugPrint('Auto-refresh failed: $e');
      } finally {
        _isRefreshing = false;
      }
    });
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadJobs(),
      _loadSurveyJobs(),
      _loadStats(),
    ]);
  }

  Future<void> _startMobileGpsStream() async {
    final userId = await AuthService.getDbId();
    if (userId == null ||
        userId <= 0 ||
        !await Geolocator.isLocationServiceEnabled()) {
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

    await _mobileGpsSubscription?.cancel();
    _mobileGpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) async {
      await ApiService.recordMobileLocation(
        action: 'update',
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    }, onError: (error) {
      debugPrint('Technician GPS stream failed: $error');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
      _refreshLatestActivity();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _autoRefreshTimer?.cancel();
    }
  }

  Future<void> _refreshLatestActivity() async {
    if (!mounted || _isRefreshing) return;
    _isRefreshing = true;
    try {
      await _loadDashboardData();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _checkLeaveStatus() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;

      if (technicianId == 0) return;

      final result =
          await ApiService.checkLeaveStatus(technicianId: technicianId);

      if (result['success'] == true && result['on_leave'] == true) {
        final leaveDetails = result['leave_details'];
        if (!mounted) return;
        setState(() {
          isOnLeave = true;
          leaveStartDate = leaveDetails['start_date'];
          leaveEndDate = leaveDetails['end_date'];
          leaveType = leaveDetails['leave_type'];
        });
      }
    } catch (e) {
      debugPrint('Error checking leave status: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;

      if (technicianId == 0) return;

      final result = await ApiService.getStats(technicianId);

      if (result['success'] == true && result['data'] != null) {
        if (!mounted) return;
        setState(() {
          stats = JobStats(
            pending: result['data']['pending'] ?? 0,
            completed: result['data']['completed'] ?? 0,
            online: (result['data']['online'] ?? 0).toDouble(),
            cash: (result['data']['cash'] ?? 0).toDouble(),
            cashPending: (result['data']['cash_pending'] ?? 0).toDouble(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _loadChatUnreadCount() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;

      if (technicianId == 0) {
        if (mounted) setState(() => unreadChatCount = 0);
        return;
      }

      final result =
          await ApiService.getUnreadSummary(technicianId: technicianId);
      if (!mounted) return;

      if (result['success'] == true && result['data'] is Map) {
        final count = (result['data']['unread_count'] as int? ?? 0);
        setState(() => unreadChatCount = count);
      } else {
        setState(() => unreadChatCount = 0);
      }
    } catch (e) {
      debugPrint('Error loading chat unread count: $e');
      if (mounted) setState(() => unreadChatCount = 0);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final authData = await AuthService.getUserData();
      final userIdValue = authData['user_id'] ?? '';

      debugPrint('📱 Loading user data from auth: $authData');

      if (!mounted) return;
      setState(() {
        technicianName = authData['name'] ?? 'Technician';
        technicianCode = authData['code'] ?? '';
        technicianUserId = authData['user_id'] ?? '';
        profilePictureUrl = authData['profile_picture'];
        isLoading = false;
      });

      if (userIdValue.isNotEmpty) {
        final profileResponse = await ApiService.getProfile(userIdValue);

        if (!mounted) return;

        if (profileResponse['success'] == true &&
            profileResponse['data'] != null) {
          final data = profileResponse['data'];
          setState(() {
            profilePictureUrl = data['profile_picture'];
          });
          debugPrint('✅ Updated profile picture from API');
        }
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadJobs() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianDbId = userData['db_id'] ?? 0;

      if (technicianDbId == 0) {
        debugPrint('❌ Invalid technician ID');
        return;
      }

      final result = await ApiService.getMyJobs(technicianDbId);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> jobsData = result['data'];
        final dashboardData = result['dashboard'] is Map
            ? Map<String, dynamic>.from(result['dashboard'] as Map)
            : null;
        final jobVisibilityData = result['job_visibility'] is Map
            ? Map<String, dynamic>.from(result['job_visibility'] as Map)
            : jobVisibility;
        final List<dynamic> blockedSlotsResponse = (dashboardData != null
            ? (dashboardData['blocked_slots'] ?? result['blocked_slots'] ?? [])
            : (result['blocked_slots'] ?? [])) as List<dynamic>;
        final parsedBlockedSlots = blockedSlotsResponse
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        final activeSlot = dashboardData != null &&
                dashboardData['active_block'] is Map
            ? Map<String, dynamic>.from(dashboardData['active_block'] as Map)
            : (parsedBlockedSlots.isNotEmpty ? parsedBlockedSlots.first : null);

        if (!mounted) return;
        setState(() {
          myJobs = jobsData.map((json) => Job.fromJson(json)).toList();
          jobVisibility = jobVisibilityData;
          myJobs.sort((a, b) {
            if (a.scheduledDate == null && b.scheduledDate == null) return 0;
            if (a.scheduledDate == null) return 1;
            if (b.scheduledDate == null) return -1;
            return a.scheduledDate!.compareTo(b.scheduledDate!);
          });
          blockedSlots = parsedBlockedSlots;
          activeBlockedSlot = activeSlot;
          technicianNotifications = ApiService.buildTechnicianNotifications(
            jobsData,
          ).map(_notificationFromMap).toList();
        });
        debugPrint('✅ Loaded ${myJobs.length} jobs (sorted by time ascending)');
        debugPrint(
            '✅ Loaded ${blockedSlots.length} blocked slots for technician');
      } else {
        debugPrint('❌ Failed to load jobs: ${result['message']}');
      }
    } catch (e) {
      debugPrint('❌ Error loading jobs: $e');
    }
  }

  Future<void> _loadSurveyJobs() async {
    try {
      final technicianId = await AuthService.getTechnicianId();
      if (technicianId == null || technicianId <= 0) {
        if (!mounted) return;
        setState(() {
          surveyJobs = [];
          surveyJobsError = 'Technician account could not be identified.';
          isLoadingSurveyJobs = false;
        });
        return;
      }

      final result = await ApiService.getMySurveyJobs(technicianId);
      if (!mounted) return;

      if (result['success'] == true && result['data'] is List) {
        setState(() {
          surveyJobs = (result['data'] as List)
              .whereType<Map>()
              .map((lead) => Map<String, dynamic>.from(lead))
              .toList();
          surveyJobsError = null;
          isLoadingSurveyJobs = false;
        });
      } else {
        setState(() {
          surveyJobsError =
              (result['message'] ?? 'Could not load survey jobs.').toString();
          isLoadingSurveyJobs = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        surveyJobsError = 'Could not load survey jobs: $error';
        isLoadingSurveyJobs = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianDbId = userData['db_id'] ?? 0;

      if (technicianDbId == 0) {
        return;
      }

      final notificationsData = await ApiService.getTechnicianNotifications(
        technicianDbId,
      );

      if (!mounted) return;

      setState(() {
        technicianNotifications = notificationsData.map((item) {
          final icon = switch ((item['icon'] ?? 'assignment').toString()) {
            'check_circle' => Icons.check_circle_rounded,
            'work' => Icons.work_rounded,
            'schedule' => Icons.schedule_rounded,
            'notifications' => Icons.notifications_rounded,
            _ => Icons.assignment_rounded,
          };

          final color = switch ((item['color'] ?? 'purple').toString()) {
            'green' => Colors.green,
            'blue' => Colors.blue,
            'orange' => Colors.orange,
            _ => const Color(0xFF6D5EF7),
          };

          final createdAt = DateTime.tryParse(item['created_at'].toString()) ??
              DateTime.now();

          return TechnicianNotificationItem(
            title: (item['title'] ?? 'Activity').toString(),
            message: (item['message'] ?? 'Technician activity').toString(),
            createdAt: createdAt,
            icon: icon,
            color: color,
            unread: item['unread'] ?? true,
            noticeId: int.tryParse(item['notice_id']?.toString() ?? ''),
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ Error loading technician notifications: $e');
    }
  }

  TechnicianNotificationItem _notificationFromMap(Map<String, dynamic> item) {
    final icon = switch ((item['icon'] ?? 'assignment').toString()) {
      'check_circle' => Icons.check_circle_rounded,
      'work' => Icons.work_rounded,
      'schedule' => Icons.schedule_rounded,
      'notifications' => Icons.notifications_rounded,
      _ => Icons.assignment_rounded,
    };
    final color = switch ((item['color'] ?? 'purple').toString()) {
      'green' => Colors.green,
      'blue' => Colors.blue,
      'orange' => Colors.orange,
      _ => const Color(0xFF6D5EF7),
    };

    return TechnicianNotificationItem(
      title: (item['title'] ?? 'Activity').toString(),
      message: (item['message'] ?? 'Technician activity').toString(),
      createdAt:
          DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now(),
      icon: icon,
      color: color,
      unread: item['unread'] ?? true,
      noticeId: int.tryParse(item['notice_id']?.toString() ?? ''),
    );
  }

  Future<void> _openNotifications() async {
    final userData = await AuthService.getUserData();
    final technicianId = userData['db_id'] ?? 0;
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          notifications: technicianNotifications,
          technicianId: technicianId is int ? technicianId : int.tryParse('$technicianId'),
        ),
      ),
    );
    await _loadNotifications();
  }

  Future<void> _openChat() async {
    final userData = await AuthService.getUserData();
    final technicianId = userData['db_id'] ?? 0;

    if (!mounted || technicianId == 0) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          technicianId: technicianId,
          title: 'Technician Chat',
          onChatUpdated: () async {
            await _loadChatUnreadCount();
            await _loadNotifications();
          },
        ),
      ),
    );

    if (mounted) {
      await _loadChatUnreadCount();
      await _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFD), Color(0xFFF0F4F8)],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              if (isOnLeave) _buildLeaveBanner(),
              if (blockedSlots.isNotEmpty) _buildBlockedSlotBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: const Color(0xFF2476C9),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: WorkingHoursWidget(),
                        ),
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        const SizedBox(height: 20),
                        _buildSurveyJobsSection(),
                        const SizedBox(height: 20),
                        _buildJobSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: _buildDrawer(),
    );
  }

  Widget _buildBlockedSlotBanner() {
    if (blockedSlots.isEmpty) {
      return const SizedBox.shrink();
    }

    final slot = activeBlockedSlot ?? blockedSlots.first;
    final String blockedDate = (slot['blocked_date'] ?? '').toString();
    final String startTime = (slot['start_time'] ?? '').toString();
    final String endTime = (slot['end_time'] ?? '').toString();
    final String reason = (slot['reason'] ?? 'Blocked by admin').toString();
    final dynamic amountValue = slot['amount'];
    final int? jobId =
        slot['job_id'] != null ? int.tryParse(slot['job_id'].toString()) : null;

    Job? linkedJob;
    if (jobId != null) {
      for (final job in myJobs) {
        if (job.id == jobId) {
          linkedJob = job;
          break;
        }
      }
    }

    final linkedJobData = slot['job'];
    final String linkedJobCustomer = linkedJobData is Map
        ? (linkedJobData['customer_name'] ?? '').toString()
        : '';
    final String linkedJobAddress = linkedJobData is Map
        ? [
            linkedJobData['address'],
            linkedJobData['city'],
            linkedJobData['state'],
          ]
            .where(
                (value) => value != null && value.toString().trim().isNotEmpty)
            .join(', ')
        : '';

    final String linkedJobName = linkedJob != null
        ? (linkedJob.customerName.isNotEmpty
            ? linkedJob.customerName
            : 'Job #${linkedJob.id}')
        : (linkedJobCustomer.isNotEmpty
            ? linkedJobCustomer
            : (jobId != null ? 'Job #$jobId' : 'No linked job'));

    final String locationText = linkedJob != null
        ? [
            linkedJob.address,
            linkedJob.city,
            linkedJob.state,
          ].where((value) => value.toString().trim().isNotEmpty).join(', ')
        : (linkedJobAddress.isNotEmpty
            ? linkedJobAddress
            : 'Location not available');

    final bool isActive = (slot['is_active_now'] ?? false) == true ||
        (activeBlockedSlot != null && activeBlockedSlot == slot);
    final String bannerTitle = isActive ? 'Active block' : 'Scheduled block';
    final String dateTimeText = [blockedDate, startTime, endTime]
        .where((value) => value.trim().isNotEmpty)
        .join(' • ');
    final String amountText = amountValue != null &&
            amountValue.toString().trim().isNotEmpty
        ? 'Amount: ₹${double.tryParse(amountValue.toString())?.toStringAsFixed(0) ?? amountValue}'
        : 'Amount: Not set';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF2F2), Color(0xFFFFEAEA)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF7A7A7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive ? Icons.warning_amber_rounded : Icons.schedule_rounded,
              color: Colors.red[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.red[900],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Date / Time: $dateTimeText',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reason: $reason',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Linked job: $linkedJobName',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Branch / Location: $locationText',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBanner() {
    final startDate =
        leaveStartDate != null ? DateFormatter.formatDate(leaveStartDate!) : '';
    final endDate =
        leaveEndDate != null ? DateFormatter.formatDate(leaveEndDate!) : '';

    String leaveTypeName = leaveType ?? 'Leave';
    if (leaveType == 'sick') leaveTypeName = 'Sick Leave';
    if (leaveType == 'casual') leaveTypeName = 'Casual Leave';
    if (leaveType == 'emergency') leaveTypeName = 'Emergency Leave';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F0D8), Color(0xFFFFF8E8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0C96E), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.info_outline, color: Colors.orange[700], size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are on $leaveTypeName',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From: $startDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'To: $endDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You cannot receive new job assignments during this period.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadDashboardData();
    unawaited(Future.wait([
      _loadUserData(),
      _checkLeaveStatus(),
      _loadNotifications(),
    ]));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data refreshed successfully!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _clockTimer?.cancel();
    _mobileGpsSubscription?.cancel();
    _refreshCountdown.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: NeumorphicStyle.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      setState(() => _isLoggingOut = true);
                      try {
                        final userId = await AuthService.getDbId();
                        unawaited(_recordMobileLocation('end', userId));
                        await AuthService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      } catch (error) {
                        debugPrint('Logout failed: $error');
                        if (mounted) {
                          setState(() => _isLoggingOut = false);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Logout failed. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recordMobileLocation(String action, int? userId) async {
    if (userId == null || userId <= 0) return;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
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
      await ApiService.recordMobileLocation(
        action: action,
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (error) {
      debugPrint('Mobile GPS $action failed: $error');
    }
  }

  Widget _buildHeader() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final formattedDate = DateFormatter.formatDate(_currentTime);
    final formattedTime = DateFormat('h:mm a').format(_currentTime);

    return Container(
      margin: padding,
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 14 : 18,
        isSmallScreen ? 14 : 18,
        isSmallScreen ? 14 : 18,
        isSmallScreen ? 16 : 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF123D74),
            Color(0xFF1764AC),
            Color(0xFF2585D8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1764AC).withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: isLoading
                    ? const SizedBox(
                        height: 62,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: isSmallScreen ? 22 : 26,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.15),
                                  backgroundImage: profilePictureUrl != null
                                      ? NetworkImage(profilePictureUrl!)
                                      : null,
                                  child: profilePictureUrl == null
                                      ? const Icon(
                                          Icons.person_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(
                                      BorderSide(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                            context, 11),
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  technicianName.isNotEmpty
                                      ? technicianName
                                      : 'Technician',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                            context, 18),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    technicianCode.isNotEmpty
                                        ? 'ID $technicianCode'
                                        : 'Technician',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper
                                          .getResponsiveFontSize(context, 10.5),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 10),
              _buildHeaderAction(
                icon: Icons.chat_bubble_rounded,
                badge: unreadChatCount,
                onTap: _openChat,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(width: 8),
              _buildHeaderAction(
                icon: Icons.notifications_rounded,
                badge: technicianNotifications.length,
                onTap: _openNotifications,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (context) => Container(
                  width: isSmallScreen ? 40 : 44,
                  height: isSmallScreen ? 40 : 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.menu_rounded,
                      size: isSmallScreen ? 20 : 22,
                      color: Colors.white,
                    ),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildCompactStatusChip(
                        icon: Icons.calendar_today_rounded,
                        label: formattedDate,
                      ),
                      _buildCompactStatusChip(
                        icon: Icons.access_time_rounded,
                        label: formattedTime,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: _isRefreshing
                            ? const CircularProgressIndicator(
                                strokeWidth: 1.6,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(width: 6),
                      ValueListenableBuilder<int>(
                        valueListenable: _refreshCountdown,
                        builder: (context, secondsLeft, _) => Text(
                          _isRefreshing
                              ? 'Refreshing'
                              : 'Refresh ${secondsLeft}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required int badge,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isSmallScreen ? 40 : 44,
          height: isSmallScreen ? 40 : 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              icon,
              size: isSmallScreen ? 18 : 20,
              color: Colors.white,
            ),
            onPressed: onTap,
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactStatusChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding.left),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1764AC),
                  Color(0xFF2476C9),
                  Color(0xFF38A0E8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1764AC).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Today overview'),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t('Jobs, payments, and service flow in one place.'),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 12),
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.work_outline_rounded,
                        color: const Color(0xFF2476C9),
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _t('Job History'),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF172B45),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 18),
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: _t('Pending'),
                        value: stats.pending.toString(),
                        color: const Color(0xFFE88A25),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: _t('Completed'),
                        value: stats.completed.toString(),
                        color: const Color(0xFF328A4A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.payment_rounded,
                        color: const Color(0xFF2476C9),
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _t('Payment History'),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF172B45),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 18),
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: _t('Online'),
                        value: stats.online.toInt().toString(),
                        color: const Color(0xFF328A4A),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: _t('Cash'),
                        value: stats.cash.toInt().toString(),
                        color: const Color(0xFF2476C9),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: ResponsiveStatsCard(
                        label: _t('Cash Pending'),
                        value: stats.cashPending.toInt().toString(),
                        color: const Color(0xFFE88A25),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyJobsSection() {
    final horizontalPadding = ResponsiveHelper.getScreenPadding(context).left;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D3553).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SurveyJobsScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF2476C9),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Survey Jobs'),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 17),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF172B45),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        surveyJobsError != null
                            ? _t('Unable to load survey jobs')
                            : _t('Assigned surveys'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isLoadingSurveyJobs)
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Text(
                    '${surveyJobs.length}',
                    style: const TextStyle(
                      color: Color(0xFF2476C9),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7890A8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobSection() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding.left),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t('My Jobs'),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF172B45),
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1764AC), Color(0xFF2476C9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TomorrowJobsScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.event,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _t('Tomorrow'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${myJobs.length}/${jobVisibility['unlimited'] == true ? 'All' : jobVisibility['limit'] ?? 1}',
                      style: TextStyle(
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2476C9),
                      ),
                    ),
                  ),
                  if ((jobVisibility['locked_count'] as int? ?? 0) > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E6),
                        border: Border.all(color: const Color(0xFFE5DAC6)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 18, color: Color(0xFF2476C9)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${jobVisibility['locked_count']} more ${jobVisibility['locked_count'] == 1 ? 'job' : 'jobs'} locked today. Complete or cancel a job to unlock the next.',
                              style: const TextStyle(
                                color: Color(0xFF6E685C),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          if (myJobs.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.work_outline, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _t('No jobs assigned yet'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...myJobs.map((job) {
              // Format the booking/scheduled time (when customer booked the service)
              String displayTime = _t('Not scheduled');
              if (job.scheduledDate != null) {
                displayTime = DateFormat('hh:mm a').format(job.scheduledDate!);
              }

              // Convert Job to JobModel for JobCard widget
              final jobModel = JobModel(
                id: job.id.toString(),
                name: job.customerName,
                address: job.address,
                service: job.service,
                treatment: job.treatment ?? 'N/A',
                flatSize: job.flatSize,
                area: '${job.city}, ${job.state}',
                time: displayTime, // Show booking/scheduled time
                date: job.scheduledDate != null
                    ? DateFormatter.formatDate(job.scheduledDate!)
                    : _t('Not scheduled'),
                paidType: 'Pending',
                amount: job.amount ?? 0,
                note: job.jobNotes,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildJobCard(jobModel, job),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildJobCard(JobModel jobModel, Job job) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusText;

    switch (job.status) {
      case 'rescheduled':
        statusColor = const Color(0xFF2476C9);
        statusBgColor = const Color(0xFFEAF3FC);
        statusIcon = Icons.schedule;
        statusText = _t('Rescheduled');
        break;
      case 'in_progress':
        statusColor = const Color(0xFF2476C9);
        statusBgColor = const Color(0xFFEAF3FC);
        statusIcon = Icons.work;
        statusText = _t('In Progress');
        break;
      case 'completed':
        statusColor = const Color(0xFF328A4A);
        statusBgColor = const Color(0xFFE8F4EB);
        statusIcon = Icons.check_circle;
        statusText = _t('Completed');
        break;
      default:
        statusColor = const Color(0xFFE88A25);
        statusBgColor = const Color(0xFFFFF1E0);
        statusIcon = Icons.assignment;
        statusText = _t('Assigned');
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(
              job: jobModel,
              jobData: job,
            ),
          ),
        );
        if (result == true) {
          _loadJobs();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
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
              color: const Color(0xFF1D3553).withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${jobModel.time}    ${jobModel.date}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172B45),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: job.isGrabbed
                            ? const Color(0xFFE8F4EB)
                            : const Color(0xFFFFF1E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            job.isGrabbed
                                ? Icons.play_circle_fill
                                : Icons.pending_actions,
                            size: 14,
                            color: job.isGrabbed
                                ? const Color(0xFF328A4A)
                                : const Color(0xFFE88A25),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _t(job.isGrabbed ? 'Started' : 'Ready to Start'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: job.isGrabbed
                                  ? const Color(0xFF328A4A)
                                  : const Color(0xFFE88A25),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.complaintId != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.report_problem,
                              size: 14,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _t('COMPLAINT'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildJobInfoRow(_t('Name:'), jobModel.name),
            const SizedBox(height: 8),
            _buildJobInfoRow(_t('Address:'), jobModel.address),
            const SizedBox(height: 8),
            _buildJobInfoRow(_t('Service:'), jobModel.service),
            const SizedBox(height: 8),
            _buildJobInfoRow(_t('Treatment:'), jobModel.treatment),
            const SizedBox(height: 8),
            _buildJobInfoRow(_t('Area:'), jobModel.area),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildJobActionButton(
                    icon: Icons.call,
                    label: _t('Call'),
                    color: const Color(0xFF328A4A),
                    onPressed: () => _makePhoneCall(job),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildJobActionButton(
                    icon: Icons.map,
                    label: _t('Map'),
                    color: const Color(0xFF2476C9),
                    onPressed: () => _openJobMap(job),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildJobActionButton(
                    icon: Icons.support_agent,
                    label: _t('Call Marketing'),
                    color: const Color(0xFFE88A25),
                    onPressed: () => _makeMarketingCall(job),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildJobActionButton(
                    icon: job.isGrabbed
                        ? Icons.visibility
                        : Icons.play_circle_fill,
                    label: _t(job.isGrabbed ? 'View Details' : 'Start Job'),
                    color: job.isGrabbed
                        ? const Color(0xFF1C5E9E)
                        : const Color(0xFF155FA8),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailScreen(
                            job: jobModel,
                            jobData: job,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadJobs();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildJobActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 17),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(Job job) async {
    final phone = job.phone.trim();
    if (phone.isEmpty) {
      _showActionError(_t('No customer phone number is available'));
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showActionError(_t('Unable to open the phone app'));
    }
  }

  Future<void> _makeMarketingCall(Job job) async {
    final phone = job.marketingUserPhone?.trim() ?? '';
    if (phone.isEmpty) {
      _showActionError(_t('No marketing phone number is available'));
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showActionError(_t('Unable to open the phone app'));
    }
  }

  Future<void> _openJobMap(Job job) async {
    final address = job.address.trim();
    if (address.isEmpty) {
      _showActionError(_t('No map location is available'));
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showActionError(_t('Unable to open Google Maps'));
    }
  }

  void _showActionError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showLanguageDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('Choose language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(dialogContext, 'en', 'English'),
            _languageOption(dialogContext, 'hi', 'हिन्दी'),
            _languageOption(dialogContext, 'mr', 'मराठी'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
    BuildContext dialogContext,
    String languageCode,
    String languageName,
  ) {
    final isSelected = AppLanguage.instance.locale.languageCode == languageCode;

    return SimpleDialogOption(
      onPressed: () async {
        await AppLanguage.instance.setLanguage(languageCode);
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      },
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 12),
          Text(languageName),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final menuItems = <Widget>[
      MenuButton(
        icon: Icons.language,
        label: _t('Language'),
        onTap: _showLanguageDialog,
      ),
      MenuButton(
        icon: Icons.person,
        label: _t('Profile'),
        color: Colors.blue[700]!,
        onTap: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
          await _loadUserData();
        },
      ),
      MenuButton(
        icon: Icons.event_available,
        label: _t('Leave'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveApplyScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.assignment_outlined,
        label: _t('Survey Jobs'),
        color: Colors.cyan[800]!,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SurveyJobsScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.receipt_long,
        label: _t('Expense'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpenseScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.local_gas_station_outlined,
        label: _t('Petrol Allowance'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PetrolAllowanceScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.speed,
        label: _t('Start Km'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KilometerScreen(isStart: true),
            ),
          );
        },
      ),
      MenuButton(
        icon: Icons.location_on,
        label: _t('End Km'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KilometerScreen(isStart: false),
            ),
          );
        },
      ),
      MenuButton(
        icon: Icons.science,
        label: _t('Chem In'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChemicalScreen(isIn: true),
            ),
          );
        },
      ),
      MenuButton(
        icon: Icons.science_outlined,
        label: _t('Chem Out'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChemicalScreen(isIn: false),
            ),
          );
        },
      ),
      MenuButton(
        icon: Icons.assignment,
        label: _t('Advance'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdvanceApplyScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.account_balance_wallet,
        label: _t('Cash'),
        color: Colors.green[700]!,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CashSubmissionScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.business,
        label: _t('Branches'),
        color: Colors.blue[700]!,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BranchesScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.help,
        label: _t('Help'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpScreen()),
          );
        },
      ),
      MenuButton(
        icon: Icons.logout,
        label: _t('Logout'),
        color: Colors.red[700]!,
        onTap: () {
          _showLogoutDialog();
        },
      ),
    ];

    return Drawer(
      backgroundColor: const Color(0xFFF4F7FF),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B3D8C),
                    Color(0xFF2E6CDE),
                    Color(0xFF5EA7FF)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        backgroundImage: profilePictureUrl != null
                            ? NetworkImage(profilePictureUrl!)
                            : null,
                        child: profilePictureUrl == null
                            ? const Icon(Icons.person,
                                size: 30, color: Colors.white)
                            : null,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _t('Menu'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    technicianName.isNotEmpty
                        ? technicianName
                        : _t('Technician'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (technicianCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID $technicianCode',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: menuItems,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
