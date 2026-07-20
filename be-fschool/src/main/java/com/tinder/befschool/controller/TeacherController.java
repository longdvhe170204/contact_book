package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.TeacherAssignmentRequest;
import com.tinder.befschool.dto.TeacherGradeResponse;
import com.tinder.befschool.dto.TeacherGradeUpsertRequest;
import com.tinder.befschool.dto.schedule.LegacyScheduleResponse;
import com.tinder.befschool.entity.Assignment;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.security.UserDetailsImpl;
import com.tinder.befschool.service.PrmCompatibilityService;
import com.tinder.befschool.service.TeacherService;
import com.tinder.befschool.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/teachers")
public class TeacherController {

    private final UserService userService;
    private final TeacherService teacherService;
    private final PrmCompatibilityService prmCompatibilityService;

    public TeacherController(UserService userService,
                             TeacherService teacherService,
                             PrmCompatibilityService prmCompatibilityService) {
        this.userService = userService;
        this.teacherService = teacherService;
        this.prmCompatibilityService = prmCompatibilityService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<User>>> getTeachers() {
        return ResponseEntity.ok(new ApiResponse<>(true, userService.findAllTeachers(), "OK"));
    }

    @GetMapping("/{teacherId}")
    public ResponseEntity<ApiResponse<User>> getTeacher(@PathVariable Long teacherId) {
        return ResponseEntity.ok(new ApiResponse<>(true, userService.findTeacherById(teacherId), "OK"));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    @GetMapping("/{teacherId}/classes")
    public ResponseEntity<ApiResponse<List<String>>> getClasses(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @PathVariable Long teacherId) {
        return ResponseEntity.ok(new ApiResponse<>(true,
                prmCompatibilityService.findTeacherClasses(currentUser.getId(), teacherId),
                "Lấy danh sách lớp thành công"));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    @GetMapping("/{teacherId}/students")
    public ResponseEntity<ApiResponse<List<User>>> getStudents(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @PathVariable Long teacherId,
            @RequestParam(required = false) String className) {
        return ResponseEntity.ok(new ApiResponse<>(true,
                prmCompatibilityService.findTeacherStudents(currentUser.getId(), teacherId, className),
                "Lấy danh sách học sinh thành công"));
    }

    @PostMapping("/{teacherId}/students")
    public ResponseEntity<ApiResponse<User>> addStudent(@PathVariable Long teacherId,
                                                        @Valid @RequestBody User student) {
        User saved = teacherService.saveStudent(teacherId, student);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, saved, "Student added successfully"));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    @GetMapping("/{teacherId}/schedules")
    public ResponseEntity<ApiResponse<List<LegacyScheduleResponse>>> getSchedules(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @PathVariable Long teacherId) {
        return ResponseEntity.ok(new ApiResponse<>(true,
                prmCompatibilityService.findTeacherSchedules(currentUser.getId(), teacherId),
                "Lấy lịch dạy thành công"));
    }

    @GetMapping("/{teacherId}/assignments")
    public ResponseEntity<ApiResponse<List<Assignment>>> getAssignments(@PathVariable Long teacherId) {
        return ResponseEntity.ok(new ApiResponse<>(true, teacherService.findAssignments(teacherId), "OK"));
    }

    @PostMapping("/{teacherId}/assignments")
    public ResponseEntity<ApiResponse<Assignment>> createAssignment(@PathVariable Long teacherId,
                                                                    @Valid @RequestBody TeacherAssignmentRequest request) {
        Assignment assignment = teacherService.createAssignment(teacherId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, assignment, "Assignment created successfully"));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    @GetMapping("/{teacherId}/grades")
    public ResponseEntity<ApiResponse<List<TeacherGradeResponse>>> getGrades(
            @AuthenticationPrincipal UserDetailsImpl currentUser,
            @PathVariable Long teacherId,
            @RequestParam String className,
            @RequestParam Integer semester,
            @RequestParam(required = false) String subject
    ) {
        return ResponseEntity.ok(
                new ApiResponse<>(
                        true,
                        teacherService.findGradesForViewer(
                                currentUser.getId(),
                                teacherId,
                                className,
                                semester,
                                subject
                        ),
                        "OK"
                )
        );
    }

    @PreAuthorize("hasRole('TEACHER')")
    @PutMapping("/{teacherId}/grades")
    public ResponseEntity<ApiResponse<Grade>> upsertGrade(@PathVariable Long teacherId,
                                                          @Valid @RequestBody TeacherGradeUpsertRequest request) {
        Grade grade = teacherService.upsertGrade(teacherId, request);
        return ResponseEntity.ok(new ApiResponse<>(true, grade, "Grade saved successfully"));
    }

    @PreAuthorize("hasRole('TEACHER')")
    @PostMapping("/{teacherId}/grades/bulk")
    public ResponseEntity<ApiResponse<List<Grade>>> bulkUpsertGrades(@PathVariable Long teacherId,
                                                                     @RequestBody List<TeacherGradeUpsertRequest> requests) {
        List<Grade> grades = teacherService.bulkUpsertGrades(teacherId, requests);
        return ResponseEntity.ok(new ApiResponse<>(true, grades, "Bulk grades updated successfully"));
    }
}
