import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  User? _teacher;
  DateTime _selectedDate = DateTime.now();
  List<Schedule> _allTeacherSchedules = [];
  List<Schedule> _visibleSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherAndSchedules();
  }

  Future<void> _loadTeacherAndSchedules() async {
    setState(() => _isLoading = true);
    try {
      final user = await StorageService.getCurrentUser();
      if (!mounted || user == null) return;
      
      final schedules = await ApiService.getTeacherSchedules(user.id);
      
      if (!mounted) return;
      setState(() {
        _teacher = user;
        _allTeacherSchedules = schedules;
        _isLoading = false;
        _updateVisibleSchedules();
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateVisibleSchedules() {
    // dayOfWeek in DateTime: 1 (Mon) -> 7 (Sun)
    // dayOfWeek in our API: 0 (Mon) -> 6 (Sun)
    final apiDayOfWeek = _selectedDate.weekday - 1;
    setState(() {
      _visibleSchedules = _allTeacherSchedules
          .where((s) => s.dayOfWeek == apiDayOfWeek)
          .toList();
    });
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
        _selectedDate = picked;
        _updateVisibleSchedules();
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _getWeekDayName(DateTime d) {
    const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    return days[d.weekday - 1];
  }

  void _openAttendanceSheet(Schedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TakeAttendanceBottomSheet(
        teacher: _teacher!,
        schedule: schedule,
        date: _formatDate(_selectedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _visibleSchedules.isEmpty
                    ? const Center(child: Text('Không có lịch dạy trong ngày này'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _visibleSchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = _visibleSchedules[index];
                          return _buildScheduleCard(schedule);
                        },
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
          colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
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
                    Icon(Icons.how_to_reg, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Điểm danh',
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

  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 20, color: Color(0xFF388E3C)),
              const SizedBox(width: 12),
              Text(
                '${_getWeekDayName(_selectedDate)}, ${_formatDate(_selectedDate)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
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
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.period,
                    style: const TextStyle(
                      color: Color(0xFF388E3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.class_, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Lớp: ${schedule.className}', style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 20),
                const Icon(Icons.room, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Phòng: ${schedule.room}', style: const TextStyle(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Thời gian: ${schedule.startTime} - ${schedule.endTime}'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openAttendanceSheet(schedule),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.checklist),
                label: const Text('Điểm danh lớp này', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TakeAttendanceBottomSheet extends StatefulWidget {
  final User teacher;
  final Schedule schedule;
  final String date;

  const _TakeAttendanceBottomSheet({
    required this.teacher,
    required this.schedule,
    required this.date,
  });

  @override
  State<_TakeAttendanceBottomSheet> createState() => _TakeAttendanceBottomSheetState();
}

class _TakeAttendanceBottomSheetState extends State<_TakeAttendanceBottomSheet> {
  List<User> _students = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  final Map<int, String> _statusMap = {};
  final Map<int, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    _loadStudentsAndAttendance();
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudentsAndAttendance() async {
    try {
      final students = await ApiService.getTeacherStudents(
        widget.teacher.id,
        className: widget.schedule.className,
      );
      
      // Load existing attendance if any
      final existingAttendance = await ApiService.getClassAttendance(widget.schedule.className, widget.date);
      final Map<int, dynamic> attendanceRecordMap = {
        for (var a in existingAttendance.where((att) => att.subject == widget.schedule.subject)) a.studentId: a
      };

      if (!mounted) return;
      for (final s in students) {
        final existing = attendanceRecordMap[s.id];
        _statusMap.putIfAbsent(s.id, () => existing?.status ?? 'PRESENT');
        _noteControllers.putIfAbsent(s.id, () => TextEditingController(text: existing?.note ?? ''));
      }
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_students.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final records = _students.map((s) {
        return {
          'studentId': s.id,
          'status': _statusMap[s.id] ?? 'PRESENT',
          'note': _noteControllers[s.id]?.text.trim() ?? '',
        };
      }).toList();

      await ApiService.saveAttendance(
        widget.teacher.id,
        className: widget.schedule.className,
        subject: widget.schedule.subject,
        date: widget.date,
        records: List<Map<String, dynamic>>.from(records),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điểm danh đã được lưu thành công!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                        ? const Center(child: Text('Không có học sinh trong lớp này.'))
                        : ListView.builder(
                            controller: controller,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _students.length,
                            itemBuilder: (context, index) => _buildStudentTile(_students[index]),
                          ),
              ),
              if (!_isLoading && _students.isNotEmpty) _buildSaveButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điểm danh: Lớp ${widget.schedule.className}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.schedule.subject} | Ngày: ${widget.date}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(User student) {
    final status = _statusMap[student.id] ?? 'PRESENT';
    final color = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : '?',
                    style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                Row(
                  children: ['PRESENT', 'ABSENT', 'LATE'].map((s) {
                    final isSelected = status == s;
                    final c = _statusColor(s);
                    return GestureDetector(
                      onTap: () => setState(() => _statusMap[student.id] = s),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? c : c.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c),
                        ),
                        child: Text(
                          _statusLabel(s),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : c,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (status != 'PRESENT')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: TextField(
                controller: _noteControllers[student.id],
                decoration: InputDecoration(
                  hintText: 'Ghi chú (lý do vắng/muộn...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF388E3C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(
            _isSaving ? 'Đang lưu...' : 'Lưu điểm danh',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
