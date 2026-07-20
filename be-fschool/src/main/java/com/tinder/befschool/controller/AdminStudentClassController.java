package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.classroom.TransferStudentRequest;
import com.tinder.befschool.service.SchoolClassService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/students")
@PreAuthorize("hasRole('ADMIN')") // Sau này đổi thành ADMIN.
public class AdminStudentClassController {
    private final SchoolClassService service;

    public AdminStudentClassController(SchoolClassService service) {
        this.service = service;
    }

    @PutMapping("/{studentId}/class")
    public ResponseEntity<ApiResponse<Void>> transfer(
            @PathVariable Long studentId,
            @Valid @RequestBody TransferStudentRequest request) {
        service.transferStudent(studentId, request);
        return ResponseEntity.ok(new ApiResponse<>(true, null, "Chuyển lớp thành công"));
    }
}
