package com.tinder.befschool.service;

import com.tinder.befschool.config.VNPayConfig;
import com.tinder.befschool.entity.Invoice;
import com.tinder.befschool.entity.Transaction;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.repository.InvoiceRepository;
import com.tinder.befschool.repository.TransactionRepository;
import com.tinder.befschool.repository.UserRepository;
import com.tinder.befschool.util.VNPayUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;

@Service
public class VNPayService {

    @Autowired
    private VNPayConfig vnPayConfig;

    @Autowired
    private InvoiceRepository invoiceRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Tạo danh sách Hóa đơn mẫu cho học sinh (demo)
     */
    public List<Invoice> getInvoicesByStudentId(Long studentId) {
        return invoiceRepository.findByStudent_Id(studentId);
    }

    /**
     * Tạo URL thanh toán VNPay cho một hóa đơn
     */
    public String createPaymentUrl(Long invoiceId, String ipAddress) {
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hóa đơn"));

        if ("PAID".equals(invoice.getStatus())) {
            throw new RuntimeException("Hóa đơn này đã được thanh toán");
        }

        // Tạo mã đơn hàng duy nhất (dùng để đối soát)
        String vnpTxnRef = VNPayUtil.getRandomNumber(8);
        long amount = invoice.getAmount().multiply(BigDecimal.valueOf(100)).longValue(); // VNPay tính theo đơn vị 1/100 VNĐ

        // Lưu transaction vào DB với trạng thái PENDING
        Transaction transaction = Transaction.builder()
                .invoice(invoice)
                .vnpTxnRef(vnpTxnRef)
                .amount(invoice.getAmount())
                .status("PENDING")
                .build();
        transactionRepository.save(transaction);

        // Tạo các tham số gửi sang VNPay theo đúng tài liệu chuẩn
        Map<String, String> vnpParams = new TreeMap<>();
        vnpParams.put("vnp_Version", "2.1.0");
        vnpParams.put("vnp_Command", "pay");
        vnpParams.put("vnp_TmnCode", vnPayConfig.getVnp_TmnCode());
        vnpParams.put("vnp_Amount", String.valueOf(amount));
        vnpParams.put("vnp_CurrCode", "VND");
        vnpParams.put("vnp_BankCode", "");
        vnpParams.put("vnp_TxnRef", vnpTxnRef);
        vnpParams.put("vnp_OrderInfo", "Thanh toan hoc phi: " + invoice.getTitle());
        vnpParams.put("vnp_OrderType", "other");
        vnpParams.put("vnp_Locale", "vn");
        vnpParams.put("vnp_ReturnUrl", vnPayConfig.getVnp_ReturnUrl());
        vnpParams.put("vnp_IpAddr", ipAddress);

        // Thêm timestamp
        Calendar cld = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
        String vnpCreateDate = formatter.format(cld.getTime());
        vnpParams.put("vnp_CreateDate", vnpCreateDate);

        // Thêm thời gian hết hạn (15 phút)
        cld.add(Calendar.MINUTE, 15);
        String vnpExpireDate = formatter.format(cld.getTime());
        vnpParams.put("vnp_ExpireDate", vnpExpireDate);

        // Tạo chuỗi dữ liệu để ký
        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();
        Iterator<Map.Entry<String, String>> itr = vnpParams.entrySet().iterator();
        while (itr.hasNext()) {
            Map.Entry<String, String> entry = itr.next();
            if (entry.getValue() != null && !entry.getValue().isEmpty()) {
                hashData.append(entry.getKey()).append("=")
                        .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
                query.append(URLEncoder.encode(entry.getKey(), StandardCharsets.US_ASCII))
                        .append("=")
                        .append(URLEncoder.encode(entry.getValue(), StandardCharsets.US_ASCII));
                if (itr.hasNext()) {
                    query.append("&");
                    hashData.append("&");
                }
            }
        }

        // Ký HMAC-SHA512
        String secureHash = VNPayUtil.hmacSHA512(vnPayConfig.getSecretKey(), hashData.toString());
        query.append("&vnp_SecureHash=").append(secureHash);

        return vnPayConfig.getVnp_PayUrl() + "?" + query;
    }

    /**
     * Xử lý callback từ VNPay (Return URL) sau khi người dùng thanh toán xong
     */
    public boolean handleVNPayReturn(Map<String, String> fields) {
        String vnpSecureHash = fields.remove("vnp_SecureHash");
        fields.remove("vnp_SecureHashType");

        // Xác thực chữ ký
        String signValue = VNPayUtil.hashAllFields(fields, vnPayConfig.getSecretKey());
        if (!signValue.equals(vnpSecureHash)) {
            return false; // Chữ ký không hợp lệ, có thể bị giả mạo
        }

        String vnpResponseCode = fields.get("vnp_ResponseCode");
        String vnpTxnRef = fields.get("vnp_TxnRef");
        String vnpTransactionNo = fields.get("vnp_TransactionNo");

        Optional<Transaction> txnOpt = transactionRepository.findByVnpTxnRef(vnpTxnRef);
        if (txnOpt.isEmpty()) {
            return false;
        }

        Transaction txn = txnOpt.get();
        if ("00".equals(vnpResponseCode)) {
            // Thanh toán thành công
            txn.setStatus("SUCCESS");
            txn.setVnpTransactionNo(vnpTransactionNo);
            txn.setPaymentDate(java.time.LocalDateTime.now());
            transactionRepository.save(txn);

            // Cập nhật trạng thái hóa đơn thành PAID
            Invoice invoice = txn.getInvoice();
            invoice.setStatus("PAID");
            invoiceRepository.save(invoice);
            return true;
        } else {
            txn.setStatus("FAILED");
            transactionRepository.save(txn);
            return false;
        }
    }
}
