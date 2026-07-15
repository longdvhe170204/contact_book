import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  User? _currentUser;
  List<Assignment> _assignments = [];
  List<String> _teacherClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await StorageService.getCurrentUser();
      if (user == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<Assignment> assignments;
      List<String> teacherClasses = const [];

      if (user.isTeacher) {
        assignments = await ApiService.getTeacherAssignments(user.id);
        teacherClasses = await ApiService.getTeacherClasses(user.id);
      } else {
        final className = user.className;
        assignments = className == null || className.isEmpty
            ? const []
            : await ApiService.getAssignments(className);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        _assignments = assignments;
        _teacherClasses = teacherClasses;
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
        SnackBar(content: Text('Loi khi tai bai tap: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _currentUser?.isTeacher ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isTeacher ? 'Bai tap da giao' : 'Bai tap'),
        centerTitle: true,
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: _showCreateAssignmentDialog,
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tao bai tap'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? Center(
                  child: Text(
                    isTeacher ? 'Ban chua giao bai tap nao' : 'Chua co bai tap',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAssignments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = _assignments[index];
                      return _buildAssignmentCard(assignment);
                    },
                  ),
                ),
    );
  }

  Future<void> _showCreateAssignmentDialog() async {
    final user = _currentUser;
    if (user == null || !user.isTeacher) {
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final subjectController = TextEditingController(text: user.subject ?? '');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String? selectedClass = _teacherClasses.isNotEmpty ? _teacherClasses.first : null;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tao bai tap moi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(labelText: 'Lop'),
                      items: _teacherClasses
                          .map((className) => DropdownMenuItem<String>(
                                value: className,
                                child: Text(className),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedClass = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(labelText: 'Mon hoc'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tieu de'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mo ta'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Han nop'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Huy'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if ((selectedClass ?? '').isEmpty ||
                              titleController.text.trim().isEmpty ||
                              subjectController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui long nhap du lop, mon hoc va tieu de'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await ApiService.createTeacherAssignment(
                              user.id,
                              className: selectedClass!,
                              subject: subjectController.text.trim(),
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim().isEmpty
                                  ? titleController.text.trim()
                                  : descriptionController.text.trim(),
                              dueDate: _formatDate(selectedDate),
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Khong the tao bai tap: $e')),
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

    titleController.dispose();
    descriptionController.dispose();
    subjectController.dispose();

    if (created == true) {
      _loadAssignments();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    assignment.subject,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(assignment.className, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              assignment.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(assignment.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(assignment.teacher, style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  assignment.dueDate,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
