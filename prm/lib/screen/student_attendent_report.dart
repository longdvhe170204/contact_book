import 'package:flutter/material.dart';

import '../models/attendance.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class StudentAttendanceReportScreen extends StatefulWidget {
  const StudentAttendanceReportScreen({super.key});

  @override
  State<StudentAttendanceReportScreen> createState() =>
      _StudentAttendanceReportScreenState();
}

class _StudentAttendanceReportScreenState extends State<StudentAttendanceReportScreen> {
  User? _student;
  List<Attendance> _attendances = [];
  bool _isLoading = true;
  String? _errorMessage;

  int get _total => _attendances.length;
  int get _present =>
      _attendances.where((item) => item.status == 'PRESENT').length;
  int get _late => _attendances.where((item) => item.status == 'LATE').length;
  int get _absent =>
      _attendances.where((item) => item.status == 'ABSENT').length;

  // Đi muộn vẫn được tính là đã tham gia buổi học.
  double get _attendanceRate =>
      _total == 0 ? 0 : ((_present + _late) / _total) * 100;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = await StorageService.getCurrentUser();
      if (user == null) {
        throw Exception('Không tìm thấy thông tin học sinh');
      }

      final attendances = await ApiService.getStudentAttendance(user.id);
      attendances.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _student = user;
        _attendances = attendances;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải báo cáo chuyên cần. Vui lòng thử lại.';
      });
    }
  }

  Color get _rateColor {
    if (_attendanceRate >= 90) return const Color(0xFF2E7D32);
    if (_attendanceRate >= 80) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  String get _rateMessage {
    if (_total == 0) return 'Chưa có dữ liệu điểm danh';
    if (_attendanceRate >= 95) return 'Chuyên cần rất tốt';
    if (_attendanceRate >= 90) return 'Chuyên cần tốt';
    if (_attendanceRate >= 80) return 'Cần duy trì đều đặn hơn';
    return 'Cần cải thiện chuyên cần';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PRESENT':
        return 'Có mặt';
      case 'ABSENT':
        return 'Vắng';
      case 'LATE':
        return 'Đi muộn';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PRESENT':
        return const Color(0xFF2E7D32);
      case 'ABSENT':
        return const Color(0xFFC62828);
      case 'LATE':
        return const Color(0xFFF57F17);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PRESENT':
        return Icons.check_circle;
      case 'ABSENT':
        return Icons.cancel;
      case 'LATE':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _displayDate(String rawDate) {
    final parts = rawDate.split('-');
    if (parts.length != 3) return rawDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Báo cáo chuyên cần'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _loadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildStudentCard(),
        const SizedBox(height: 16),
        _buildAttendanceRateCard(),
        const SizedBox(height: 16),
        _buildSummaryGrid(),
        const SizedBox(height: 22),
        const Text(
          'Lịch sử điểm danh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_attendances.isEmpty)
          _buildEmptyHistory()
        else
          ..._attendances.map(_buildHistoryCard),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStudentCard() {
    final name = _student?.name.isNotEmpty == true ? _student!.name : 'Học sinh';
    final className = _student?.className;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (className != null && className.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lớp $className',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRateCard() {
    final progress = (_attendanceRate / 100).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 118,
              height: 118,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_rateColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_attendanceRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _rateColor,
                        ),
                      ),
                      const Text(
                        'chuyên cần',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng quan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rateMessage,
                    style: TextStyle(
                      color: _rateColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã tham gia ${_present + _late} trên $_total buổi được điểm danh.',
                    style: TextStyle(color: Colors.grey[700], height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đi muộn được tính là có tham gia.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Có mặt',
            value: _present,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'Đi muộn',
            value: _late,
            icon: Icons.schedule,
            color: const Color(0xFFF9A825),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: 'Vắng',
            value: _absent,
            icon: Icons.cancel_outlined,
            color: const Color(0xFFC62828),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available, size: 54, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu điểm danh',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Attendance attendance) {
    final color = _statusColor(attendance.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon(attendance.status), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          attendance.subject?.isNotEmpty == true
                              ? attendance.subject!
                              : 'Buổi học',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _displayDate(attendance.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(attendance.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (attendance.className?.isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Lớp ${attendance.className}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  if (attendance.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      attendance.note!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
