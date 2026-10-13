class Job {
  final int id;
  final int leadId;
  final int?
      complaintId; // NEW: Complaint ID if this is a complaint revisit job
  final String customerName;
  final String phone;
  final String? alternatePhone;
  final String email;
  final String address;
  final String? mapLocation; // Google Maps link
  final double? latitude;
  final double? longitude;
  final String city;
  final String state;
  final String service;
  final String? treatment; // Treatment type
  final String? flatSize; // Flat size
  final String? customerType;
  final String? customerCategory;
  final String? gstStatus;
  final String? gstNumber;
  final String? frequency;
  final int? frequencyId;
  final int? numberOfServices;
  final int? warrantyDays;
  final String? followUpDate;
  final String? leadNotes;
  final int? leadSourceId;
  final String? leadSourceName;
  final int? locationId;
  final String? locationName;
  final int? jobTypeId;
  final String? jobTypeName;
  final String? whatsappMessage;
  final int? branchId;
  final String status;
  final DateTime? scheduledDate;
  final double? amount;
  final String? jobNotes;
  final String? marketingNotes; // Add marketing notes field
  final String? marketingUserName;
  final String? marketingUserPhone;
  final List<Map<String, dynamic>>? addonServices;
  final double addonAmount;
  final double totalAmount;
  final String paymentMode;
  final String? paymentAccount;
  final double paidAmount;
  final double pendingAmount;
  final String paymentStatus;
  final DateTime? paymentDate;
  final DateTime? completedDate;
  final String? technicianNotes;
  final bool isGrabbed;
  final DateTime? grabbedAt;
  final DateTime? jobStartTime;
  final int? timeAllocated; // Time allocated in minutes
  final DateTime createdAt;
  // NEW: Recurring job payment fields
  final bool isRecurringSeries;
  final int? recurringSequence;
  final int? totalRecurringJobs;
  final bool showPaymentCollection;
  final bool isPrimaryTechnician;
  final String technicianRole;
  // NEW: Carry forward payment tracking fields
  final double totalPaidAcrossVisits;
  final bool hasCarryForward;
  final List<Map<String, dynamic>> paymentHistory;

  // NEW: Previous technician information for re-visits
  final String? previousTechnicianName;
  final String? previousTechnicianCode;
  final String? previousTechnicianNotes;
  final DateTime? previousJobCompletedDate;
  final int? previousJobId;
  final List<Map<String, dynamic>> previousJobHistory;
  final List<Map<String, dynamic>> technicianNoteHistory;
  final bool isTomorrowPreview;

  // NEW: Tech notes from previous technician
  final String? techNotesFromPrevious;

  Job({
    required this.id,
    required this.leadId,
    this.complaintId, // NEW
    required this.customerName,
    required this.phone,
    this.alternatePhone,
    required this.email,
    required this.address,
    this.mapLocation,
    this.latitude,
    this.longitude,
    required this.city,
    required this.state,
    required this.service,
    this.treatment, // Treatment type
    this.flatSize, // Flat size
    this.customerType,
    this.customerCategory,
    this.gstStatus,
    this.gstNumber,
    this.frequency,
    this.frequencyId,
    this.numberOfServices,
    this.warrantyDays,
    this.followUpDate,
    this.leadNotes,
    this.leadSourceId,
    this.leadSourceName,
    this.locationId,
    this.locationName,
    this.jobTypeId,
    this.jobTypeName,
    this.whatsappMessage,
    this.branchId,
    required this.status,
    this.scheduledDate,
    this.amount,
    this.jobNotes,
    this.marketingNotes, // Add marketing notes to constructor
    this.marketingUserName,
    this.marketingUserPhone,
    this.addonServices,
    this.addonAmount = 0,
    this.totalAmount = 0,
    this.paymentMode = 'cash',
    this.paymentAccount,
    this.paidAmount = 0,
    this.pendingAmount = 0,
    this.paymentStatus = 'pending',
    this.paymentDate,
    this.completedDate,
    this.technicianNotes,
    required this.isGrabbed,
    this.grabbedAt,
    this.jobStartTime,
    this.timeAllocated,
    required this.createdAt,
    // NEW: Recurring job payment fields
    this.isRecurringSeries = false,
    this.recurringSequence,
    this.totalRecurringJobs,
    this.showPaymentCollection = true,
    this.isPrimaryTechnician = true,
    this.technicianRole = 'master',
    // NEW: Carry forward payment tracking fields
    this.totalPaidAcrossVisits = 0.0,
    this.hasCarryForward = false,
    this.paymentHistory = const [],
    // NEW: Previous technician information for re-visits
    this.previousTechnicianName,
    this.previousTechnicianCode,
    this.previousTechnicianNotes,
    this.previousJobCompletedDate,
    this.previousJobId,
    this.previousJobHistory = const [],
    this.technicianNoteHistory = const [],
    this.isTomorrowPreview = false,
    // NEW: Tech notes from previous technician
    this.techNotesFromPrevious,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    final amount =
        json['amount'] != null ? double.parse(json['amount'].toString()) : null;
    final paidAmount = json['paid_amount'] != null
        ? double.parse(json['paid_amount'].toString())
        : 0.0;
    final addonAmount = json['addon_amount'] != null
        ? double.parse(json['addon_amount'].toString())
        : 0.0;
    final totalAmount = json['total_amount'] != null
        ? double.parse(json['total_amount'].toString())
        : (amount ?? 0.0);
    final pendingAmount = json['pending_amount'] != null
        ? double.parse(json['pending_amount'].toString())
        : totalAmount;

    // Parse addon services
    List<Map<String, dynamic>>? addonServices;
    if (json['addon_services'] != null && json['addon_services'] is List) {
      addonServices = (json['addon_services'] as List)
          .map((service) => Map<String, dynamic>.from(service))
          .toList();
    }

    return Job(
      id: json['id'] != null ? int.parse(json['id'].toString()) : 0,
      leadId:
          json['lead_id'] != null ? int.parse(json['lead_id'].toString()) : 0,
      complaintId: json['complaint_id'] != null
          ? int.parse(json['complaint_id'].toString())
          : null, // NEW
      customerName: json['customer_name'] ?? '',
      phone: json['phone'] ?? '',
      alternatePhone: json['alternate_phone'],
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      mapLocation: json['map_location'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      service: json['service'] ?? '',
      treatment: json['treatment'], // Treatment type from API
      flatSize: json['flat_size'], // Flat size from API
      customerType: json['customer_type'],
      customerCategory: json['customer_category'],
      gstStatus: json['gst_status'],
      gstNumber: json['gst_number'],
      frequency: json['frequency'],
      frequencyId: json['frequency_id'] != null
          ? int.tryParse(json['frequency_id'].toString())
          : null,
      numberOfServices: json['number_of_services'] != null
          ? int.tryParse(json['number_of_services'].toString())
          : null,
      warrantyDays: json['warranty_days'] != null
          ? int.tryParse(json['warranty_days'].toString())
          : null,
      followUpDate: json['follow_up_date']?.toString(),
      leadNotes: json['notes'],
      leadSourceId: json['lead_source_id'] != null
          ? int.tryParse(json['lead_source_id'].toString())
          : null,
      leadSourceName: json['lead_source_name'],
      locationId: json['location_id'] != null
          ? int.tryParse(json['location_id'].toString())
          : null,
      locationName: json['location_name'],
      jobTypeId: json['job_type_id'] != null
          ? int.tryParse(json['job_type_id'].toString())
          : null,
      jobTypeName: json['job_type_name'],
      whatsappMessage: json['whatsapp_message'],
      branchId: json['branch_id'] != null
          ? int.parse(json['branch_id'].toString())
          : null,
      status: json['status'] ?? 'assigned',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      amount: amount,
      jobNotes: json['job_notes'],
      marketingNotes: json['marketing_notes'], // Add marketing notes from JSON
      marketingUserName: json['marketing_user_name']?.toString(),
      marketingUserPhone: json['marketing_user_phone']?.toString(),
      addonServices: addonServices,
      addonAmount: addonAmount,
      totalAmount: totalAmount,
      paymentMode: json['payment_mode'] ?? 'cash',
      paymentAccount: json['payment_account'],
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date']).toLocal()
          : null,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date']).toLocal()
          : null,
      technicianNotes: json['technician_notes'],
      isGrabbed: json['is_grabbed'] ?? false,
      grabbedAt: json['grabbed_at'] != null
          ? DateTime.parse(json['grabbed_at']).toLocal()
          : null,
      jobStartTime: json['job_start_time'] != null
          ? DateTime.parse(json['job_start_time']).toLocal()
          : null,
      timeAllocated: json['time_allocated'] != null
          ? int.tryParse(json['time_allocated'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      // NEW: Recurring job payment fields
      isRecurringSeries: json['is_recurring_series'] ?? false,
      recurringSequence: json['recurring_sequence'] != null
          ? int.parse(json['recurring_sequence'].toString())
          : null,
      totalRecurringJobs: json['total_recurring_jobs'] != null
          ? int.parse(json['total_recurring_jobs'].toString())
          : null,
      showPaymentCollection: json['show_payment_collection'] ?? true,
      isPrimaryTechnician: json['is_primary_technician'] ?? true,
      technicianRole: json['technician_role'] ??
          ((json['is_primary_technician'] ?? true) ? 'master' : 'co'),
      // NEW: Carry forward payment tracking fields
      totalPaidAcrossVisits: json['total_paid_across_visits'] != null
          ? double.parse(json['total_paid_across_visits'].toString())
          : 0.0,
      hasCarryForward: json['has_carry_forward'] ?? false,
      paymentHistory:
          json['payment_history'] != null && json['payment_history'] is List
              ? (json['payment_history'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
              : [],
      // NEW: Previous technician information for re-visits
      previousTechnicianName: json['previous_technician_name'],
      previousTechnicianCode: json['previous_technician_code'],
      previousTechnicianNotes: json['previous_technician_notes'],
      previousJobCompletedDate: json['previous_job_completed_date'] != null
          ? DateTime.parse(json['previous_job_completed_date']).toLocal()
          : null,
      previousJobId: json['previous_job_id'] != null
          ? int.parse(json['previous_job_id'].toString())
          : null,
      previousJobHistory:
          json['previous_job_history'] != null &&
                  json['previous_job_history'] is List
              ? (json['previous_job_history'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
              : [],
      technicianNoteHistory:
          json['technician_note_history'] is List
              ? (json['technician_note_history'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
              : [],
      isTomorrowPreview: json['is_tomorrow_preview'] == true,
      // NEW: Tech notes from previous technician
      techNotesFromPrevious: json['tech_notes_from_previous'],
    );
  }

  String getStatusLabel() {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'rescheduled':
        return 'Rescheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
