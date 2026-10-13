import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import '../widgets/localized_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/neumorphic_style.dart';
import '../services/api_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? selectedReceiptImage;
  String selectedCategory = 'Petrol';
  String? userId;
  bool isLoading = false;
  List<dynamic> expenses = [];
  double totalExpense = 0.0;

  final List<String> categories = [
    'Petrol',
    'Maintenance',
    'Overtime',
    'Commission',
    'Material',
    'Office Expense',
    'Breakfast',
    'Travel',
    'Food',
    'Fuel',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
    if (userId != null) {
      _fetchExpenses();
    }
  }

  Future<void> _fetchExpenses() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final response = await ApiService.getExpenses(
        userId: userId!,
        fromDate: DateFormat('yyyy-MM-dd').format(monthStart),
        toDate: DateFormat('yyyy-MM-dd').format(monthEnd),
      );

      if (response['success'] == true) {
        setState(() {
          expenses = response['expenses'] ?? [];
          totalExpense = double.tryParse(response['total'].toString()) ?? 0.0;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Failed to load expenses')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense List'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExpenses,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTodayTotal(),
                      const SizedBox(height: 24),
                      _buildExpenseForm(),
                      const SizedBox(height: 24),
                      _buildExpenseList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTodayTotal() {
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 16),
        child: Column(
          children: [
            Text(
              '$monthLabel Total Expense',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '₹ ${totalExpense.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Expense',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            decoration: InputDecoration(
              labelText: Text.translate(context, 'Category'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: Text.translate(context, 'Amount (₹)'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: Text.translate(context, 'Description'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          _buildReceiptPicker(),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _addExpense,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'ADD EXPENSE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receipt Photo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(selectedReceiptImage == null
                  ? 'Take receipt photo'
                  : 'Retake receipt photo'),
                onPressed: _pickReceiptImage,
              ),
            ),
            if (selectedReceiptImage != null) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    selectedReceiptImage = null;
                  });
                },
              ),
            ]
          ],
        ),
        if (selectedReceiptImage != null) ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${selectedReceiptImage!.name}',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ],
    );
  }

  Future<void> _pickReceiptImage() async {
    final pickedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedImage != null) {
      setState(() {
        selectedReceiptImage = pickedImage;
      });
    }
  }

  Widget _buildExpenseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Month\'s Expenses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No expenses added today',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ...expenses.map((expense) => _buildExpenseCard(expense)),
      ],
    );
  }

  Widget _buildExpenseCard(dynamic expense) {
    final status =
        ((expense['status'] ?? expense['expense_status'] ?? 'pending')
                .toString())
            .toLowerCase();
    final statusColor = _getExpenseStatusColor(status);
    final statusText = _getExpenseStatusText(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.neumorphicDecoration(borderRadius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCategoryColor(expense['category']),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(expense['category']),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense['category'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense['description'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    if (expense['receipt_photo_url'] != null &&
                        expense['receipt_photo_url'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 14,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Receipt attached',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blueGrey[700]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '₹ ${double.parse(expense['amount'].toString()).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (expense['admin_notes'] != null &&
              expense['admin_notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Admin note: ${expense['admin_notes']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getExpenseStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return status.isEmpty
            ? 'Pending'
            : status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getExpenseStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'petrol':
        return Colors.red;
      case 'maintenance':
        return Colors.purple;
      case 'overtime':
        return Colors.indigo;
      case 'commission':
        return Colors.teal;
      case 'material':
        return Colors.brown;
      case 'office expense':
        return Colors.blueGrey;
      case 'breakfast':
        return Colors.amber;
      case 'travel':
        return Colors.blue;
      case 'food':
        return Colors.green;
      case 'fuel':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'petrol':
        return Icons.local_gas_station;
      case 'maintenance':
        return Icons.build;
      case 'overtime':
        return Icons.access_time;
      case 'commission':
        return Icons.monetization_on;
      case 'material':
        return Icons.inventory;
      case 'office expense':
        return Icons.business;
      case 'breakfast':
        return Icons.free_breakfast;
      case 'travel':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      case 'fuel':
        return Icons.local_gas_station;
      default:
        return Icons.receipt;
    }
  }

  Future<void> _addExpense() async {
    if (amountController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    String? receiptPhoto;
    if (selectedReceiptImage != null) {
      final bytes = await selectedReceiptImage!.readAsBytes();
      final extension =
          selectedReceiptImage!.path.split('.').last.toLowerCase();
      final imageType = ['png', 'jpg', 'jpeg', 'webp'].contains(extension)
          ? (extension == 'jpg' ? 'jpeg' : extension)
          : 'jpeg';
      receiptPhoto = 'data:image/$imageType;base64,${base64Encode(bytes)}';
    }

    try {
      final response = await ApiService.addExpense(
        userId: userId!,
        category: selectedCategory,
        amount: double.parse(amountController.text),
        description: descriptionController.text,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        receiptPhoto: receiptPhoto,
      );

      setState(() {
        isLoading = false;
      });

      if (response['success'] == true) {
        amountController.clear();
        descriptionController.clear();
        selectedReceiptImage = null;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully')),
          );
        }

        // Refresh the expense list
        _fetchExpenses();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Failed to add expense')),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
