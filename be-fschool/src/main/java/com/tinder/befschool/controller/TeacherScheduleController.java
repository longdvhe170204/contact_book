package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.schedule.ScheduleResponse;
import com.tinder.befschool.security.UserDetailsImpl;
import com.tinder.befschool.service.AdminScheduleService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teacher/schedules")
@PreAuthorize("hasRole('TEACHER')")
public class TeacherScheduleController {
    private final AdminScheduleService service;

    public TeacherScheduleController(AdminScheduleService service) { this.service = service; }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ScheduleResponse>>> mine(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @RequestParam(required = false) Integer dayOfWeek) {
        return ResponseEntity.ok(new ApiResponse<>(true,
                service.findTeacherSchedule(currentUser.getId(), dayOfWeek),
                "Lấy lịch dạy thành công"));
    }
}
