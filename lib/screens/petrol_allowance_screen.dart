import 'package:flutter/material.dart' hide Text;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/localized_text.dart';
import '../services/api_service.dart';

class PetrolAllowanceScreen extends StatefulWidget {
  const PetrolAllowanceScreen({super.key});

  @override
  State<PetrolAllowanceScreen> createState() => _PetrolAllowanceScreenState();
}

class _PetrolAllowanceScreenState extends State<PetrolAllowanceScreen> {
  final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: Intl.defaultLocale,
    symbol: '₹',
    decimalDigits: 0,
  );

  String? _userId;
  String _period = 'month';
  DateTime _anchor = DateTime.now();
  DateTime? _customFrom;
  DateTime? _customTo;
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _allTime = {};
  List<dynamic> _entries = [];
  double _rate = 3;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUser() async {
    final preferences = await SharedPreferences.getInstance();
    _userId = preferences.getString('user_id');
    await _loadAllowance();
  }

  String _dateString(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTimeRange get _range {
    if (_period == 'custom' && _customFrom != null && _customTo != null) {
      return DateTimeRange(start: _customFrom!, end: _customTo!);
    }
    if (_period == 'day') {
      return DateTimeRange(start: _anchor, end: _anchor);
    }
    if (_period == 'week') {
      final start = _anchor.subtract(Duration(days: _anchor.weekday - 1));
      return DateTimeRange(start: start, end: start.add(const Duration(days: 6)));
    }
    if (_period == 'year') {
      return DateTimeRange(
        start: DateTime(_anchor.year),
        end: DateTime(_anchor.year, 12, 31),
      );
    }
    return DateTimeRange(
      start: DateTime(_anchor.year, _anchor.month),
      end: DateTime(_anchor.year, _anchor.month + 1, 0),
    );
  }

  Future<void> _loadAllowance() async {
    if (_userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) setState(() => _loading = true);
    final range = _range;
    final response = await ApiService.getPetrolAllowance(
      userId: _userId!,
      fromDate: _dateString(range.start),
      toDate: _dateString(range.end),
    );

    if (!mounted) return;
    if (response['success'] == true) {
      setState(() {
        _summary = Map<String, dynamic>.from(response['summary'] ?? {});
        _allTime = Map<String, dynamic>.from(response['all_time'] ?? {});
        _entries = List<dynamic>.from(response['entries'] ?? []);
        _rate = double.tryParse(response['rate'].toString()) ?? 3;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Unable to load petrol allowance.')),
      );
    }
  }

  double _number(Map<String, dynamic> source, String key) =>
      double.tryParse(source[key]?.toString() ?? '') ?? 0;

  String _money(dynamic value) =>
      _moneyFormat.format(double.tryParse(value.toString()) ?? 0);

  Future<void> _selectPeriod(String period) async {
    if (period == 'custom') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        initialDateRange: _customFrom != null && _customTo != null
            ? DateTimeRange(start: _customFrom!, end: _customTo!)
            : _range,
      );
      if (range == null) return;
      setState(() {
        _period = period;
        _customFrom = range.start;
        _customTo = range.end;
      });
    } else {
      setState(() => _period = period);
    }
    await _loadAllowance();
  }

  Future<void> _shiftPeriod(int amount) async {
    setState(() {
      if (_period == 'custom') {
        final length = _range.duration.inDays + 1;
        _customFrom = _range.start.add(Duration(days: length * amount));
        _customTo = _customFrom!.add(Duration(days: length - 1));
      } else if (_period == 'day') {
        _anchor = _anchor.add(Duration(days: amount));
      } else if (_period == 'week') {
        _anchor = _anchor.add(Duration(days: 7 * amount));
      } else if (_period == 'year') {
        _anchor = DateTime(_anchor.year + amount, _anchor.month, _anchor.day);
      } else {
        _anchor = DateTime(_anchor.year, _anchor.month + amount, 1);
      }
    });
    await _loadAllowance();
  }

  String get _rangeLabel {
    final range = _range;
    if (_period == 'day') return DateFormat('EEE, d MMM yyyy').format(range.start);
    if (_period == 'month') return DateFormat('MMMM yyyy').format(range.start);
    if (_period == 'year') return '${range.start.year}';
    return '${DateFormat('d MMM yyyy').format(range.start)} - ${DateFormat('d MMM yyyy').format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petrol Allowance'),
        actions: [
          IconButton(
            onPressed: _loadAllowance,
            icon: const Icon(Icons.refresh),
            tooltip: Text.translate(context, 'Refresh'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllowance,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildBalance(_number(_allTime, 'pending')),
                  const SizedBox(height: 16),
                  _buildPeriodPicker(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(onPressed: () => _shiftPeriod(-1), icon: const Icon(Icons.chevron_left)),
                      Expanded(child: Center(child: Text(_rangeLabel, style: const TextStyle(fontWeight: FontWeight.w600)))),
                      IconButton(onPressed: () => _shiftPeriod(1), icon: const Icon(Icons.chevron_right)),
                    ],
                  ),
                  _buildPeriodStats(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('${_entries.where((entry) => entry['type'] == 'km').length} trips', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Text('No entries in this period.')),
                    )
                  else
                    ..._entries.map(_buildEntry),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${DateFormat('d MMM').format(range.start)} to ${DateFormat('d MMM yyyy').format(range.end)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalance(double pending) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2457D6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_summary['technician']?['name'] ?? 'Petrol allowance', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          const Text('Pending balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 2),
          Text(_money(pending), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
          const Divider(color: Colors.white38, height: 24),
          Row(
            children: [
              _balanceValue('Given all time', _money(_allTime['given'] ?? 0)),
              _balanceValue('Used all time', _money(_allTime['used'] ?? 0)),
              _balanceValue('Balance', _money(_allTime['pending'] ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceValue(String label, String value) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              const SizedBox(height: 3),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  Widget _buildPeriodPicker() {
    const options = {'day': 'Day', 'week': 'Week', 'month': 'Month', 'year': 'Year', 'custom': 'Custom'};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((option) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(option.value),
            selected: _period == option.key,
            onSelected: (_) => _selectPeriod(option.key),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPeriodStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _statCard('Amount given', _money(_summary['given'] ?? 0)),
        _statCard('Km travelled', '${_number(_summary, 'km').toStringAsFixed(0)} km'),
        _statCard('Used (₹${_rate.toStringAsFixed(0)}/km)', _money(_summary['used'] ?? 0)),
        _statCard('Period net', _money(_summary['pending'] ?? 0)),
      ],
    );
  }

  Widget _statCard(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _buildEntry(dynamic entry) {
    final isGiven = entry['type'] == 'given';
    final date = DateTime.tryParse(entry['date']?.toString() ?? '');
    final value = double.tryParse(entry['value']?.toString() ?? '') ?? 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: isGiven ? Colors.green.shade50 : Colors.orange.shade50,
        child: Icon(isGiven ? Icons.south_west : Icons.route, color: isGiven ? Colors.green.shade800 : Colors.orange.shade800, size: 20),
      ),
      title: Text(date == null ? 'Unknown date' : DateFormat('d MMM yyyy').format(date)),
      subtitle: Text(isGiven ? (entry['note']?.toString().isNotEmpty == true ? entry['note'] : 'Amount received') : '${value.toStringAsFixed(1)} km travelled'),
      trailing: Text(
        isGiven ? '+${_money(value)}' : '-${_money(value * _rate)}',
        style: TextStyle(color: isGiven ? Colors.green.shade800 : Colors.orange.shade900, fontWeight: FontWeight.w700),
      ),
    );
  }
}