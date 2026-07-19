import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String? _error;
  int? _payingInvoiceId;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final user = await StorageService.getCurrentUser();
      if (user == null) return;
      final invoices = await ApiService.getInvoices(user.id);
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách hóa đơn';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePayment(Map<String, dynamic> invoice) async {
    setState(() => _payingInvoiceId = invoice['id']);
    try {
      final paymentUrl = await ApiService.createVNPayPaymentUrl(invoice['id']);
      if (!mounted) return;

      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Không thể mở trang thanh toán. Vui lòng thử lại.');
      }
    } catch (e) {
      _showError('Lỗi tạo thanh toán: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _payingInvoiceId = null);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PAID': return 'Đã thanh toán';
      case 'CANCELLED': return 'Đã hủy';
      default: return 'Chờ thanh toán';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 đ';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Học phí', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; _error = null; });
              _loadInvoices();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadInvoices, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _invoices.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Không có hóa đơn nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _invoices[index];
                        final status = invoice['status'] ?? 'PENDING';
                        final isPaid = status == 'PAID';
                        final isPaying = _payingInvoiceId == invoice['id'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        invoice['title'] ?? 'Hóa đơn học phí',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  invoice['description'] ?? '',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Số tiền', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        Text(
                                          _formatCurrency(invoice['amount']),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2196F3)),
                                        ),
                                      ],
                                    ),
                                    if (!isPaid)
                                      ElevatedButton.icon(
                                        onPressed: isPaying ? null : () => _handlePayment(invoice),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2196F3),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                                        icon: isPaying
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Icon(Icons.payment, size: 18),
                                        label: Text(isPaying ? 'Đang xử lý...' : 'Thanh toán VNPay'),
                                      )
                                    else
                                      const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
