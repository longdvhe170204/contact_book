package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.ImportSummaryResponse;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.service.DataImportService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class DataImportController {

    private final DataImportService dataImportService;

    public DataImportController(DataImportService dataImportService) {
        this.dataImportService = dataImportService;
    }

    @PostMapping("/students/import")
    public ResponseEntity<ApiResponse<ImportSummaryResponse>> importStudents(@RequestBody List<User> students) {
        ImportSummaryResponse summary = dataImportService.importStudents(students);
        return ResponseEntity.ok(new ApiResponse<>(true, summary, "Hoàn tất import danh sách học sinh"));
    }
}
