package com.tinder.befschool.controller;

import com.tinder.befschool.entity.Invoice;
import com.tinder.befschool.service.VNPayService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@CrossOrigin(origins = "*")
public class PaymentController {

    @Autowired
    private VNPayService vnPayService;

    /**
     * Lấy danh sách hóa đơn của học sinh
     */
    @GetMapping("/invoices/{studentId}")
    public ResponseEntity<List<Invoice>> getInvoices(@PathVariable Long studentId) {
        List<Invoice> invoices = vnPayService.getInvoicesByStudentId(studentId);
        return ResponseEntity.ok(invoices);
    }

    /**
     * Tạo URL thanh toán VNPay cho hóa đơn
     * Flutter gọi API này -> nhận URL -> mở webview
     */
    @PostMapping("/vnpay/create-payment")
    public ResponseEntity<Map<String, String>> createPayment(
            @RequestParam Long invoiceId,
            HttpServletRequest request) {
        try {
            String ipAddress = request.getHeader("X-Forwarded-For");
            if (ipAddress == null) {
                ipAddress = request.getRemoteAddr();
            }

            String paymentUrl = vnPayService.createPaymentUrl(invoiceId, ipAddress);

            Map<String, String> response = new HashMap<>();
            response.put("paymentUrl", paymentUrl);
            response.put("status", "success");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Endpoint nhận callback từ VNPay sau khi người dùng thanh toán xong
     * VNPay sẽ redirect người dùng về URL này với kết quả thanh toán
     */
    @GetMapping("/vnpay/return")
    public ResponseEntity<String> vnpayReturn(HttpServletRequest request) {
        Map<String, String> fields = new HashMap<>();
        for (Map.Entry<String, String[]> entry : request.getParameterMap().entrySet()) {
            if (entry.getKey().startsWith("vnp_")) {
                fields.put(entry.getKey(), entry.getValue()[0]);
            }
        }

        boolean isSuccess = vnPayService.handleVNPayReturn(fields);
        String responseCode = fields.getOrDefault("vnp_ResponseCode", "99");

        String htmlContent;
        if (isSuccess) {
            htmlContent = """
                <!DOCTYPE html>
                <html lang="vi">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Thanh toán thành công</title>
                  <style>
                    body { font-family: Arial, sans-serif; display: flex; justify-content: center;
                           align-items: center; min-height: 100vh; margin: 0; background: #f0fdf4; }
                    .card { background: white; border-radius: 16px; padding: 40px 32px;
                            text-align: center; box-shadow: 0 4px 24px rgba(0,0,0,0.1); max-width: 340px; }
                    .icon { font-size: 64px; margin-bottom: 16px; }
                    h2 { color: #16a34a; margin: 0 0 8px; }
                    p { color: #6b7280; margin: 0 0 24px; }
                    a { display: block; background: #2196F3; color: white; text-decoration: none;
                        padding: 14px 24px; border-radius: 12px; font-weight: bold; font-size: 16px; }
                    a:active { opacity: 0.8; }
                  </style>
                </head>
                <body>
                  <div class="card">
                    <div class="icon">✅</div>
                    <h2>Thanh toán thành công!</h2>
                    <p>Giao dịch đã được xác nhận.<br>Hóa đơn đã được cập nhật trạng thái PAID.</p>
                    <a href="fschool://vnpay?success=true">← Quay lại ứng dụng</a>
                  </div>
                </body>
                </html>
                """;
        } else {
            htmlContent = """
                <!DOCTYPE html>
                <html lang="vi">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <title>Thanh toán thất bại</title>
                  <style>
                    body { font-family: Arial, sans-serif; display: flex; justify-content: center;
                           align-items: center; min-height: 100vh; margin: 0; background: #fef2f2; }
                    .card { background: white; border-radius: 16px; padding: 40px 32px;
                            text-align: center; box-shadow: 0 4px 24px rgba(0,0,0,0.1); max-width: 340px; }
                    .icon { font-size: 64px; margin-bottom: 16px; }
                    h2 { color: #dc2626; margin: 0 0 8px; }
                    p { color: #6b7280; margin: 0 0 24px; }
                    a { display: block; background: #6b7280; color: white; text-decoration: none;
                        padding: 14px 24px; border-radius: 12px; font-weight: bold; font-size: 16px; }
                  </style>
                </head>
                <body>
                  <div class="card">
                    <div class="icon">❌</div>
                    <h2>Thanh toán thất bại</h2>
                    <p>Mã lỗi: %s<br>Vui lòng thử lại.</p>
                    <a href="fschool://vnpay?success=false&code=%s">← Quay lại ứng dụng</a>
                  </div>
                </body>
                </html>
                """.formatted(responseCode, responseCode);
        }

        return ResponseEntity.ok()
                .header("Content-Type", "text/html; charset=UTF-8")
                .body(htmlContent);
    }
}
