package com.tinder.befschool.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendNewPassword(String to, String newPassword) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(to);
            message.setSubject("Mật khẩu mới cho tài khoản FSchool của bạn");
            message.setText("Chào bạn,\n\nMật khẩu mới của bạn là: " + newPassword + 
                    "\n\nVui lòng đăng nhập và đổi mật khẩu ngay để bảo mật tài khoản.\n\nTrân trọng,\nĐội ngũ FSchool");
            
            mailSender.send(message);
            logger.info("Email sent successfully to {}", to);
        } catch (Exception e) {
            logger.error("Failed to send email to {}: {}", to, e.getMessage());
        }
    }

    public void sendAssignmentNotification(String to, String studentName, String teacherName, String subject, String title, String dueDate) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(to);
            message.setSubject("[FSchool] Thông báo bài tập mới: " + subject);
            
            String content = String.format(
                "Chào %s,\n\n" +
                "Bạn có một bài tập mới từ giáo viên %s.\n\n" +
                "Môn học: %s\n" +
                "Tiêu đề: %s\n" +
                "Hạn nộp: %s\n\n" +
                "Vui lòng đăng nhập vào hệ thống để xem chi tiết và làm bài đúng hạn.\n\n" +
                "Trân trọng,\n" +
                "Hệ thống giáo dục FSchool",
                studentName, teacherName, subject, title, dueDate
            );
            
            message.setText(content);
            mailSender.send(message);
            logger.info("Assignment notification email sent successfully to {}", to);
        } catch (Exception e) {
            logger.error("Failed to send assignment notification to {}: {}", to, e.getMessage());
        }
    }
}
