import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../models/schedule.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  User? _student;

  // Date tracking
  late DateTime _currentWeekStart;
  late int _selectedDayOfWeek; // 0 for Mon to 6 for Sun

  List<Schedule> _schedules = [];
  List<Attendance> _allAttendances = [];
  bool _isLoading = true;
  User? _currentUser;

  final List<String> _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _formatPeriod(String? period) {
    final value = period?.trim() ?? '';

    if (value.isEmpty) {
      return 'Chưa có tiết';
    }

    final lower = value.toLowerCase();

    if (lower.startsWith('tiết')) {
      return value;
    }

    if (lower.startsWith('tiet')) {
      final number = value.replaceFirst(
        RegExp(r'^tiet\s*', caseSensitive: false),
        '',
      );

      return 'Tiết $number';
    }

    return 'Tiết $value';
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentWeekStart = _getStartOfWeek(now);
    _selectedDayOfWeek = now.weekday - 1;

    _loadAllData();
  }

  DateTime _getStartOfWeek(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  DateTime get _selectedDate {
    return _currentWeekStart.add(Duration(days: _selectedDayOfWeek));
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final user = await StorageService.getCurrentUser();
      if (!mounted || user == null) return;

      final allAttendances = await ApiService.getStudentAttendance(user.id);

      if (!mounted) return;
      setState(() {
        _student = user;
        _allAttendances = allAttendances;
      });
      await _loadSchedulesForSelectedDay();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedulesForSelectedDay() async {
    if (_student == null || _student!.className == null || _student!.className!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final schedules = await ApiService.getSchedulesByDay(_student!.className!, _selectedDayOfWeek);
      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (picked != null && mounted) {
      setState(() {
        _currentWeekStart = _getStartOfWeek(picked);
        _selectedDayOfWeek = picked.weekday - 1;
      });
      _loadSchedulesForSelectedDay();
    }
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadSchedulesForSelectedDay();
  }

  void _prevWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadSchedulesForSelectedDay();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Attendance? _getAttendanceForSchedule(Schedule schedule) {
    final dateStr = _formatDate(_selectedDate);
    try {
      // Find matching attendance by date AND className AND subject
      return _allAttendances.firstWhere((a) =>
        a.date == dateStr &&
        a.className == schedule.className &&
        a.subject == schedule.subject
      );
    } catch (_) {
      return null;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PRESENT': return const Color(0xFF4CAF50);
      case 'ABSENT': return const Color(0xFFF44336);
      case 'LATE': return const Color(0xFFFF9800);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PRESENT': return 'Có mặt';
      case 'ABSENT': return 'Vắng';
      case 'LATE': return 'Muộn';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekText = 'Tuần: ${_formatDisplayDate(_currentWeekStart)} - ${_formatDisplayDate(weekEnd)}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildWeekSelector(weekText),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftSidebar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Thoi Khoa Bieu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekSelector(String weekText) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF1976D2)),
            onPressed: _prevWeek,
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18, color: Color(0xFF1976D2)),
                  const SizedBox(width: 8),
                  Text(
                    weekText,
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF1976D2)),
            onPressed: _nextWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(2, 0)),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final isSelected = _selectedDayOfWeek == index;
          final dateForDay = _currentWeekStart.add(Duration(days: index));

          return GestureDetector(
            onTap: () {
              if (_selectedDayOfWeek != index) {
                setState(() => _selectedDayOfWeek = index);
                _loadSchedulesForSelectedDay();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1976D2) : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _weekDays[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDisplayDate(dateForDay),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.beach_access, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Không có môn học',
              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final attendance = _getAttendanceForSchedule(schedule);
        return _buildScheduleCard(schedule, attendance);
      },
    );
  }

  Widget _buildScheduleCard(Schedule schedule, Attendance? attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    schedule.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatPeriod(schedule.period),
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Giáo viên: ${schedule.teacher}', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.room, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Phòng: ${schedule.room}', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('${schedule.startTime} - ${schedule.endTime}', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Trạng thái:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                ),
                const Spacer(),
                if (attendance == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Chưa điểm danh',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(attendance.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor(attendance.status)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          attendance.status == 'PRESENT' ? Icons.check_circle :
                          (attendance.status == 'ABSENT' ? Icons.cancel : Icons.warning),
                          size: 14,
                          color: _statusColor(attendance.status)
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(attendance.status),
                          style: TextStyle(
                            color: _statusColor(attendance.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (attendance?.note != null && attendance!.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.edit_note, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lời nhắc: ${attendance.note}',
                        style: TextStyle(fontSize: 13, color: Colors.orange[800], fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
