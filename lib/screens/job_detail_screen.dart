import 'package:flutter/material.dart' hide Text;
import '../widgets/localized_text.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';
import '../models/job.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'payment_screen.dart';
import 'before_photos_screen.dart';
import 'after_photos_screen.dart';
import 'customer_signature_screen.dart';
import 'addon_service_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  final Job? jobData; // Add this to pass the full Job object

  const JobDetailScreen({super.key, required this.job, this.jobData});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool get isCoTechnician => widget.jobData?.isPrimaryTechnician == false;

  String jobStartTime = '';
  int allocatedMinutes = 45;
  bool isGrabbed = false;
  bool isGrabbing = false;
  bool isJobStarted = false;
  bool isStarting = false;
  bool isClosingJob = false; // Add loading state for close job
  bool isSavingTechnicianNote = false;
  DateTime? jobStartDateTime;
  Job? updatedJobData; // Store updated job data
  final TextEditingController _technicianNoteController =
      TextEditingController();
  List<Map<String, dynamic>> _technicianNoteHistory = [];

  // Workflow state tracking
  bool beforePhotosUploaded = false;
  bool afterPhotosUploaded = false;
  bool signatureUploaded = false;

  // Invoice download state
  bool isDownloadingInvoice = false;

  @override
  void initState() {
    super.initState();
    updatedJobData = widget.jobData;
    _technicianNoteHistory = List<Map<String, dynamic>>.from(
        widget.jobData?.technicianNoteHistory ?? []);
    // Check if job is already grabbed and started
    if (widget.jobData != null) {
      isGrabbed = widget.jobData!.isGrabbed;
      isJobStarted = widget.jobData!.jobStartTime != null;
      jobStartDateTime = widget.jobData!.jobStartTime;

      // Get time allocated from job data, default to 45 if not set
      allocatedMinutes = widget.jobData!.timeAllocated ?? 45;

      if (jobStartDateTime != null) {
        jobStartTime = DateFormat('hh:mm a').format(jobStartDateTime!);
      }
    }
    _loadWorkflowState();
  }

  @override
  void dispose() {
    _technicianNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkflowState() async {
    final prefs = await SharedPreferences.getInstance();
    final jobId = widget.job.id;
    setState(() {
      beforePhotosUploaded = prefs.getBool('before_photos_$jobId') ?? false;
      afterPhotosUploaded = prefs.getBool('after_photos_$jobId') ?? false;
      signatureUploaded = prefs.getBool('signature_$jobId') ?? false;
    });
  }

  Future<void> _saveWorkflowState() async {
    final prefs = await SharedPreferences.getInstance();
    final jobId = widget.job.id;
    await prefs.setBool('before_photos_$jobId', beforePhotosUploaded);
    await prefs.setBool('after_photos_$jobId', afterPhotosUploaded);
    await prefs.setBool('signature_$jobId', signatureUploaded);
  }

  Future<void> _markBeforePhotosUploaded() async {
    setState(() {
      beforePhotosUploaded = true;
    });
    await _saveWorkflowState();
  }

  Future<void> _markAfterPhotosUploaded() async {
    setState(() {
      afterPhotosUploaded = true;
    });
    await _saveWorkflowState();
  }

  Future<void> _markSignatureUploaded() async {
    setState(() {
      signatureUploaded = true;
    });
    await _saveWorkflowState();
  }

  Future<void> _refreshJobData() async {
    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;

      if (technicianId == 0) {
        throw Exception('Invalid technician ID');
      }

      final result = await ApiService.getMyJobs(technicianId);

      if (result['success'] == true && result['data'] != null) {
        final jobs = (result['data'] as List)
            .map((jobJson) => Job.fromJson(jobJson))
            .toList();

        // Find the current job in the refreshed list
        final jobId = int.tryParse(widget.job.id) ?? 0;
        final refreshedJob = jobs.firstWhere(
          (job) => job.id == jobId,
          orElse: () => updatedJobData!,
        );

        setState(() {
          updatedJobData = refreshedJob;
          _technicianNoteHistory = List<Map<String, dynamic>>.from(
            refreshedJob.technicianNoteHistory,
          );
          // Update allocated minutes from refreshed data
          allocatedMinutes = refreshedJob.timeAllocated ?? 45;
        });
      }
    } catch (e) {
      // Silently fail - user can still proceed with old data
      debugPrint('Failed to refresh job data: $e');
    }
  }

  Future<void> _handleStartJob() async {
    setState(() {
      isStarting = true;
    });

    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (technicianId == 0 || jobId == 0) {
        throw Exception('Invalid technician or job ID');
      }

      if (!isGrabbed) {
        final grabResult = await ApiService.grabJob(jobId, technicianId);
        if (grabResult['success'] != true) {
          throw Exception(grabResult['message'] ?? 'Failed to accept job');
        }
      }

      final result = await ApiService.startJob(jobId, technicianId);

      if (!mounted) return;

      if (result['success'] == true) {
        final startTime = result['data']['job_start_time'];
        final parsedTime = DateTime.parse(startTime).toLocal();

        setState(() {
          isGrabbed = true;
          isJobStarted = true;
          jobStartDateTime = parsedTime;
          jobStartTime = DateFormat('hh:mm a').format(parsedTime);
          isStarting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          isStarting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to start job'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isStarting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCloseJob() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Job'),
        content: const Text(
          'Are you sure you want to close this job? The job status will be updated to completed and you will be redirected to the home page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
            ),
            child: const Text('Close Job'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isClosingJob = true;
    });

    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (technicianId == 0 || jobId == 0) {
        throw Exception('Invalid technician or job ID');
      }

      final result = await ApiService.closeJob(jobId, technicianId);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job closed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to home page
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          isClosingJob = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to close job'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isClosingJob = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGrabJob() async {
    setState(() {
      isGrabbing = true;
    });

    try {
      final userData = await AuthService.getUserData();
      final technicianId = userData['db_id'] ?? 0;
      final jobId = int.tryParse(widget.job.id) ?? 0;

      if (technicianId == 0 || jobId == 0) {
        throw Exception('Invalid technician or job ID');
      }

      final result = await ApiService.grabJob(jobId, technicianId);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          isGrabbed = true;
          isGrabbing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job grabbed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          isGrabbing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to grab job'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGrabbing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = updatedJobData?.phone ?? widget.jobData?.phone ?? '';
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openDirections() async {
    // Priority 1: Use map_location if available (Google Maps link from marketing team)
    final mapLocation =
        updatedJobData?.mapLocation ?? widget.jobData?.mapLocation;

    if (mapLocation != null && mapLocation.isNotEmpty) {
      // If it's already a URL, use it directly
      final Uri mapsUri = Uri.parse(mapLocation);
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Priority 2: Fallback to address search
    final address = updatedJobData?.address ??
        widget.jobData?.address ??
        widget.job.address;
    final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadInvoice() async {
    if (widget.jobData == null) return;

    setState(() {
      isDownloadingInvoice = true;
    });

    try {
      final userData = await AuthService.getUserData();

      final result = await ApiService.downloadJobInvoice(
        jobId: widget.jobData!.id,
        technicianId: userData['db_id'],
      );

      if (result['success'] == true) {
        // Open the download URL in browser
        final downloadUrl = result['download_url'];
        final Uri uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to download invoice'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isDownloadingInvoice = false;
      });
    }
  }

  Future<void> _viewInvoice() async {
    if (widget.jobData == null) return;

    try {
      final userData = await AuthService.getUserData();

      final result = await ApiService.viewJobInvoice(
        jobId: widget.jobData!.id,
        technicianId: userData['db_id'],
      );

      if (result['success'] == true) {
        // Open the view URL in browser
        final viewUrl = result['view_url'];
        final Uri uri = Uri.parse(viewUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to view invoice'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error viewing invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobInfo(),
                const SizedBox(height: 16),
                _buildPreviousJobHistory(),
                if (updatedJobData?.isTomorrowPreview != true) ...[
                  const SizedBox(height: 16),
                  _buildTechnicianNoteHistory(),
                ],
                const SizedBox(height: 24),
                _buildTimeAllocation(),
                const SizedBox(height: 24),
                _buildNote(),
                const SizedBox(height: 24),
                if (!isCoTechnician) ...[
                  _buildPaymentInfo(),
                  const SizedBox(height: 24),
                ],
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobInfo() {
    final job = updatedJobData ?? widget.jobData;

    String display(String? value) {
      final normalized = value?.trim() ?? '';
      return normalized.isEmpty ? 'N/A' : normalized;
    }

    String displayInt(int? value) => value == null ? 'N/A' : value.toString();
    final amountValue = job?.amount ?? widget.job.amount;

    if (job == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Phone', display(job.phone)),
          const SizedBox(height: 10),
          _buildInfoRow('Alternative Number', display(job.alternatePhone)),
          const SizedBox(height: 10),
          _buildInfoRow('Address', display(job.address)),
          const SizedBox(height: 10),
          _buildInfoRow('Location', display(job.locationName)),
          const SizedBox(height: 10),
          _buildInfoRow('Service', display(job.service)),
          const SizedBox(height: 10),
          _buildInfoRow('Flat Size', display(job.flatSize)),
          const SizedBox(height: 10),
          _buildInfoRow('Frequency', display(job.frequency)),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Warranty',
            job.warrantyDays == null ? 'N/A' : '${job.warrantyDays} days',
          ),
          const SizedBox(height: 10),
          _buildInfoRow('No. Of Visit', displayInt(job.numberOfServices)),
          const SizedBox(height: 10),
          _buildInfoRow('Amount', '₹${amountValue.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildInfoRow('Treatment', display(job.treatment)),
          const SizedBox(height: 10),
          _buildInfoRow('Marketing Note', display(job.marketingNotes)),
        ],
      ),
    );
  }

  Widget _buildPreviousJobHistory() {
    final job = updatedJobData ?? widget.jobData;
    final history = job?.previousJobHistory ?? const <Map<String, dynamic>>[];

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    String display(dynamic value) {
      final normalized = value?.toString().trim() ?? '';
      return normalized.isEmpty ? 'N/A' : normalized;
    }

    String displayDateTime(dynamic value) {
      if (value == null) return 'N/A';
      final normalized = value.toString();
      final parsed = DateTime.tryParse(normalized)?.toLocal();
      if (parsed == null) return normalized;
      if (normalized.length == 10) {
        return DateFormat('dd MMM yyyy').format(parsed);
      }
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    }

    String displayTime(dynamic value) {
      if (value == null) return 'N/A';
      final normalized = value.toString();
      final parsed = DateTime.tryParse(normalized)?.toLocal();
      if (parsed != null) {
        return DateFormat('hh:mm a').format(parsed);
      }
      final parsedTime = DateTime.tryParse('1970-01-01 $normalized');
      return parsedTime == null
          ? normalized
          : DateFormat('hh:mm a').format(parsedTime);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'Previous job history (${history.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        children: history.map((previousJob) {
          final chemicalUsage = previousJob['chemical_usage'] is List
              ? (previousJob['chemical_usage'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
              : <Map<String, dynamic>>[];
          final completedAt = previousJob['previous_job_completed_date'] ??
              previousJob['previous_job_end_time'];
          final scheduledDate = previousJob['previous_job_scheduled_date'];
          final scheduledTime = previousJob['previous_job_scheduled_time'];
          final scheduledAt = [
            if (scheduledDate != null && scheduledDate.toString().isNotEmpty)
              displayDateTime(scheduledDate),
            if (scheduledTime != null && scheduledTime.toString().isNotEmpty)
              displayTime(scheduledTime),
          ].join(', ');

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildInfoGroup(
              title: 'Job #${display(previousJob['previous_job_id'])}',
              icon: Icons.history,
              children: [
                _buildInfoRow(
                  'Technician',
                  display(previousJob['previous_technician_name']),
                ),
                _buildInfoRow(
                  'Treatment Type',
                  display(previousJob['previous_treatment_type']),
                ),
                if (previousJob['previous_technician_code'] != null)
                  _buildInfoRow(
                    'Technician Code',
                    display(previousJob['previous_technician_code']),
                  ),
                if (scheduledAt.isNotEmpty)
                  _buildInfoRow('Previously scheduled', scheduledAt),
                if (completedAt != null)
                  _buildInfoRow('Completed', displayDateTime(completedAt)),
                if (previousJob['previous_job_start_time'] != null)
                  _buildInfoRow(
                    'Started',
                    displayDateTime(previousJob['previous_job_start_time']),
                  ),
                if (previousJob['previous_job_end_time'] != null)
                  _buildInfoRow(
                    'Ended',
                    displayTime(previousJob['previous_job_end_time']),
                  ),
                _buildInfoRow(
                  'Technician Note',
                  display(previousJob['previous_technician_notes']),
                ),
                if ((previousJob['previous_job_notes']?.toString() ?? '')
                    .trim()
                    .isNotEmpty)
                  _buildInfoRow(
                    'Job Note',
                    display(previousJob['previous_job_notes']),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Chemicals used',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                if (chemicalUsage.isEmpty)
                  const Text(
                    'No chemical usage recorded for this job.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  )
                else
                  ...chemicalUsage.map((usage) {
                    final quantity = display(usage['quantity']);
                    final unit = display(usage['chemical_unit']);
                    return _buildInfoRow(
                      display(usage['chemical_name']),
                      '$quantity $unit',
                    );
                  }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTechnicianNoteHistory() {
    Future<void> saveNote() async {
      final noteText = _technicianNoteController.text.trim();
      if (noteText.isEmpty || isSavingTechnicianNote) return;

      setState(() {
        isSavingTechnicianNote = true;
      });

      try {
        final userData = await AuthService.getUserData();
        final technicianId = userData['db_id'] ?? 0;
        final jobId = int.tryParse(widget.job.id) ?? 0;
        if (technicianId == 0 || jobId == 0) {
          throw Exception('Invalid technician or job ID');
        }

        final result = await ApiService.addTechnicianJobNote(
          jobId: jobId,
          technicianId: technicianId,
          note: noteText,
        );
        if (!mounted) return;

        if (result['success'] != true || result['data'] is! Map) {
          throw Exception(
              result['message'] ?? 'Failed to save technician note');
        }

        setState(() {
          _technicianNoteHistory.add(
            Map<String, dynamic>.from(result['data'] as Map),
          );
          _technicianNoteController.clear();
          isSavingTechnicianNote = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experience note saved for future technicians.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          isSavingTechnicianNote = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    String noteDate(dynamic value) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed == null
          ? ''
          : DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technician Experience Notes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Notes saved here stay with the job so the next assigned technician can learn from your experience.',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          if (_technicianNoteHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._technicianNoteHistory.map((entry) {
              final date = noteDate(entry['created_at']);
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        entry['technician_name']?.toString() ?? 'Technician',
                        if (date.isNotEmpty) date,
                      ].join(' • '),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(entry['note']?.toString() ?? ''),
                  ],
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'No technician experience notes yet.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _technicianNoteController,
            maxLines: 4,
            maxLength: 5000,
            decoration: const InputDecoration(
              labelText: 'Share your experience',
              hintText: 'Add useful details for the next technician...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isSavingTechnicianNote ? null : saveNote,
              icon: isSavingTechnicianNote
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSavingTechnicianNote ? 'Saving...' : 'Save note'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAllocation() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: isJobStarted ? Colors.green[700]! : Colors.indigo[900]!,
              borderRadius: 14,
            ),
            child: Column(
              children: [
                const Text(
                  'JOB START',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isJobStarted ? jobStartTime : 'Not Started',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: NeumorphicStyle.coloredNeumorphicDecoration(
              color: Colors.indigo[900]!,
              borderRadius: 14,
            ),
            child: Column(
              children: [
                const Text(
                  'ALLOCATE TIME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$allocatedMinutes Minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNote() {
    // Only show note section if there's an actual note
    if (widget.job.note == null || widget.job.note!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 14),
      child: Row(
        children: [
          Text(
            'Note:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.job.note!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    // Use jobData if available (has full payment info), otherwise fall back to JobModel
    final hasFullJobData = widget.jobData != null;

    if (hasFullJobData) {
      final job = widget.jobData!;

      // For recurring jobs with carry forward, get updated payment data
      if (job.isRecurringSeries && job.hasCarryForward) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getCarryForwardPaymentData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration:
                    NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              // Fall back to job data if API fails
              return _buildStandardPaymentInfo(job);
            }

            final paymentData = snapshot.data!;
            return _buildCarryForwardPaymentInfo(job, paymentData);
          },
        );
      } else {
        // Standard job payment display
        return _buildStandardPaymentInfo(job);
      }
    } else {
      // Fall back to basic JobModel display
      return _buildBasicPaymentInfo();
    }
  }

  Future<Map<String, dynamic>> _getCarryForwardPaymentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getInt('db_id') ?? 0;

      if (technicianId == 0) {
        throw Exception('No technician ID available');
      }

      final result = await ApiService.getPaymentSummary(
        jobId: int.parse(widget.job.id),
        technicianId: technicianId,
      );

      if (result['success'] == true && result['data'] != null) {
        return result['data'];
      } else {
        throw Exception('Failed to get payment summary');
      }
    } catch (e) {
      debugPrint('Error getting carry forward payment data: $e');
      rethrow;
    }
  }

  Widget _buildCarryForwardPaymentInfo(
      Job job, Map<String, dynamic> paymentData) {
    final totalAmount = (paymentData['total_amount'] ?? 0.0).toDouble();
    final totalPaid = (paymentData['total_paid'] ?? 0.0).toDouble();
    final pendingAmount = (paymentData['pending_amount'] ?? 0.0).toDouble();
    final showPaymentOption = paymentData['show_payment_option'] ?? true;
    final summaryMessage = paymentData['summary_message'] ?? '';

    // Determine payment status display based on carry forward data
    String paymentStatusText;
    Color paymentStatusColor;

    if (pendingAmount <= 0) {
      paymentStatusText = 'PAID';
      paymentStatusColor = Colors.green;
    } else if (totalPaid > 0) {
      paymentStatusText = 'PARTIAL';
      paymentStatusColor = Colors.orange;
    } else {
      paymentStatusText = 'PENDING';
      paymentStatusColor = Colors.red;
    }

    // Special handling for recurring jobs with carry forward
    if (job.isRecurringSeries && !showPaymentOption && pendingAmount <= 0) {
      paymentStatusText = 'ALREADY PAID';
      paymentStatusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          // Show carry forward indicator for recurring jobs with enhanced highlighting
          if (job.isRecurringSeries && job.hasCarryForward) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: totalPaid > 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: totalPaid > 0
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.blue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                      totalPaid > 0
                          ? Icons.account_balance_wallet
                          : Icons.repeat,
                      size: 18,
                      color:
                          totalPaid > 0 ? Colors.green[700] : Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      totalPaid > 0
                          ? 'Recurring Job ${job.recurringSequence}/${job.totalRecurringJobs} - Carry Forward Payment Active'
                          : 'Recurring Job ${job.recurringSequence}/${job.totalRecurringJobs}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: totalPaid > 0
                            ? Colors.green[700]
                            : Colors.blue[700],
                      ),
                    ),
                  ),
                  if (totalPaid > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Payment Mode: ${job.paymentMode.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: paymentStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: paymentStatusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Status: $paymentStatusText',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: paymentStatusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Total: ₹${totalAmount.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Paid: ₹${totalPaid.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Pending: ₹${pendingAmount.toInt()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: pendingAmount > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Show carry forward summary message if available
          if (summaryMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summaryMessage,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandardPaymentInfo(Job job) {
    // Determine payment status display
    String paymentStatusText;
    Color paymentStatusColor;

    switch (job.paymentStatus) {
      case 'paid':
        paymentStatusText = 'PAID';
        paymentStatusColor = Colors.green;
        break;
      case 'partial':
        paymentStatusText = 'PARTIAL';
        paymentStatusColor = Colors.orange;
        break;
      case 'pending':
      default:
        paymentStatusText = 'PENDING';
        paymentStatusColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Payment Mode: ${job.paymentMode.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: paymentStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: paymentStatusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Status: $paymentStatusText',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: paymentStatusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Total: ₹${job.totalAmount.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Paid: ₹${job.paidAmount.toInt()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: NeumorphicStyle.neumorphicInsetDecoration(
                      borderRadius: 10),
                  child: Text(
                    'Pending: ₹${job.pendingAmount.toInt()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: job.pendingAmount > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicPaymentInfo() {
    // Fall back to basic JobModel display
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration:
                  NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 10),
              child: Text(
                'Payment Mode: ${widget.job.paidType.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration:
                NeumorphicStyle.neumorphicInsetDecoration(borderRadius: 10),
            child: Text(
              'Amount: ₹${widget.job.amount.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // If job is not grabbed, show the start action directly.
    if (!isGrabbed) {
      return Column(
        children: [
          _buildStartButton(),
          const SizedBox(height: 16),
          _buildInfoBox(
            'Tap START JOB to accept and begin this service',
            Colors.indigo,
          ),
        ],
      );
    }

    // If job is grabbed but not started, show Call, Directions, and Start only
    if (!isJobStarted) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildNeumorphicButton(
                  'CALL',
                  Colors.green[700]!,
                  _makePhoneCall,
                  icon: Icons.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNeumorphicButton(
                  'DIRECTIONS',
                  Colors.blue[700]!,
                  _openDirections,
                  icon: Icons.directions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNeumorphicButton(
            'START JOB',
            Colors.indigo[900]!,
            _handleStartJob,
            icon: Icons.play_arrow,
            isLoading: isStarting,
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            'Step 1: Click START JOB to begin the service',
            Colors.blue,
          ),
        ],
      );
    }

    // Step 2: After start, show Before Photos button only
    if (!beforePhotosUploaded) {
      return Column(
        children: [
          _buildNeumorphicButton(
            'Upload Before Photos',
            Colors.orange[600]!,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BeforePhotosScreen(
                    job: widget.job,
                    jobData: updatedJobData ?? widget.jobData,
                  ),
                ),
              );
              // Mark as uploaded when returning from screen
              if (result == true || mounted) {
                await _markBeforePhotosUploaded();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Before photos uploaded! Now upload after photos.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: Icons.camera_alt,
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            'Step 2: Upload BEFORE photos to continue',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          // Manual mark button for testing
          TextButton(
            onPressed: () async {
              await _markBeforePhotosUploaded();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Before photos marked as uploaded'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Mark Before Photos as Uploaded'),
          ),
        ],
      );
    }

    // Step 3: After before photos, show After Photos and Signature buttons
    if (!afterPhotosUploaded || !signatureUploaded) {
      return Column(
        children: [
          if (!afterPhotosUploaded)
            Column(
              children: [
                _buildNeumorphicButton(
                  'Upload After Photos',
                  Colors.green[600]!,
                  () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AfterPhotosScreen(
                          job: widget.job,
                          jobData: updatedJobData ?? widget.jobData,
                        ),
                      ),
                    );
                    if (result == true || mounted) {
                      await _markAfterPhotosUploaded();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('After photos uploaded!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icons.camera_alt,
                ),
                const SizedBox(height: 12),
                // Manual mark button
                TextButton(
                  onPressed: () async {
                    await _markAfterPhotosUploaded();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('After photos marked as uploaded'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Mark After Photos as Uploaded'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          if (!signatureUploaded)
            Column(
              children: [
                _buildNeumorphicButton(
                  'Customer Signature',
                  Colors.blue[600]!,
                  () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerSignatureScreen(
                          job: widget.job,
                        ),
                      ),
                    );
                    if (result == true || mounted) {
                      await _markSignatureUploaded();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signature uploaded!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icons.draw,
                ),
                const SizedBox(height: 12),
                // Manual mark button
                TextButton(
                  onPressed: () async {
                    await _markSignatureUploaded();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signature marked as uploaded'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Mark Signature as Uploaded'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          _buildInfoBox(
            'Step 3: Upload AFTER photos and get customer signature',
            Colors.green,
          ),
        ],
      );
    }

    // Co-technicians finish the shared job without entering the payment flow.
    if (isCoTechnician) {
      return Column(
        children: [
          _buildNeumorphicButton(
            'COMPLETE JOB',
            Colors.purple[700]!,
            _handleCloseJob,
            icon: Icons.check_circle_outline,
            isLoading: isClosingJob,
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            'Co-Technician: tap COMPLETE JOB to finish the work.',
            Colors.blue,
          ),
        ],
      );
    }

    // Step 4: After all uploads, show Add-on Services and Payment
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNeumorphicButton(
                'ADD ON SERVICE',
                Colors.red[700]!,
                () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddonServiceScreen(
                        job: widget.job,
                      ),
                    ),
                  );

                  if (result == true && mounted) {
                    await _refreshJobData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Add-on services updated! Total amount refreshed.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                icon: Icons.add_circle,
              ),
            ),
            const SizedBox(width: 12),
            // Show payment button only if payment is not fully paid
            if (widget.jobData == null ||
                (widget.jobData!.paymentStatus != 'paid' ||
                    widget.jobData!.pendingAmount > 0))
              Expanded(
                child: _buildNeumorphicButton(
                  'PAYMENT OPTION',
                  Colors.indigo[900]!,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          job: widget.job,
                          jobData: updatedJobData ?? widget.jobData,
                        ),
                      ),
                    );
                  },
                  icon: Icons.payment,
                ),
              )
            else
              // Show payment status and invoice options when fully paid
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[700], size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'PAYMENT COMPLETE',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Invoice download buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildNeumorphicButton(
                            'Download PDF',
                            Colors.green[600]!,
                            _downloadInvoice,
                            icon: Icons.download,
                            isLoading: isDownloadingInvoice,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNeumorphicButton(
                            'View & Share',
                            Colors.blue[600]!,
                            _viewInvoice,
                            icon: Icons.visibility,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        // Show Close Job button when:
        // (a) recurring job with payment fully collected, or
        // (b) zero-cost job (warranty/complaint) — no payment needed
        if (widget.jobData != null &&
            ((widget.jobData!.isRecurringSeries &&
                    widget.jobData!.paymentStatus == 'paid' &&
                    widget.jobData!.pendingAmount == 0) ||
                (widget.jobData!.totalAmount == 0 &&
                    widget.jobData!.pendingAmount == 0))) ...[
          const SizedBox(height: 16),
          _buildNeumorphicButton(
            'COMPLETE JOB',
            Colors.purple[700]!,
            _handleCloseJob,
            icon: Icons.check_circle_outline,
            isLoading: isClosingJob,
          ),
        ],
        const SizedBox(height: 16),
        _buildInfoBox(
          widget.jobData != null &&
                  ((widget.jobData!.paymentStatus == 'paid' &&
                          widget.jobData!.pendingAmount == 0) ||
                      (widget.jobData!.totalAmount == 0 &&
                          widget.jobData!.pendingAmount == 0))
              ? widget.jobData!.totalAmount == 0
                  ? 'Zero-cost job. Tap COMPLETE JOB to close.'
                  : 'Payment completed! You can finish the job.'
              : 'Final Step: Add services and complete payment',
          widget.jobData != null &&
                  ((widget.jobData!.paymentStatus == 'paid' &&
                          widget.jobData!.pendingAmount == 0) ||
                      (widget.jobData!.totalAmount == 0 &&
                          widget.jobData!.pendingAmount == 0))
              ? Colors.green
              : Colors.purple,
        ),
      ],
    );
  }

  Widget _buildInfoBox(String message, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: Colors.indigo[800]!,
        borderRadius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isStarting ? null : _handleStartJob,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: isStarting
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'START JOB',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicButton(
      String label, Color color, VoidCallback onPressed,
      {IconData? icon, bool isLoading = false, bool isDisabled = false}) {
    return Container(
      decoration: NeumorphicStyle.coloredNeumorphicDecoration(
        color: isDisabled ? Colors.grey[400]! : color,
        borderRadius: 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading || isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildInfoGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF2563EB)),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 122,
          child: Text(
            '$label:',
            maxLines: 2,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.25,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              color: Color(0xFF172033),
            ),
          ),
        ),
      ],
    );
  }
}
