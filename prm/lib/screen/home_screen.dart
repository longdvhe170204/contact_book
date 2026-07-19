import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'class_schedule_screen.dart';
import 'grades_screen.dart';
import 'notification_screen.dart';
import 'student_attendance_screen.dart';
import 'student_conduct_screen.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_conduct_screen.dart';
import 'teacher_students_screen.dart';
import 'chat_list_screen.dart';
import 'student_attendent_report.dart';
import 'invoice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  NotificationModel? _latestNotification;
  List<String> _teacherClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await StorageService.getCurrentUser();
      final notifications = await ApiService.getNotifications();
      List<String> teacherClasses = [];
      if (user != null && user.isTeacher) {
        teacherClasses = await ApiService.getTeacherClasses(user.id);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        _latestNotification = notifications.isNotEmpty ? notifications.first : null;
        _teacherClasses = teacherClasses;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Khong tim thay thong tin tai khoan')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, user),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: _buildFeatures(context, user),
              ),
              const SizedBox(height: 24),
              _buildReportSection(context, user),
              const SizedBox(height: 24),
              _buildNotificationCard(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: user.isTeacher ? const Color(0xFF1976D2) : const Color(0xFF42A5F5),
              ),
              const SizedBox(width: 12),
              const Text(
                'Báo cáo thống kê',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (user.isTeacher) ...[
            const Text(
              'Tỷ lệ đi học chuyên cần theo lớp:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (_teacherClasses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa có thông tin lớp học được phân công', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13)),
              )
            else
              ...List.generate(_teacherClasses.length, (index) {
                final className = _teacherClasses[index];
                final rate = index == 0 ? 0.962 : 0.95;
                final color = index == 0 ? const Color(0xFF4CAF50) : const Color(0xFF2196F3);
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _teacherClasses.length - 1 ? 0 : 10),
                  child: _buildClassBar('Lớp $className', rate, color),
                );
              }),
          ] else ...[
            const Text(
              'Chuyên cần học kỳ này của học sinh:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDonutChart(0.962),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Đúng giờ (96.2%)', const Color(0xFF4CAF50)),
                      const SizedBox(height: 6),
                      _buildLegendItem('Đi muộn (2.8%)', const Color(0xFFFF9800)),
                      const SizedBox(height: 6),
                      _buildLegendItem('Vắng mặt (1.0%)', const Color(0xFFF44336)),
                    ],
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildClassBar(String className, double rate, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(className, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${(rate * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChart(double rate) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: rate,
              backgroundColor: const Color(0xFFF44336).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              strokeWidth: 8,
            ),
          ),
          Text(
            '${(rate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF1976D2), size: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.headlineInfo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 24,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatures(BuildContext context, User user) {
    final items = <Widget>[
      _buildFeatureCard(
        title: user.isTeacher ? 'Lich day' : 'Thoi khoa bieu',
        icon: Icons.calendar_today,
        color: const Color(0xFF4CAF50),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => user.isTeacher
              ? const ClassScheduleScreen()
              : const StudentAttendanceScreen(),
          ),
        ),
      ),
      _buildFeatureCard(
        title: 'Bai tap',
        icon: Icons.assignment,
        color: const Color(0xFFFF9800),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TeacherAssignmentsScreen()),
        ),
      ),
      _buildFeatureCard(
        title: user.isTeacher ? 'Quan ly diem' : 'Diem so',
        icon: Icons.grade,
        color: const Color(0xFFE91E63),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GradesScreen()),
        ),
      ),
    ];

    if (user.isTeacher) {
      items.add(
        _buildFeatureCard(
          title: 'Lop hoc',
          icon: Icons.groups,
          color: const Color(0xFF9C27B0),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeacherStudentsScreen()),
          ),
        ),
      );
    }

    items.addAll([
      _buildFeatureCard(
        title: 'Thong bao',
        icon: Icons.notifications,
        color: const Color(0xFFF44336),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        ),
      ),
      _buildFeatureCard(
        title: user.isTeacher ? 'Diem danh lop' : 'Diem danh Report',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF00BCD4),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => user.isTeacher
                ? const TeacherAttendanceScreen()
                : const StudentAttendanceReportScreen(),
          ),
        ),
      ),
      _buildFeatureCard(
        title: user.isTeacher ? 'Hanh kiem lop' : 'Hanh kiem',
        icon: Icons.star_border,
        color: const Color(0xFFFF5722),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => user.isTeacher
                ? const TeacherConductScreen()
                : const StudentConductScreen(),
          ),
        ),
      ),
      _buildFeatureCard(
        title: 'Tin nhắn',
        icon: Icons.message,
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        ),
      ),
    ]);

    // Chỉ hiện mục Học phí cho học sinh
    if (!user.isTeacher) {
      items.add(
        _buildFeatureCard(
          title: 'Học phí',
          icon: Icons.payment,
          color: const Color(0xFF009688),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InvoiceScreen()),
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildNotificationCard(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active, color: Color(0xFF1976D2)),
                  SizedBox(width: 12),
                  Text(
                    'Thong bao moi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _latestNotification?.title ?? 'Chua co thong bao moi',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _latestNotification?.date ?? 'He thong se cap nhat som',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (user.isTeacher) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Ban dang quan ly ${user.subject ?? 'cac mon duoc phan cong'} va co the cap nhat bai tap, diem so truc tiep tu ung dung.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
