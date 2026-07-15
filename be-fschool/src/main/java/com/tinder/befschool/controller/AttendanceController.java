package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.AttendanceRequest;
import com.tinder.befschool.entity.Attendance;
import com.tinder.befschool.service.AttendanceService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    public AttendanceController(AttendanceService attendanceService) {
        this.attendanceService = attendanceService;
    }

    /**
     * POST /api/attendance?teacherId={id}
     * Giáo viên lưu điểm danh cho một lớp theo ngày
     */
    @PostMapping
    public ResponseEntity<ApiResponse<List<Attendance>>> saveAttendance(
            @RequestParam Long teacherId,
            @Valid @RequestBody AttendanceRequest request) {
        List<Attendance> result = attendanceService.saveAttendance(teacherId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, result, "Attendance saved successfully"));
    }

    /**
     * GET /api/attendance/student/{studentId}
     * Học sinh xem lịch sử điểm danh của mình
     */
    @GetMapping("/student/{studentId}")
    public ResponseEntity<ApiResponse<List<Attendance>>> getStudentAttendance(@PathVariable Long studentId) {
        return ResponseEntity.ok(new ApiResponse<>(true, attendanceService.getStudentAttendance(studentId), "OK"));
    }

    /**
     * GET /api/attendance/class/{className}/date/{date}
     * Giáo viên xem điểm danh của lớp theo ngày (yyyy-MM-dd)
     */
    @GetMapping("/class/{className}/date/{date}")
    public ResponseEntity<ApiResponse<List<Attendance>>> getClassAttendance(
            @PathVariable String className,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(new ApiResponse<>(true, attendanceService.getClassAttendance(className, date), "OK"));
    }
}
