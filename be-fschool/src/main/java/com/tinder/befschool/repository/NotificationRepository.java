package com.tinder.befschool.repository;

import com.tinder.befschool.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByCategoryOrderByCreatedAtDesc(String category);
    List<Notification> findAllByOrderByCreatedAtDesc();
}
