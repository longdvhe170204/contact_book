import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  User? _currentUser;
  List<User> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await StorageService.getCurrentUser();
      if (user == null) return;

      List<User> contacts = [];
      if (user.isTeacher) {
        contacts = await ApiService.getTeacherStudents(user.id);
      } else {
        contacts = await ApiService.getStudentTeachers(user.id);
      }

      setState(() {
        _currentUser = user;
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('Chưa có liên hệ nào'))
              : ListView.separated(
                  itemCount: _contacts.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          contact.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(
                        contact.isTeacher 
                            ? (contact.subject ?? 'Giáo viên') 
                            : 'Lớp ${contact.className ?? 'N/A'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        if (_currentUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentUser: _currentUser!,
                                otherUser: contact,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
