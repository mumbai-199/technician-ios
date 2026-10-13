import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../widgets/localized_text.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SurveyJobsScreen extends StatefulWidget {
  const SurveyJobsScreen({super.key});

  @override
  State<SurveyJobsScreen> createState() => _SurveyJobsScreenState();
}

class _SurveyJobsScreenState extends State<SurveyJobsScreen> {
  static const Color _primary = Color(0xFF0C4A78);

  List<Map<String, dynamic>> _surveys = [];
  int? _technicianId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final technicianId = await AuthService.getTechnicianId();
      if (technicianId == null || technicianId <= 0) {
        throw Exception('Technician account could not be identified.');
      }

      final result = await ApiService.getMySurveyJobs(technicianId);
      if (result['success'] != true || result['data'] is! List) {
        throw Exception(result['message'] ?? 'Could not load survey jobs.');
      }

      if (!mounted) return;
      setState(() {
        _technicianId = technicianId;
        _surveys = (result['data'] as List)
            .whereType<Map>()
            .map((lead) => Map<String, dynamic>.from(lead))
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openSurvey(Map<String, dynamic> lead) async {
    final technicianId = _technicianId;
    if (technicianId == null) return;

    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyJobFormScreen(
          lead: lead,
          technicianId: technicianId,
        ),
      ),
    );

    if (submitted == true) _loadSurveys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FB),
        foregroundColor: _primary,
        elevation: 0,
        title: const Text(
          'Survey Jobs',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: Text.translate(context, 'Refresh surveys'),
            onPressed: _loadSurveys,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSurveys,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _errorMessage != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 120),
                      _SurveyEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Surveys unavailable',
                        message: _errorMessage!,
                        actionLabel: 'Try again',
                        onAction: _loadSurveys,
                      ),
                    ],
                  )
                : _surveys.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 120),
                          _SurveyEmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'No survey jobs',
                            message: 'Assigned survey jobs will appear here.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _surveys.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final lead = _surveys[index];
                          return _SurveyLeadCard(
                            lead: lead,
                            onTap: () => _openSurvey(lead),
                          );
                        },
                      ),
      ),
    );
  }
}

class SurveyJobFormScreen extends StatefulWidget {
  final Map<String, dynamic> lead;
  final int technicianId;

  const SurveyJobFormScreen({
    super.key,
    required this.lead,
    required this.technicianId,
  });

  @override
  State<SurveyJobFormScreen> createState() => _SurveyJobFormScreenState();
}

