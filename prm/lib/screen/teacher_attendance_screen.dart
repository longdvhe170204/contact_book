import 'package:flutter/material.dart';
import '../models/attendance.dart';
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
  List<String> _classes = [];
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  List<User> _students = [];
  // studentId -> status
  final Map<int, String> _statusMap = {};
  final Map<int, TextEditingController> _noteControllers = {};
  bool _isLoadingClasses = true;
  bool _isLoadingStudents = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTeacher() async {
    try {
      final user = await StorageService.getCurrentUser();
      if (!mounted || user == null) return;
      final classes = await ApiService.getTeacherClasses(user.id);
      if (!mounted) return;
      setState(() {
        _teacher = user;
        _classes = classes;
        _isLoadingClasses = false;
        if (classes.isNotEmpty) {
          _selectedClass = classes.first;
        }
      });
      if (_selectedClass != null) _loadStudents();
    } catch (_) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_teacher == null || _selectedClass == null) return;
    setState(() => _isLoadingStudents = true);
    try {
      final students = await ApiService.getTeacherStudents(_teacher!.id, className: _selectedClass);
      if (!mounted) return;
      // Init status ke PRESENT if not already set
      for (final s in students) {
        _statusMap.putIfAbsent(s.id, () => 'PRESENT');
        _noteControllers.putIfAbsent(s.id, () => TextEditingController());
      }
      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_teacher == null || _selectedClass == null || _students.isEmpty) return;
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
        _teacher!.id,
        className: _selectedClass!,
        date: _formatDate(_selectedDate),
        records: List<Map<String, dynamic>>.from(records),
      );

      if (!mounted) return;
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
      case 'PRESENT':
        return const Color(0xFF4CAF50);
      case 'ABSENT':
        return const Color(0xFFF44336);
      case 'LATE':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PRESENT':
        return 'Có mặt';
      case 'ABSENT':
        return 'Vắng';
      case 'LATE':
        return 'Muộn';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          if (_isLoadingClasses)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            _buildFilters(),
            Expanded(
              child: _isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? _buildEmpty()
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                itemCount: _students.length,
                                itemBuilder: (context, index) => _buildStudentTile(_students[index]),
                              ),
                            ),
                            _buildSaveButton(),
                          ],
                        ),
            ),
          ],
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

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: InputDecoration(
                    labelText: 'Lớp',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedClass = v);
                    _loadStudents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF1976D2)),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
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
                // Status toggle buttons
                Row(
                  children: ['PRESENT', 'ABSENT', 'LATE'].map((s) {
                    final isSelected = status == s;
                    final c = _statusColor(s);
                    return GestureDetector(
                      onTap: () => setState(() => _statusMap[student.id] = s),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? c : c.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF388E3C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildEmpty() {
    return const Center(
      child: Text('Không có học sinh trong lớp này.'),
    );
  }
}
