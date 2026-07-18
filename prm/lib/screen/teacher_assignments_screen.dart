import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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
        if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _assignments = assignments;
        _teacherClasses = teacherClasses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải bài tập: $e')),
      );
    }
  }

  Future<void> _deleteAssignment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa bài tập này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await ApiService.deleteTeacherAssignment(id);
        _loadAssignments();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài tập thành công')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa bài tập: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = _currentUser?.isTeacher ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isTeacher ? 'Bài tập đã giao' : 'Bài tập'),
        centerTitle: true,
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
        onPressed: _showCreateAssignmentDialog,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo bài tập'),
      )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
          ? Center(
        child: Text(
          isTeacher ? 'Bạn chưa giao bài tập nào' : 'Chưa có bài tập',
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
    if (user == null || !user.isTeacher) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final subjectController = TextEditingController(text: user.subject ?? '');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String? selectedClass = _teacherClasses.isNotEmpty ? _teacherClasses.first : null;
    PlatformFile? selectedFile;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo bài tập mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(labelText: 'Lớp'),
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
                      decoration: const InputDecoration(labelText: 'Môn học'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hạn nộp'),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedFile == null
                                ? 'Chưa chọn tài liệu đính kèm'
                                : 'Đính kèm: ${selectedFile!.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedFile == null ? Colors.grey : Colors.blue,
                              fontWeight: selectedFile == null ? FontWeight.normal : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.any,
                              allowMultiple: false,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                selectedFile = result.files.first;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
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
                    if ((selectedClass ?? '').isEmpty ||
                        titleController.text.trim().isEmpty ||
                        subjectController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đủ lớp, môn học và tiêu đề'),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      String? fileUrl;
                      if (selectedFile != null) {
                        List<int> bytes;
                        if (selectedFile!.bytes != null) {
                          bytes = selectedFile!.bytes!;
                        } else if (selectedFile!.path != null) {
                          bytes = await File(selectedFile!.path!).readAsBytes();
                        } else {
                          throw Exception('Không thể đọc dữ liệu file');
                        }
                        fileUrl = await ApiService.uploadFile(bytes, selectedFile!.name);
                      }

                      await ApiService.createTeacherAssignment(
                        user.id,
                        className: selectedClass!,
                        subject: subjectController.text.trim(),
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? titleController.text.trim()
                            : descriptionController.text.trim(),
                        dueDate: _formatDate(selectedDate),
                        fileUrl: fileUrl,
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không thể tạo bài tập: $e')),
                      );
                      setDialogState(() {
                        isSaving = false;
                      });
                    }
                  },
                  child: const Text('Lưu'),
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

  Future<void> _showEditAssignmentDialog(Assignment assignment) async {
    final titleController = TextEditingController(text: assignment.title);
    final descriptionController = TextEditingController(text: assignment.description);
    final subjectController = TextEditingController(text: assignment.subject);
    DateTime selectedDate = DateTime.parse(assignment.dueDate);
    String? selectedClass = assignment.className;
    PlatformFile? selectedFile;
    String? currentFileUrl = assignment.fileUrl;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa bài tập'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(labelText: 'Lớp'),
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
                      decoration: const InputDecoration(labelText: 'Môn học'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hạn nộp'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedFile != null
                                ? 'Đính kèm mới: ${selectedFile!.name}'
                                : (currentFileUrl != null && currentFileUrl!.isNotEmpty)
                                ? 'Đang có file đính kèm cũ'
                                : 'Chưa có file đính kèm',
                            style: TextStyle(
                              fontSize: 12,
                              color: (selectedFile != null || currentFileUrl != null) ? Colors.blue : Colors.grey,
                              fontWeight: (selectedFile != null || currentFileUrl != null) ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.any,
                              allowMultiple: false,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                selectedFile = result.files.first;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
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
                    if ((selectedClass ?? '').isEmpty ||
                        titleController.text.trim().isEmpty ||
                        subjectController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đủ lớp, môn học và tiêu đề'),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      String? fileUrl = currentFileUrl;
                      if (selectedFile != null) {
                        List<int> bytes;
                        if (selectedFile!.bytes != null) {
                          bytes = selectedFile!.bytes!;
                        } else if (selectedFile!.path != null) {
                          bytes = await File(selectedFile!.path!).readAsBytes();
                        } else {
                          throw Exception('Không thể đọc dữ liệu file');
                        }
                        fileUrl = await ApiService.uploadFile(bytes, selectedFile!.name);
                      }

                      await ApiService.updateTeacherAssignment(
                        assignment.id,
                        className: selectedClass!,
                        subject: subjectController.text.trim(),
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? titleController.text.trim()
                            : descriptionController.text.trim(),
                        dueDate: _formatDate(selectedDate),
                        fileUrl: fileUrl,
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không thể chỉnh sửa bài tập: $e')),
                      );
                      setDialogState(() {
                        isSaving = false;
                      });
                    }
                  },
                  child: const Text('Lưu'),
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

    if (updated == true) {
      _loadAssignments();
    }
  }

  void _showFileOptions(String fileUrl) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Sao chép đường dẫn tải tài liệu'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: fileUrl));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép link tài liệu vào bộ nhớ')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Xem tài liệu đính kèm'),
                subtitle: Text(fileUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(fileUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      throw Exception('canLaunchUrl returned false');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không thể mở tài liệu: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final isTeacher = _currentUser?.isTeacher ?? false;

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
                const Spacer(),
                if (isTeacher)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditAssignmentDialog(assignment);
                      } else if (value == 'delete') {
                        _deleteAssignment(assignment.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa bài tập'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              assignment.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(assignment.description),
            if (assignment.fileUrl != null && assignment.fileUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showFileOptions(assignment.fileUrl!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tài liệu đính kèm: ${assignment.fileUrl!.split('/').last}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
