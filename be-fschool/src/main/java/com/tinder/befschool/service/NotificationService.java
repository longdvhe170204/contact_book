package com.tinder.befschool.service;

import com.tinder.befschool.entity.Notification;

import java.util.List;

public interface NotificationService {
    List<Notification> findAll();
    List<Notification> findByCategory(String category);
}