class _SurveyJobFormScreenState extends State<SurveyJobFormScreen> {
  static const Color _ink = Color(0xFF173632);
  static const Color _muted = Color(0xFF7A8984);
  static const Color _canvas = Color(0xFFF6F5F0);
  static const Color _gold = Color(0xFFD6B878);
  static const OutlineInputBorder _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(15)),
    borderSide: BorderSide(color: Color(0xFFE3E6DF)),
  );
  static const List<String> _pestTypes = [
    'Cockroach',
    'Bedbugs',
    'Termites',
    'Rodents',
    'Ants',
    'Mosquitoes',
    'Flies',
    'Lizards',
    'Other',
  ];
  static const List<String> _treatments = [
    'Gel Treatment',
    'Residual Spray',
    'Fogging',
    'Drill - fill - seal',
    'Other',
  ];
  bool _isSubmitting = false;
  bool _isLoadingFlatSizes = true;
  bool _gstApplicable = false;
  String? _flatSizeError;
  List<String> _flatSizes = [];
  String? _selectedFlatSize;
  String? _propertyType;
  String? _infestationLevel;
  String? _serviceFrequency;
  DateTime? _surveyDate;
  TimeOfDay? _surveyTime;
  final Set<String> _selectedPests = {};
  final Set<String> _selectedTreatments = {};
  final List<Map<String, dynamic>> _evidencePhotos = [];
  final ImagePicker _imagePicker = ImagePicker();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  String? _savedSignature;
  final _areaSqftController = TextEditingController();
  final _quotationAmountController = TextEditingController();
  final Map<String, TextEditingController> _pestAmountControllers = {};
  final _gstPercentageController = TextEditingController();
  final _technicianNotesController = TextEditingController();
  final _affectedAreasController = TextEditingController();
  final _findingsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existingDetails = widget.lead['survey_details'];
    if (existingDetails is Map) {
      _propertyType = existingDetails['property_type']?.toString();
      _infestationLevel = existingDetails['infestation_level']?.toString();
      _serviceFrequency = existingDetails['service_frequency']?.toString();
      _areaSqftController.text = existingDetails['area_sqft']?.toString() ?? '';
      _quotationAmountController.text =
          existingDetails['quotation_amount']?.toString() ?? '';
      final gstApplicable = existingDetails['gst_applicable']?.toString();
      _gstApplicable = gstApplicable == 'true' || gstApplicable == '1';
      _gstPercentageController.text =
          existingDetails['gst_percentage']?.toString() ?? '';
      _technicianNotesController.text =
          existingDetails['technician_notes']?.toString() ?? '';
      _affectedAreasController.text =
          existingDetails['affected_areas']?.toString() ?? '';
      _findingsController.text = existingDetails['findings']?.toString() ?? '';
      final signature = existingDetails['customer_signature']?.toString();
      _savedSignature =
          signature == null || signature.isEmpty ? null : signature;
      final pests = existingDetails['target_pest_types'];
      if (pests is List) {
        _selectedPests.addAll(pests.map((item) => item.toString()));
      }
      final pestAmounts = existingDetails['pest_amounts'];
      if (pestAmounts is Map) {
        for (final entry in pestAmounts.entries) {
          final pest = entry.key.toString();
          if (_pestTypes.contains(pest)) {
            _pestAmountControllers[pest] = TextEditingController(
              text: entry.value?.toString() ?? '',
            );
          }
        }
      }
      for (final pest in _selectedPests) {
        _pestAmountControllers.putIfAbsent(
          pest,
          TextEditingController.new,
        );
      }
      final treatments = existingDetails['recommended_treatments'];
      if (treatments is List) {
        _selectedTreatments.addAll(treatments.map((item) => item.toString()));
      }
      final photos = existingDetails['evidence_photos'];
      if (photos is List) {
        _evidencePhotos.addAll(
          photos
              .whereType<Map>()
              .map((photo) => Map<String, dynamic>.from(photo)),
        );
      }
      final dateValue = existingDetails['schedule_date']?.toString();
      final timeValue = existingDetails['schedule_time']?.toString();
      if (dateValue != null && dateValue.isNotEmpty) {
        _surveyDate = DateTime.tryParse(dateValue);
      }
      if (timeValue != null && timeValue.isNotEmpty) {
        final timeParts = timeValue.split(':');
        if (timeParts.length >= 2) {
          _surveyTime = TimeOfDay(
            hour: int.tryParse(timeParts[0]) ?? 0,
            minute: int.tryParse(timeParts[1]) ?? 0,
          );
        }
      }
    }
    _loadFlatSizes();
  }

  Future<void> _loadFlatSizes() async {
    final result = await ApiService.getActiveFlatSizes();
    if (!mounted) return;

    if (result['success'] != true || result['data'] is! List) {
      setState(() {
        _isLoadingFlatSizes = false;
        _flatSizeError =
            (result['message'] ?? 'Could not load ERP flat sizes.').toString();
      });
      return;
    }

    final sizes = (result['data'] as List)
        .whereType<Map>()
        .map((size) => size['name']?.toString().trim() ?? '')
        .where((size) => size.isNotEmpty)
        .toList();
    final existingDetails = widget.lead['survey_details'];
    final existingDetailSize = existingDetails is Map
        ? existingDetails['flat_size']?.toString().trim()
        : null;
    final existingSize =
        (existingDetailSize?.isNotEmpty == true ? existingDetailSize : null) ??
            widget.lead['flat_size']?.toString().trim();

    setState(() {
      _flatSizes = sizes;
      _selectedFlatSize = existingSize != null && sizes.contains(existingSize)
          ? existingSize
          : null;
      _isLoadingFlatSizes = false;
    });
  }

  @override
  void dispose() {
    _areaSqftController.dispose();
    _quotationAmountController.dispose();
    for (final controller in _pestAmountControllers.values) {
      controller.dispose();
    }
    _gstPercentageController.dispose();
    _technicianNotesController.dispose();
    _affectedAreasController.dispose();
    _findingsController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _captureEvidencePhoto() async {
    if (_isSubmitting || _evidencePhotos.length >= 4) return;

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 55,
      );
      if (photo == null || !mounted) return;

      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Enable location services to geo-tag evidence photos.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to geo-tag photos.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _evidencePhotos.add({
          'image': base64Encode(bytes),
          'latitude': position.latitude,
          'longitude': position.longitude,
          'captured_at': DateTime.now().toIso8601String(),
        });
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _captureSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please capture the customer signature first.')),
      );
      return;
    }
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null || !mounted) return;
    setState(
        () => _savedSignature = 'data:image/png;base64,${base64Encode(bytes)}');
  }

  Future<void> _submitResult(String status) async {
    if (_isSubmitting) return;

    if (_selectedFlatSize == null ||
        _propertyType == null ||
        _infestationLevel == null ||
        _affectedAreasController.text.trim().isEmpty ||
        _surveyDate == null ||
        _surveyTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the property survey before submitting.'),
        ),
      );
      return;
    }

    final pestAmounts = <String, double>{};
    for (final pest in _selectedPests) {
      final amountText = _pestAmountControllers[pest]?.text.trim() ?? '';
      if (amountText.isEmpty) continue;
      final amount = double.tryParse(amountText);
      if (amount == null || !amount.isFinite || amount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enter a valid amount for $pest.')),
        );
        return;
      }
      pestAmounts[pest] = amount;
    }

    final quotationAmount = pestAmounts.isNotEmpty
        ? pestAmounts.values.reduce((total, amount) => total + amount)
        : double.tryParse(_quotationAmountController.text.trim());
    if (pestAmounts.isEmpty &&
        _quotationAmountController.text.trim().isNotEmpty) {
      if (quotationAmount == null ||
          !quotationAmount.isFinite ||
          quotationAmount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid estimate amount.')),
        );
        return;
      }
    }

    final gstPercentageText = _gstPercentageController.text.trim();
    final gstPercentage =
        _gstApplicable ? double.tryParse(gstPercentageText) : null;
    if (_gstApplicable &&
        (gstPercentage == null ||
            !gstPercentage.isFinite ||
            gstPercentage < 0 ||
            gstPercentage > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid GST percentage between 0 and 100.'),
        ),
      );
      return;
    }

    if (status == 'converted') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm conversion'),
          content: const Text(
            'This marks the lead as converted and automatically creates a draft quotation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.submitSurveyResult(
        technicianId: widget.technicianId,
        leadId: int.parse(widget.lead['id'].toString()),
        status: status,
        surveyDetails: {
          'property_type': _propertyType ?? '',
          'flat_size': _selectedFlatSize!,
          'property_area': _selectedFlatSize!,
          'area_sqft': num.tryParse(_areaSqftController.text.trim()),
          'infestation_level': _infestationLevel!,
          'target_pest_types': _selectedPests.toList(),
          'affected_areas': _affectedAreasController.text.trim(),
          'findings': _findingsController.text.trim(),
          'recommended_treatments': _selectedTreatments.toList(),
          'service_frequency': _serviceFrequency ?? '',
          'pest_amounts': pestAmounts.isEmpty ? null : pestAmounts,
          'quotation_amount': quotationAmount,
          'gst_applicable': _gstApplicable,
          'gst_percentage': gstPercentage,
          'technician_notes': _technicianNotesController.text.trim(),
          'evidence_photos': _evidencePhotos,
          'customer_signature': _savedSignature ?? '',
          'schedule_date': _formatDate(_surveyDate!),
          'schedule_time': _formatTime(_surveyTime!),
        },
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Could not update survey.');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, double> get _enteredPestAmounts {
    final amounts = <String, double>{};
    for (final pest in _selectedPests) {
      final amount = double.tryParse(
        _pestAmountControllers[pest]?.text.trim() ?? '',
      );
      if (amount != null && amount.isFinite && amount >= 0) {
        amounts[pest] = amount;
      }
    }
    return amounts;
  }

  double? get _quotationBaseAmount {
    final pestAmounts = _enteredPestAmounts;
    if (pestAmounts.isNotEmpty) {
      return double.parse(
        pestAmounts.values
            .reduce((total, amount) => total + amount)
            .toStringAsFixed(2),
      );
    }

    final amount = double.tryParse(_quotationAmountController.text.trim());
    if (amount == null || !amount.isFinite || amount < 0) return null;
    return amount;
  }

  double? get _gstAmount {
    final baseAmount = _quotationBaseAmount;
    if (baseAmount == null) return null;
    if (!_gstApplicable) return 0;

    final percentage = double.tryParse(_gstPercentageController.text.trim());
    if (percentage == null ||
        !percentage.isFinite ||
        percentage < 0 ||
        percentage > 100) {
      return null;
    }
    return double.parse((baseAmount * percentage / 100).toStringAsFixed(2));
  }

  double? get _totalQuotationAmount {
    final baseAmount = _quotationBaseAmount;
    final gstAmount = _gstAmount;
    if (baseAmount == null || gstAmount == null) return null;
    return double.parse((baseAmount + gstAmount).toStringAsFixed(2));
  }

  String _formatQuotationAmount(double amount) =>
      '₹ ${amount.toStringAsFixed(2)}';

  Widget _quotationSummaryRow(
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isTotal ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount, style: style),
      ],
    );
  }

  Future<void> _pickSurveyDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _surveyDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _surveyDate = date);
  }

  Future<void> _pickSurveyTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _surveyTime ?? TimeOfDay.now(),
    );
    if (time != null && mounted) setState(() => _surveyTime = time);
  }

  Widget _detail(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF75899A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1D374B),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxSection(
    String title,
    List<String> options,
    Set<String> selected,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E7E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2924),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            title,
            'Select all that apply',
            icon: Icons.pest_control_rodent_outlined,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                showCheckmark: true,
                selectedColor: const Color(0xFFE5F1EB),
                backgroundColor: const Color(0xFFF7F7F3),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFB7D2C2)
                      : const Color(0xFFE8E7E0),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? _ink : _muted,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: _isSubmitting
                    ? null
                    : (checked) => setState(() {
                          if (checked) {
                            selected.add(option);
                            if (identical(selected, _selectedPests)) {
                              _pestAmountControllers.putIfAbsent(
                                option,
                                TextEditingController.new,
                              );
                            }
                          } else {
                            selected.remove(option);
                          }
                        }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(
    String title,
    String subtitle, {
    IconData icon = Icons.tune_rounded,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1EB),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _ink, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pestAmountFields() {
    final selectedPests =
        _pestTypes.where(_selectedPests.contains).toList(growable: false);
    if (selectedPests.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E7E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimate by pest',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter a separate service amount for each selected pest.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...selectedPests.map((pest) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: pest == selectedPests.last ? 0 : 10,
              ),
              child: TextField(
                key: ValueKey('pest-amount-$pest'),
                controller: _pestAmountControllers[pest],
                enabled: !_isSubmitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: '$pest Amount',
                  prefixText: '₹ ',
                  hintText: 'Enter estimate for $pest',
                  border: _fieldBorder,
                  filled: true,
                  fillColor: const Color(0xFFFCFCFA),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final name = (lead['customer_name'] ?? 'Survey').toString();
    final service = (lead['service'] ?? 'Service').toString();

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Field survey',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF183C36), Color(0xFF28574A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2416322B),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Text(
                        'FIELD VISIT',
                        style: TextStyle(
                          color: Color(0xFFF2D99E),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.verified_user_outlined,
                      color: _gold.withValues(alpha: 0.9),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'PROPERTY ASSESSMENT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.spa_outlined,
                        color: Color(0xFFF2D99E),
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          service,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEAE9E2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  'Client details',
                  'Information provided for this visit',
                  icon: Icons.person_pin_circle_outlined,
                ),
                const SizedBox(height: 18),
                _detail('Phone', lead['phone']?.toString()),
                _detail('Address', lead['address']?.toString()),
                _detail('City', lead['city']?.toString()),
                _detail('Treatment', lead['treatment']?.toString()),
                _detail('Property size', lead['flat_size']?.toString()),
                _detail('Notes', lead['notes']?.toString()),
                _detail('Marketing notes', lead['marketing_notes']?.toString()),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _sectionHeading(
            'Property profile',
            'Tell us about the space you inspected',
            icon: Icons.domain_outlined,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _propertyType,
            decoration: const InputDecoration(
              labelText: 'Property Type',
              border: _fieldBorder,
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Residential',
                child: Text('Residential'),
              ),
              DropdownMenuItem(
                value: 'Commercial',
                child: Text('Commercial'),
              ),
            ],
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _propertyType = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedFlatSize),
            initialValue: _selectedFlatSize,
            decoration: InputDecoration(
              labelText: 'Property Area / Flat Size (ERP)',
              errorText: _flatSizeError,
              suffixIcon: _isLoadingFlatSizes
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: _fieldBorder,
              filled: true,
              fillColor: Colors.white,
            ),
            items: _flatSizes
                .map((size) => DropdownMenuItem(
                      value: size,
                      child: Text(size),
                    ))
                .toList(),
            onChanged: _isSubmitting || _isLoadingFlatSizes
                ? null
                : (value) => setState(() => _selectedFlatSize = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _areaSqftController,
            enabled: !_isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Area in square feet (optional)',
              hintText: 'For example: 1200',
              border: _fieldBorder,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _sectionHeading(
            'Pest inspection',
            'Identify activity and severity',
            icon: Icons.search_rounded,
          ),
          const SizedBox(height: 14),
          _checkboxSection('Target Pest Type', _pestTypes, _selectedPests),
          if (_selectedPests.isNotEmpty) ...[
            const SizedBox(height: 12),
            _pestAmountFields(),
          ],
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _infestationLevel,
            decoration: InputDecoration(
              labelText: Text.translate(context, 'Infestation level'),
              border: _fieldBorder,
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Low', child: Text('Low')),
              DropdownMenuItem(value: 'Medium', child: Text('Medium')),
              DropdownMenuItem(value: 'High', child: Text('High')),
            ],
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _infestationLevel = value),
          ),
          const SizedBox(height: 22),
          _sectionHeading(
            'Inspection evidence',
            'Capture and document what you find',
            icon: Icons.photo_camera_back_outlined,
          ),
          const SizedBox(height: 14),
          _evidencePhotosSection(),
          const SizedBox(height: 22),
          _sectionHeading(
            'Treatment plan',
            'Recommend the right service for this property',
            icon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 14),
          _checkboxSection(
            'Recommended Treatment',
            _treatments,
            _selectedTreatments,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8E7E0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x090F2924),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading(
                  'Estimate & tax',
                  'Set your service price and GST',
                  icon: Icons.request_quote_outlined,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _serviceFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Service Frequency',
                    border: _fieldBorder,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'One-time', child: Text('One-time')),
                    DropdownMenuItem(value: 'AMC', child: Text('AMC')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _serviceFrequency = value),
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  value: _gstApplicable,
                  onChanged: _isSubmitting
                      ? null
                      : (value) =>
                          setState(() => _gstApplicable = value ?? false),
                  title: const Text('Apply GST'),
                  subtitle: Text(
                    _gstApplicable
                        ? 'GST will be added to the quotation amount.'
                        : 'No GST will be added.',
                  ),
                  activeColor: const Color(0xFF28574A),
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                if (_gstApplicable) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _gstPercentageController,
                    enabled: !_isSubmitting,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'GST Percentage',
                      suffixText: '%',
                      hintText: 'Enter GST rate',
                      border: _fieldBorder,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  if (_quotationBaseAmount != null && _gstAmount == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Enter a valid GST percentage between 0 and 100.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
                if (_quotationBaseAmount != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F1),
                      border: Border.all(color: const Color(0xFFE5E9E0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        if (_enteredPestAmounts.isNotEmpty)
                          ..._pestTypes
                              .where(_enteredPestAmounts.containsKey)
                              .map(
                                (pest) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _quotationSummaryRow(
                                    pest,
                                    _formatQuotationAmount(
                                      _enteredPestAmounts[pest]!,
                                    ),
                                  ),
                                ),
                              ),
                        if (_enteredPestAmounts.isEmpty &&
                            _selectedPests.isNotEmpty &&
                            _quotationBaseAmount != null)
                          _quotationSummaryRow(
                            'Existing estimate',
                            _formatQuotationAmount(_quotationBaseAmount!),
                          ),
                        _quotationSummaryRow(
                          'Subtotal',
                          _formatQuotationAmount(_quotationBaseAmount!),
                        ),
                        if (_gstApplicable) ...[
                          const SizedBox(height: 6),
                          _quotationSummaryRow(
                            'GST (${_gstPercentageController.text.trim().isEmpty ? '—' : _gstPercentageController.text.trim()}%)',
                            _gstAmount == null
                                ? '—'
                                : _formatQuotationAmount(_gstAmount!),
                          ),
                        ],
                        const Divider(height: 16),
                        _quotationSummaryRow(
                          'Total amount',
                          _totalQuotationAmount == null
                              ? '—'
                              : _formatQuotationAmount(_totalQuotationAmount!),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionHeading(
            'Visit notes',
            'Document affected areas and recommendations',
            icon: Icons.sticky_note_2_outlined,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _affectedAreasController,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              labelText: Text.translate(context, 'Affected areas'),
              hintText:
                  Text.translate(context, 'For example: kitchen and balcony'),
              border: _fieldBorder,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _findingsController,
            enabled: !_isSubmitting,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: Text.translate(
                  context, 'Findings and recommendation (optional)'),
              border: _fieldBorder,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _technicianNotesController,
            enabled: !_isSubmitting,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Technician Notes',
              border: _fieldBorder,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _customerSignatureSection(),
          const SizedBox(height: 22),
          _sectionHeading(
            'Appointment',
            'Propose a convenient service window',
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _isSubmitting ? null : _pickSurveyDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: Text.translate(context, 'Proposed service date'),
                border: _fieldBorder,
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _surveyDate == null ? 'Select date' : _formatDate(_surveyDate!),
                style: TextStyle(
                  color: _surveyDate == null
                      ? const Color(0xFF75899A)
                      : const Color(0xFF1D374B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _isSubmitting ? null : _pickSurveyTime,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: Text.translate(context, 'Proposed service time'),
                border: _fieldBorder,
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(Icons.schedule_outlined),
              ),
              child: Text(
                _surveyTime == null ? 'Select time' : _formatTime(_surveyTime!),
                style: TextStyle(
                  color: _surveyTime == null
                      ? const Color(0xFF75899A)
                      : const Color(0xFF1D374B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF183C36),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2016322B),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready to submit?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the outcome for this survey',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed:
                        _isSubmitting ? null : () => _submitResult('converted'),
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Converted'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE4C987),
                      foregroundColor: const Color(0xFF183C36),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 52,
                  child: FilledButton.tonalIcon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitResult('waiting_for_confirmation'),
                    icon: const Icon(Icons.hourglass_top_rounded),
                    label: const Text('Waiting for Confirmation'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidencePhotosSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E7E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2924),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Geo-tagged photos',
            style: TextStyle(
              color: Color(0xFF173632),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Captured with location. Up to 4 photos.',
            style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
          ),
          if (_evidencePhotos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_evidencePhotos.length, (index) {
                final evidence = _evidencePhotos[index];
                final image = evidence['image']?.toString() ?? '';
                return SizedBox(
                  width: 118,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(image),
                              width: 118,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 118,
                                height: 90,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(
                                      () => _evidencePhotos.removeAt(index),
                                    ),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ],
                      ),
                      Text(
                        '${evidence['latitude']}, ${evidence['longitude']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSubmitting || _evidencePhotos.length >= 4
                ? null
                : _captureEvidencePhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              _evidencePhotos.length >= 4
                  ? 'Photo limit reached'
                  : 'Take photo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerSignatureSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E7E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x090F2924),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Digital Signature',
            style: TextStyle(
              color: Color(0xFF173632),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          if (_savedSignature != null)
            Image.memory(
              base64Decode(_savedSignature!.split(',').last),
              height: 150,
              width: double.infinity,
              fit: BoxFit.contain,
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD7E1E8)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (_savedSignature == null)
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _captureSignature,
                  icon: const Icon(Icons.check),
                  label: const Text('Save signature'),
                ),
              OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() {
                          _savedSignature = null;
                          _signatureController.clear();
                        }),
                icon: Icon(
                  _savedSignature == null ? Icons.undo : Icons.edit_outlined,
                ),
                label: Text(
                  _savedSignature == null ? 'Clear' : 'Sign again',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurveyLeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final VoidCallback onTap;

  const _SurveyLeadCard({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final customer = (lead['customer_name'] ?? 'Customer').toString();
    final service = (lead['service'] ?? 'Survey').toString();
    final location = [lead['location_name'], lead['city']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1EAF0)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE4F4F5),
          child: Icon(Icons.assignment_outlined, color: Color(0xFF08747A)),
        ),
        title: Text(
          customer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text([
            service,
            if (location.isNotEmpty) location,
            if ((lead['phone'] ?? '').toString().isNotEmpty)
              lead['phone'].toString(),
          ].join('\n')),
        ),
        isThreeLine: location.isNotEmpty,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SurveyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SurveyEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF8DA3B2)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF29465C),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
