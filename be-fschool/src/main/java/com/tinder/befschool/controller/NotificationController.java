package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.entity.Notification;
import com.tinder.befschool.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Notification>>> getAll() {
        return ResponseEntity.ok(new ApiResponse<>(true, notificationService.findAll(), "OK"));
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<ApiResponse<List<Notification>>> getByCategory(@PathVariable String category) {
        return ResponseEntity.ok(new ApiResponse<>(true, notificationService.findByCategory(category), "OK"));
    }
}
