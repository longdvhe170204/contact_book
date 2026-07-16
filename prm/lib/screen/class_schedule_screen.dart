import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ClassScheduleScreen extends StatefulWidget {
  const ClassScheduleScreen({super.key});

  @override
  State<ClassScheduleScreen> createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen> {
  final List<String> _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final List<String> _weekDaysFull = [
    'Thu 2',
    'Thu 3',
    'Thu 4',
    'Thu 5',
    'Thu 6',
    'Thu 7',
    'Chu nhat',
  ];

  int _selectedDay = 0;
  User? _currentUser;
  bool _isLoading = true;
  List<Schedule> _allTeacherSchedules = [];
  List<Schedule> _visibleSchedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
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

      List<Schedule> schedules;
      List<Schedule> allTeacherSchedules = _allTeacherSchedules;

      if (user.isTeacher) {
        if (allTeacherSchedules.isEmpty) {
          allTeacherSchedules = await ApiService.getTeacherSchedules(user.id);
        }
        schedules = allTeacherSchedules
            .where((schedule) => schedule.dayOfWeek == _selectedDay)
            .toList();
      } else {
        final className = user.className;
        schedules = className == null || className.isEmpty
            ? const []
            : await ApiService.getSchedulesByDay(className, _selectedDay);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        _allTeacherSchedules = allTeacherSchedules;
        _visibleSchedules = schedules;
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
        SnackBar(content: Text('Loi khi tai thoi khoa bieu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final isTeacher = user?.isTeacher ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isTeacher ? 'Lich giang day' : 'Thoi khoa bieu'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoChip(
                  isTeacher
                      ? 'Bo mon: ${user?.subject ?? '--'}'
                      : 'Lop: ${user?.className ?? '--'}',
                ),
                _buildInfoChip(_weekDaysFull[_selectedDay]),
              ],
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedDay == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = index;
                    });
                    _loadSchedules();
                  },
                  child: Container(
                    width: 56,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1976D2) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1976D2)),
                    ),
                    child: Center(
                      child: Text(
                        _weekDays[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _visibleSchedules.isEmpty
                    ? const Center(child: Text('Khong co lich trong ngay nay'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _visibleSchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = _visibleSchedules[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        schedule.period,
                                        style: const TextStyle(
                                          color: Color(0xFF1976D2),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(isTeacher ? 'Lop: ${schedule.className}' : 'Giao vien: ${schedule.teacher}'),
                                  Text('Phong: ${schedule.room}'),
                                  Text('Thoi gian: ${schedule.startTime} - ${schedule.endTime}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
