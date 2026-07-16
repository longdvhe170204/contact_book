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
}
