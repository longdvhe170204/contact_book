package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.schedule.*;
import com.tinder.befschool.service.AdminScheduleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/schedules")
@PreAuthorize("hasRole('TEACHER')") // Sau này đổi thành ADMIN.
public class AdminScheduleController {
    private final AdminScheduleService service;

    public AdminScheduleController(AdminScheduleService service) { this.service = service; }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ScheduleResponse>>> findAll(
            @RequestParam(required = false) String schoolYear,
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) Long classId) {
        return ok(service.findAll(schoolYear, semester, classId), "Lấy thời khóa biểu thành công");
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ScheduleResponse>> findById(@PathVariable Long id) {
        return ok(service.findById(id), "Lấy tiết học thành công");
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ScheduleResponse>> create(@Valid @RequestBody CreateScheduleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, service.create(request), "Xếp tiết học thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ScheduleResponse>> update(
            @PathVariable Long id, @Valid @RequestBody UpdateScheduleRequest request) {
        return ok(service.update(id, request), "Cập nhật tiết học thành công");
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        service.delete(id);
        return ok(null, "Xóa tiết học thành công");
    }

    @GetMapping("/options/subjects")
    public ResponseEntity<ApiResponse<List<SubjectOptionResponse>>> subjects() {
        return ok(service.findSubjects(), "Lấy danh sách môn học thành công");
    }

    private <T> ResponseEntity<ApiResponse<T>> ok(T data, String message) {
        return ResponseEntity.ok(new ApiResponse<>(true, data, message));
    }
}
