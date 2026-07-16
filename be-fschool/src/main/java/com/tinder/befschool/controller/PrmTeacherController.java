package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.schedule.LegacyScheduleResponse;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.security.UserDetailsImpl;
import com.tinder.befschool.service.PrmCompatibilityService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Compatibility endpoints for the existing PRM API contract. */
@RestController
@RequestMapping("/api/teachers/{teacherId}")
@PreAuthorize("hasRole('TEACHER')")
public class PrmTeacherController {
    private final PrmCompatibilityService service;

    public PrmTeacherController(PrmCompatibilityService service) {
        this.service = service;
    }

    @GetMapping("/classes")
    public ResponseEntity<ApiResponse<List<String>>> classes(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @PathVariable Long teacherId) {
        return ok(service.findTeacherClasses(currentUser.getId(), teacherId), "Lấy danh sách lớp thành công");
    }

    @GetMapping("/students")
    public ResponseEntity<ApiResponse<List<User>>> students(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @PathVariable Long teacherId,
            @RequestParam(required = false) String className) {
        return ok(service.findTeacherStudents(currentUser.getId(), teacherId, className),
                "Lấy danh sách học sinh thành công");
    }

    @GetMapping("/schedules")
    public ResponseEntity<ApiResponse<List<LegacyScheduleResponse>>> schedules(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @PathVariable Long teacherId) {
        return ok(service.findTeacherSchedules(currentUser.getId(), teacherId), "Lấy lịch dạy thành công");
    }

    private <T> ResponseEntity<ApiResponse<T>> ok(T data, String message) {
        return ResponseEntity.ok(new ApiResponse<>(true, data, message));
    }
}
