import 'package:flutter/material.dart';
import '../models/conduct.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TeacherConductScreen extends StatefulWidget {
  const TeacherConductScreen({super.key});

  @override
  State<TeacherConductScreen> createState() => _TeacherConductScreenState();
}

class _TeacherConductScreenState extends State<TeacherConductScreen> {
  User? _teacher;
  List<String> _classes = [];
  String? _selectedClass;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<User> _students = [];
  List<Conduct> _existingConducts = [];
  bool _isLoadingClasses = true;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
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
        if (classes.isNotEmpty) _selectedClass = classes.first;
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
      final conducts = await ApiService.getClassConduct(_selectedClass!, _selectedMonth, _selectedYear);
      if (!mounted) return;
      setState(() {
        _students = students;
        _existingConducts = conducts;
        _isLoadingStudents = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Conduct? _conductForStudent(int studentId) {
    try {
      return _existingConducts.firstWhere((c) => c.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  void _openConductDialog(User student) {
    final existing = _conductForStudent(student.id);
    String selectedRating = existing?.conductRating ?? 'GOOD';
    final commentCtrl = TextEditingController(text: existing?.comment ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nhận xét: ${student.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tháng $_selectedMonth/$_selectedYear',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                const Text('Xếp loại hạnh kiểm', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    _ratingChip('EXCELLENT', 'Xuất sắc', const Color(0xFF1976D2), selectedRating, (r) {
                      setModal(() => selectedRating = r);
                    }),
                    _ratingChip('GOOD', 'Tốt', const Color(0xFF4CAF50), selectedRating, (r) {
                      setModal(() => selectedRating = r);
                    }),
                    _ratingChip('AVERAGE', 'Khá', const Color(0xFFFF9800), selectedRating, (r) {
                      setModal(() => selectedRating = r);
                    }),
                    _ratingChip('WEAK', 'Yếu', const Color(0xFFF44336), selectedRating, (r) {
                      setModal(() => selectedRating = r);
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Lời nhận xét', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập lời nhận xét cho học sinh...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _saveConduct(student.id, selectedRating, commentCtrl.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Lưu nhận xét', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingChip(String value, String label, Color color, String selected, Function(String) onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _saveConduct(int studentId, String rating, String comment) async {
    if (_teacher == null || _selectedClass == null) return;
    try {
      final saved = await ApiService.saveConduct(
        _teacher!.id,
        studentId: studentId,
        className: _selectedClass!,
        month: _selectedMonth,
        year: _selectedYear,
        conductRating: rating,
        comment: comment,
      );
      if (!mounted) return;
      setState(() {
        _existingConducts.removeWhere((c) => c.studentId == studentId);
        _existingConducts.add(saved);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu nhận xét!'), backgroundColor: Color(0xFF4CAF50)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'EXCELLENT':
        return const Color(0xFF1976D2);
      case 'GOOD':
        return const Color(0xFF4CAF50);
      case 'AVERAGE':
        return const Color(0xFFFF9800);
      case 'WEAK':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _ratingLabel(String rating) {
    switch (rating) {
      case 'EXCELLENT':
        return 'Xuất sắc';
      case 'GOOD':
        return 'Tốt';
      case 'AVERAGE':
        return 'Khá';
      case 'WEAK':
        return 'Yếu';
      default:
        return rating;
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
                      ? const Center(child: Text('Không có học sinh.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (context, i) => _buildStudentTile(_students[i]),
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
          colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
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
                    Icon(Icons.rate_review, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Nhận xét HS',
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
    final months = List.generate(12, (i) => i + 1);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(
                labelText: 'Lớp',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                setState(() => _selectedClass = v);
                _loadStudents();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: InputDecoration(
                labelText: 'Tháng',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: months.map((m) => DropdownMenuItem(value: m, child: Text('T$m'))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedMonth = v);
                  _loadStudents();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(User student) {
    final conduct = _conductForStudent(student.id);
    final hasConduct = conduct != null;
    final color = hasConduct ? _ratingColor(conduct.conductRating) : Colors.grey[400]!;

    return GestureDetector(
      onTap: () => _openConductDialog(student),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                student.name.isNotEmpty ? student.name[0] : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (hasConduct) ...[
                    const SizedBox(height: 3),
                    Text(
                      conduct.comment ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                hasConduct ? _ratingLabel(conduct.conductRating) : 'Chưa nhận xét',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
