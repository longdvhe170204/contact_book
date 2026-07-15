import 'package:flutter/material.dart';
import '../models/conduct.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class StudentConductScreen extends StatefulWidget {
  const StudentConductScreen({super.key});

  @override
  State<StudentConductScreen> createState() => _StudentConductScreenState();
}

class _StudentConductScreenState extends State<StudentConductScreen> {
  List<Conduct> _conducts = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await StorageService.getCurrentUser();
      if (user == null || !mounted) return;
      final conducts = await ApiService.getStudentConduct(user.id);
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _conducts = conducts;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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

  IconData _ratingIcon(String rating) {
    switch (rating) {
      case 'EXCELLENT':
        return Icons.star;
      case 'GOOD':
        return Icons.thumb_up;
      case 'AVERAGE':
        return Icons.thumbs_up_down;
      case 'WEAK':
        return Icons.thumb_down;
      default:
        return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conducts.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: _conducts.map(_buildConductCard).toList(),
                        ),
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
                    Icon(Icons.star_outline, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Hạnh kiểm',
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

  Widget _buildConductCard(Conduct c) {
    final color = _ratingColor(c.conductRating);
    final icon = _ratingIcon(c.conductRating);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tháng ${c.month}/${c.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Hạnh kiểm: ${c.ratingLabel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.teacherName != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        'GV. nhận xét: ${c.teacherName}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (c.comment != null && c.comment!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      c.comment!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ] else
                  Text(
                    'Chưa có lời nhận xét.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có nhận xét nào',
            style: TextStyle(fontSize: 17, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
