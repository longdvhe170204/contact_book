package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.classroom.*;
import com.tinder.befschool.service.SchoolClassService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/classes")
@PreAuthorize("hasRole('TEACHER')") // Sau này đổi thành ADMIN.
@Validated
public class AdminClassController {
    private final SchoolClassService service;

    public AdminClassController(SchoolClassService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<SchoolClassResponse>>> findAll() {
        return ok(service.findAll(), "Lấy danh sách lớp thành công");
    }

    @GetMapping("/{classId}")
    public ResponseEntity<ApiResponse<SchoolClassResponse>> findById(@PathVariable Long classId) {
        return ok(service.findById(classId), "Lấy thông tin lớp thành công");
    }

    @PostMapping
    public ResponseEntity<ApiResponse<SchoolClassResponse>> create(
            @Valid @RequestBody CreateSchoolClassRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, service.create(request), "Tạo lớp thành công"));
    }

    @PutMapping("/{classId}")
    public ResponseEntity<ApiResponse<SchoolClassResponse>> update(
            @PathVariable Long classId,
            @Valid @RequestBody UpdateSchoolClassRequest request) {
        return ok(service.update(classId, request), "Cập nhật lớp thành công");
    }

    @PostMapping("/{classId}/close")
    public ResponseEntity<ApiResponse<SchoolClassResponse>> close(@PathVariable Long classId) {
        return ok(service.close(classId), "Đóng lớp thành công");
    }

    @PutMapping("/{classId}/homeroom-teacher")
    public ResponseEntity<ApiResponse<SchoolClassResponse>> assignTeacher(
            @PathVariable Long classId,
            @Valid @RequestBody AssignHomeroomTeacherRequest request) {
        return ok(service.assignHomeroomTeacher(classId, request.teacherId()),
                "Gán giáo viên chủ nhiệm thành công");
    }

    @DeleteMapping("/{classId}/homeroom-teacher")
    public ResponseEntity<ApiResponse<SchoolClassResponse>> removeTeacher(@PathVariable Long classId) {
        return ok(service.removeHomeroomTeacher(classId), "Gỡ giáo viên chủ nhiệm thành công");
    }

    @GetMapping("/{classId}/students")
    public ResponseEntity<ApiResponse<List<ClassStudentResponse>>> getStudents(@PathVariable Long classId) {
        return ok(service.getStudents(classId), "Lấy danh sách học sinh thành công");
    }

    @GetMapping("/unassigned-students")
    public ResponseEntity<ApiResponse<List<UnassignedStudentResponse>>> getUnassignedStudents(
            @RequestParam
            @Pattern(regexp = "^\\d{4}-\\d{4}$", message = "Năm học phải có dạng YYYY-YYYY")
            String schoolYear) {
        return ok(service.getUnassignedStudents(schoolYear), "Lấy học sinh chưa có lớp thành công");
    }

    @PostMapping("/{classId}/students")
    public ResponseEntity<ApiResponse<List<ClassStudentResponse>>> addStudents(
            @PathVariable Long classId,
            @Valid @RequestBody AddStudentsToClassRequest request) {
        return ok(service.addStudents(classId, request), "Thêm học sinh vào lớp thành công");
    }

    @PostMapping("/{classId}/students/{studentId}/remove")
    public ResponseEntity<ApiResponse<Void>> removeStudent(
            @PathVariable Long classId,
            @PathVariable Long studentId,
            @Valid @RequestBody RemoveStudentRequest request) {
        service.removeStudent(classId, studentId, request);
        return ok(null, "Gỡ học sinh khỏi lớp thành công");
    }

    private <T> ResponseEntity<ApiResponse<T>> ok(T data, String message) {
        return ResponseEntity.ok(new ApiResponse<>(true, data, message));
    }
}
