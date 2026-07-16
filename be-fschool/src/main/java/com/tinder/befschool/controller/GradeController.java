package com.tinder.befschool.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.service.GradeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/grades")
public class GradeController {

    private final GradeService gradeService;
    private final ObjectMapper objectMapper;

    public GradeController(GradeService gradeService, ObjectMapper objectMapper) {
        this.gradeService = gradeService;
        this.objectMapper = objectMapper;
    }

    @GetMapping("/student/{studentId}/semester/{semester}")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getGrades(@PathVariable Long studentId, @PathVariable Integer semester) {
        List<Grade> grades = gradeService.findByStudentAndSemester(studentId, semester);
        // convert tx15 and tx1tiet to List<Double>
        List<Map<String, Object>> out = grades.stream().map(g -> {
            Map<String, Object> m = objectMapper.convertValue(g, new TypeReference<Map<String, Object>>(){});
            try {
                if (g.getTx15() != null) {
                    List<Double> tx15 = objectMapper.readValue(g.getTx15(), new TypeReference<List<Double>>(){});
                    m.put("tx15", tx15);
                }
                if (g.getTx1tiet() != null) {
                    List<Double> tx1 = objectMapper.readValue(g.getTx1tiet(), new TypeReference<List<Double>>(){});
                    m.put("tx1tiet", tx1);
                }
            } catch (Exception ex) {
                // ignore parse error, leave as raw string
                m.put("tx15", g.getTx15());
                m.put("tx1tiet", g.getTx1tiet());
            }
            return m;
        }).toList();

        return ResponseEntity.ok(new ApiResponse<>(true, out, "OK"));
    }
}
