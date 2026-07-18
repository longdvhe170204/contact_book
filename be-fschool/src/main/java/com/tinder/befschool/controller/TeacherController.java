package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.TeacherAssignmentRequest;
import com.tinder.befschool.dto.TeacherGradeResponse;
import com.tinder.befschool.dto.TeacherGradeUpsertRequest;
import com.tinder.befschool.entity.Assignment;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.entity.Schedule;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.service.TeacherService;
import com.tinder.befschool.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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

    public TeacherController(UserService userService, TeacherService teacherService) {
        this.userService = userService;
        this.teacherService = teacherService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<User>>> getTeachers() {
        return ResponseEntity.ok(new ApiResponse<>(true, userService.findAllTeachers(), "OK"));
    }

    @GetMapping("/{teacherId}")
    public ResponseEntity<ApiResponse<User>> getTeacher(@PathVariable Long teacherId) {
        return ResponseEntity.ok(new ApiResponse<>(true, userService.findTeacherById(teacherId), "OK"));
    }

    @GetMapping("/{teacherId}/classes")
    public ResponseEntity<ApiResponse<List<String>>> getClasses(@PathVariable Long teacherId) {
        return ResponseEntity.ok(new ApiResponse<>(true, teacherService.findClassNames(teacherId), "OK"));
    }

    @GetMapping("/{teacherId}/students")
    public ResponseEntity<ApiResponse<List<User>>> getStudents(@PathVariable Long teacherId,
                                                               @RequestParam(required = false) String className) {
        return ResponseEntity.ok(new ApiResponse<>(true, teacherService.findStudents(teacherId, className), "OK"));
    }

    @PostMapping("/{teacherId}/students")
    public ResponseEntity<ApiResponse<User>> addStudent(@PathVariable Long teacherId,
                                                        @Valid @RequestBody User student) {
        User saved = teacherService.saveStudent(teacherId, student);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, saved, "Student added successfully"));
    }

    @GetMapping("/{teacherId}/schedules")
    public ResponseEntity<ApiResponse<List<Schedule>>> getSchedules(@PathVariable Long teacherId) {
        return ResponseEntity.ok(new ApiResponse<>(true, teacherService.findSchedules(teacherId), "OK"));
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

    @GetMapping("/{teacherId}/grades")
    public ResponseEntity<ApiResponse<List<TeacherGradeResponse>>> getGrades(@PathVariable Long teacherId,
                                                                             @RequestParam String className,
                                                                             @RequestParam Integer semester,
                                                                             @RequestParam(required = false) String subject) {
        return ResponseEntity.ok(new ApiResponse<>(true, teacherService.findGrades(teacherId, className, semester, subject), "OK"));
    }

    @PutMapping("/{teacherId}/grades")
    public ResponseEntity<ApiResponse<Grade>> upsertGrade(@PathVariable Long teacherId,
                                                          @Valid @RequestBody TeacherGradeUpsertRequest request) {
        Grade grade = teacherService.upsertGrade(teacherId, request);
        return ResponseEntity.ok(new ApiResponse<>(true, grade, "Grade saved successfully"));
    }

    @PostMapping("/{teacherId}/grades/bulk")
    public ResponseEntity<ApiResponse<List<Grade>>> bulkUpsertGrades(@PathVariable Long teacherId,
                                                                     @RequestBody List<TeacherGradeUpsertRequest> requests) {
        List<Grade> grades = teacherService.bulkUpsertGrades(teacherId, requests);
        return ResponseEntity.ok(new ApiResponse<>(true, grades, "Bulk grades updated successfully"));
    }
}