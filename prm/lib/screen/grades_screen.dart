import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/grade.dart';
import '../models/teacher_grade.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  int _selectedSemester = 1;
  User? _currentUser;
  bool _isLoading = true;

  List<Grade> _studentGrades = [];
  List<String> _teacherClasses = [];
  String? _selectedClass;
  List<User> _students = [];
  List<TeacherGrade> _teacherGrades = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _currentUser ?? await StorageService.getCurrentUser();
      if (user == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (user.isTeacher) {
        final classes = _teacherClasses.isEmpty
            ? await ApiService.getTeacherClasses(user.id)
            : _teacherClasses;
        final selectedClass = _selectedClass ?? (classes.isNotEmpty ? classes.first : null);

        final students = selectedClass == null
            ? const <User>[]
            : await ApiService.getTeacherStudents(user.id, className: selectedClass);
        final grades = selectedClass == null
            ? const <TeacherGrade>[]
            : await ApiService.getTeacherGrades(
                user.id,
                className: selectedClass,
                semester: _selectedSemester,
                subject: user.subject,
              );

        if (!mounted) {
          return;
        }
        setState(() {
          _currentUser = user;
          _teacherClasses = classes;
          _selectedClass = selectedClass;
          _students = students;
          _teacherGrades = grades;
          _isLoading = false;
        });
        return;
      }

      final grades = await ApiService.getGrades(user.id, _selectedSemester);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        _studentGrades = grades;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi khi tai diem: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _currentUser?.isTeacher ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isTeacher ? 'Quan ly diem' : 'Bang diem'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isTeacher
              ? _buildTeacherView()
              : _buildStudentView(),
    );
  }

  Widget _buildStudentView() {
    if (_studentGrades.isEmpty) {
      return const Center(child: Text('Chua co diem'));
    }

    final values = _studentGrades.map((g) => g.average).whereType<double>().toList();
    final avg = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildSemesterButton('Hoc ky 1', 1)),
              const SizedBox(width: 12),
              Expanded(child: _buildSemesterButton('Hoc ky 2', 2)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('TB', avg.toStringAsFixed(2), Icons.stars),
                  _buildSummaryItem('Mon', '${_studentGrades.length}', Icons.book),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _studentGrades.length,
            itemBuilder: (context, index) {
              final grade = _studentGrades[index];
              final average = grade.average ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _gradeColor(average).withOpacity(0.15),
                    child: Icon(Icons.book, color: _gradeColor(average)),
                  ),
                  title: Text(grade.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                    'Trung bình: ${average.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: _gradeColor(average),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildGradeRow('Điểm 15 phút', _formatScores(grade.tx15)),
                          const Divider(height: 16),
                          _buildGradeRow('Điểm 1 tiết', _formatScores(grade.tx1tiet)),
                          const Divider(height: 16),
                          _buildGradeRow('Điểm Giữa kỳ', _formatNullable(grade.giuaKy)),
                          const Divider(height: 16),
                          _buildGradeRow('Điểm Cuối kỳ', _formatNullable(grade.cuoiKy)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_teacherClasses.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Lop phu trach',
                    border: OutlineInputBorder(),
                  ),
                  items: _teacherClasses
                      .map((className) => DropdownMenuItem<String>(
                            value: className,
                            child: Text(className),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                    _loadData();
                  },
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSemesterButton('Hoc ky 1', 1)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSemesterButton('Hoc ky 2', 2)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _students.isEmpty
              ? const Center(child: Text('Chua co du lieu lop hoc'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final grade = _findTeacherGrade(student.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text('15p: ${_formatScores(grade?.tx15 ?? const [])}'),
                            Text('1 tiet: ${_formatScores(grade?.tx1tiet ?? const [])}'),
                            Text('Giua ky: ${_formatNullable(grade?.giuaKy)}'),
                            Text('Cuoi ky: ${_formatNullable(grade?.cuoiKy)}'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _showGradeEditor(student, grade),
                                icon: const Icon(Icons.edit),
                                label: const Text('Cap nhat'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSemesterButton(String label, int semester) {
    final isSelected = _selectedSemester == semester;
    return InkWell(
      onTap: () {
        if (_selectedSemester != semester) {
          setState(() {
            _selectedSemester = semester;
          });
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1976D2)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1976D2),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1976D2)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Widget _buildGradeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  TeacherGrade? _findTeacherGrade(int studentId) {
    for (final grade in _teacherGrades) {
      if (grade.studentId == studentId) {
        return grade;
      }
    }
    return null;
  }

  Future<void> _showGradeEditor(User student, TeacherGrade? grade) async {
    final teacher = _currentUser;
    if (teacher == null || !teacher.isTeacher) {
      return;
    }

    final formKey = GlobalKey<FormState>();

    final tx15Controller = TextEditingController(text: _joinScores(grade?.tx15 ?? const []));
    final tx1TietController = TextEditingController(text: _joinScores(grade?.tx1tiet ?? const []));
    final giuaKyController = TextEditingController(text: grade?.giuaKy?.toString() ?? '');
    final cuoiKyController = TextEditingController(text: grade?.cuoiKy?.toString() ?? '');

    String? validateMultipleScores(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      if (RegExp(r'[a-zA-Z]').hasMatch(value)) return 'Không nhập chữ, chỉ nhập số';
      final parts = value.split(',');
      for (var part in parts) {
        if (part.trim().isEmpty) continue;
        final score = double.tryParse(part.trim());
        if (score == null) return 'Sai định dạng số';
        if (score < 0 || score > 10) return 'Điểm phải từ 0 đến 10';
      }
      return null;
    }

    String? validateSingleScore(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      if (RegExp(r'[a-zA-Z]').hasMatch(value)) return 'Không nhập chữ, chỉ nhập số';
      final score = double.tryParse(value.trim());
      if (score == null) return 'Sai định dạng số';
      if (score < 0 || score > 10) return 'Điểm phải từ 0 đến 10';
      return null;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Điểm của ${student.name}'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: tx15Controller,
                        decoration: const InputDecoration(
                          labelText: 'Điểm 15 phút (cách nhau bởi dấu phẩy)',
                          hintText: 'VD: 7, 8.5',
                        ),
                        keyboardType: TextInputType.text,
                        validator: validateMultipleScores,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tx1TietController,
                        decoration: const InputDecoration(
                          labelText: 'Điểm 1 tiết (cách nhau bởi dấu phẩy)',
                          hintText: 'VD: 8, 9.5',
                        ),
                        keyboardType: TextInputType.text,
                        validator: validateMultipleScores,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: giuaKyController,
                        decoration: const InputDecoration(labelText: 'Giữa kỳ'),
                        keyboardType: TextInputType.text,
                        validator: validateSingleScore,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cuoiKyController,
                        decoration: const InputDecoration(labelText: 'Cuối kỳ'),
                        keyboardType: TextInputType.text,
                        validator: validateSingleScore,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Điểm trung bình hiện tại: ${grade?.average?.toStringAsFixed(1) ?? '--'}\nHệ thống sẽ tự động tính lại điểm trung bình sau khi lưu.',
                                style: const TextStyle(fontSize: 13, color: Colors.blue, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                          });
                          try {
                            await ApiService.upsertTeacherGrade(
                              teacher.id,
                              studentId: student.id,
                              semester: _selectedSemester,
                              subject: teacher.subject ?? '',
                              tx15: _parseScores(tx15Controller.text),
                              tx1tiet: _parseScores(tx1TietController.text),
                              giuaKy: _parseNullableDouble(giuaKyController.text),
                              cuoiKy: _parseNullableDouble(cuoiKyController.text),
                              average: null, // Let backend calculate it
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Khong the luu diem: $e')),
                            );
                            setDialogState(() {
                              isSaving = false;
                            });
                          }
                        },
                  child: const Text('Luu'),
                ),
              ],
            );
          },
        );
      },
    );

    tx15Controller.dispose();
    tx1TietController.dispose();
    giuaKyController.dispose();
    cuoiKyController.dispose();

    if (saved == true) {
      _loadData();
    }
  }

  List<double> _parseScores(String raw) {
    if (raw.trim().isEmpty) {
      return const [];
    }
    return raw
        .split(',')
        .map((value) => double.tryParse(value.trim()))
        .whereType<double>()
        .toList();
  }

  String _joinScores(List<double> scores) {
    return scores.map((value) => value.toString()).join(', ');
  }

  String _formatScores(List<double> scores) {
    if (scores.isEmpty) {
      return '--';
    }
    return scores.map((value) => value.toStringAsFixed(1)).join(', ');
  }

  String _formatNullable(double? value) {
    if (value == null) {
      return '--';
    }
    return value.toStringAsFixed(1);
  }

  double? _parseNullableDouble(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    return double.tryParse(raw.trim());
  }

  Color _gradeColor(double average) {
    if (average >= 9) return const Color(0xFF4CAF50);
    if (average >= 8) return const Color(0xFF2196F3);
    if (average >= 6.5) return const Color(0xFFFF9800);
    if (average >= 5) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}
