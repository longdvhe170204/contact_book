package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.TeacherAssignmentRequest;
import com.tinder.befschool.entity.Assignment;
import com.tinder.befschool.service.AssignmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/assignments")
public class AssignmentController {

    private final AssignmentService assignmentService;

    public AssignmentController(AssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @GetMapping("/class/{className}")
    public ResponseEntity<ApiResponse<List<Assignment>>> getByClass(@PathVariable String className) {
        List<Assignment> list = assignmentService.findByClass(className);
        return ResponseEntity.ok(new ApiResponse<>(true, list, "OK"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Assignment>> updateAssignment(@PathVariable Long id, @RequestBody TeacherAssignmentRequest request) {
        Assignment updated = assignmentService.update(id, request);
        return ResponseEntity.ok(new ApiResponse<>(true, updated, "Assignment updated successfully"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteAssignment(@PathVariable Long id) {
        assignmentService.delete(id);
        return ResponseEntity.ok(new ApiResponse<>(true, null, "Assignment deleted successfully"));
    }
}
