package com.tinder.befschool.service.impl;

import com.tinder.befschool.entity.Notification;
import com.tinder.befschool.repository.NotificationRepository;
import com.tinder.befschool.service.NotificationService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;

    public NotificationServiceImpl(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Override
    public List<Notification> findAll() {
        return notificationRepository.findAllByOrderByCreatedAtDesc();
    }

    @Override
    public List<Notification> findByCategory(String category) {
        return notificationRepository.findByCategoryOrderByCreatedAtDesc(category);
    }

    @Override
    public Notification createNotification(Notification notification) {
        notification.setCreatedAtCustom(java.time.LocalDateTime.now());
        if(notification.getDate() == null || notification.getDate().isBlank()) {
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
            notification.setDate(notification.getCreatedAtCustom().format(formatter));
        }
        return notificationRepository.save(notification);
    }

    @Override
    public void deleteNotification(Long id) {
        notificationRepository.deleteById(id);
    }
}
