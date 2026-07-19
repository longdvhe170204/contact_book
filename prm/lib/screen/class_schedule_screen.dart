import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ClassScheduleScreen extends StatefulWidget {
  const ClassScheduleScreen({super.key});

  @override
  State<ClassScheduleScreen> createState() =>
      _ClassScheduleScreenState();
}

class _ClassScheduleScreenState
    extends State<ClassScheduleScreen> {
  final List<String> _weekDays = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  final List<String> _weekDaysFull = [
    'Thứ 2',
    'Thứ 3',
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];

  int _selectedDay = 0;

  User? _currentTeacher;

  bool _isLoading = true;

  List<Schedule> _allSchedules = [];
  List<Schedule> _visibleSchedules = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = await StorageService.getCurrentUser();

    if (!mounted) return;

    if (user == null || !user.isTeacher) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy thông tin giáo viên',
          ),
        ),
      );

      return;
    }

    setState(() {
      _currentTeacher = user;
    });

    await _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final teacher = _currentTeacher;

    if (teacher == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final schedules =
      await ApiService.getTeacherSchedules(
        teacher.id,
      );

      schedules.sort((a, b) {
        final dayCompare =
        a.dayOfWeek.compareTo(b.dayOfWeek);

        if (dayCompare != 0) {
          return dayCompare;
        }

        return _periodNumber(a.period).compareTo(
          _periodNumber(b.period),
        );
      });

      if (!mounted) return;

      setState(() {
        _allSchedules = schedules;
        _visibleSchedules = schedules
            .where(
              (schedule) =>
          schedule.dayOfWeek ==
              _selectedDay,
        )
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi tải lịch giảng dạy: $error',
          ),
        ),
      );
    }
  }

  void _selectDay(int index) {
    setState(() {
      _selectedDay = index;

      _visibleSchedules = _allSchedules
          .where(
            (schedule) =>
        schedule.dayOfWeek == index,
      )
          .toList();
    });
  }

  int _periodNumber(String? period) {
    final value = period?.trim() ?? '';
    final match = RegExp(r'\d+').firstMatch(value);

    return int.tryParse(
      match?.group(0) ?? '',
    ) ??
        999;
  }

  String _formatPeriod(String? period) {
    final value = period?.trim() ?? '';

    if (value.isEmpty) {
      return 'Chưa có tiết';
    }

    final normalized = value.toLowerCase();

    if (normalized.startsWith('tiết') ||
        normalized.startsWith('tiet')) {
      return value;
    }

    return 'Tiết $value';
  }

  String _formatRoom(String? room) {
    final value = room?.trim() ?? '';

    return value.isEmpty
        ? 'Chưa cập nhật'
        : value;
  }

  String _formatTime(
      String? startTime,
      String? endTime,
      ) {
    final start = startTime?.trim() ?? '';
    final end = endTime?.trim() ?? '';

    if (start.isEmpty && end.isEmpty) {
      return 'Chưa cập nhật';
    }

    if (start.isEmpty) return end;
    if (end.isEmpty) return start;

    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
        const Color(0xFF1F2937),
        title: const Text(
          'Lịch giảng dạy',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildDaySelector(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
              const Color(0xFFE3F2FD),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch trong tuần',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bộ môn: '
                      '${_currentTeacher?.subject ?? '--'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color:
              const Color(0xFFF1F5F9),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Text(
              _weekDaysFull[_selectedDay],
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        itemCount: _weekDays.length,
        itemBuilder: (context, index) {
          final isSelected =
              _selectedDay == index;

          return GestureDetector(
            onTap: () => _selectDay(index),
            child: AnimatedContainer(
              duration:
              const Duration(milliseconds: 180),
              width: 52,
              margin:
              const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1976D2)
                    : Colors.white,
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(
                    0xFF1976D2,
                  )
                      : const Color(
                    0xFFE2E8F0,
                  ),
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(
                      0xFF1976D2,
                    ).withOpacity(0.22),
                    blurRadius: 10,
                    offset:
                    const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: Center(
                child: Text(
                  _weekDays[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(
                      0xFF475569,
                    ),
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_visibleSchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color:
                const Color(0xFFEFF6FF),
                borderRadius:
                BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                size: 34,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không có lịch giảng dạy',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Không có tiết học trong '
                  '${_weekDaysFull[_selectedDay]}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          20,
        ),
        itemCount: _visibleSchedules.length,
        itemBuilder: (context, index) {
          return _buildScheduleCard(
            _visibleSchedules[index],
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(
      Schedule schedule,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          const Color(0xFFE6EAF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    schedule.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFEFF6FF),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatPeriod(
                      schedule.period,
                    ),
                    style: const TextStyle(
                      color:
                      Color(0xFF1976D2),
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildScheduleInfo(
              icon: Icons.groups_2_outlined,
              label: 'Lớp',
              value: schedule.className,
            ),
            const SizedBox(height: 10),
            _buildScheduleInfo(
              icon: Icons.meeting_room_outlined,
              label: 'Phòng',
              value:
              _formatRoom(schedule.room),
            ),
            const SizedBox(height: 10),
            _buildScheduleInfo(
              icon: Icons.access_time_rounded,
              label: 'Thời gian',
              value: _formatTime(
                schedule.startTime,
                schedule.endTime,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
            const Color(0xFFF8FAFC),
            borderRadius:
            BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color:
            const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}