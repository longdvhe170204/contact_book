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
  bool _isLoading = true;
  User? _currentUser;

  final List<String> _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
  }

    try {
      final user = await StorageService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Color _statusColor(String status) {
    switch (status) {
    }
  }

    switch (status) {
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
                          children: [
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
                    SizedBox(width: 12),
                    Text(
                      'Chuyên cần',
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

    return Container(
        color: Colors.white,
        children: [
          ),
            children: [
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF1976D2)),
            onPressed: _nextWeek,
          ),
        ],
      ),
    );
  }

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
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

      decoration: BoxDecoration(
          ),
        ],
      ),
        children: [
          Container(
            decoration: BoxDecoration(
            ),
              children: [
                Text(
                  ),
                ],
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
        children: [
          ),
        ],
      ),
    );
  }
}
