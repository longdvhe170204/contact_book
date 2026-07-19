package com.tinder.befschool.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transactions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @Column(name = "vnp_txn_ref", nullable = false, unique = true)
    private String vnpTxnRef; // Mã đơn hàng tự sinh gửi sang VNPay

    @Column(name = "vnp_transaction_no")
    private String vnpTransactionNo; // Mã giao dịch do VNPay trả về

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String status; // PENDING, SUCCESS, FAILED

    private LocalDateTime paymentDate;

    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if(status == null) status = "PENDING";
    }
}
