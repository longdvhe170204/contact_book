package com.tinder.befschool.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.dto.TeacherGradeResponse;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.entity.RoleName;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.repository.GradeRepository;
import com.tinder.befschool.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/grades")
@PreAuthorize("hasRole('ADMIN')")
public class AdminGradeController {

    private final GradeRepository gradeRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;

    public AdminGradeController(GradeRepository gradeRepository, UserRepository userRepository, ObjectMapper objectMapper) {
        this.gradeRepository = gradeRepository;
        this.userRepository = userRepository;
        this.objectMapper = objectMapper;
    }

    @GetMapping("/classes")
    public ResponseEntity<ApiResponse<List<String>>> getAllClasses() {
        return ResponseEntity.ok(new ApiResponse<>(true, userRepository.findDistinctClassNames(), "Lấy danh sách lớp thành công"));
    }

    @GetMapping("/debug/users")
    public ResponseEntity<?> debugUsers() {
        return ResponseEntity.ok(userRepository.findAll().stream().map(u -> u.getName() + " - " + u.getClassName() + " - " + u.getRoles().stream().map(r -> r.getName().name()).collect(Collectors.joining(","))).toList());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<TeacherGradeResponse>>> getGrades(
            @RequestParam String className,
            @RequestParam Integer semester,
            @RequestParam(required = false) String subject) {

        List<Grade> grades = subject == null || subject.isBlank()
                ? gradeRepository.findByClassNameAndSemesterOrderBySubjectAscStudentIdAsc(className, semester)
                : gradeRepository.findByClassNameAndSemesterAndSubjectOrderByStudentIdAsc(className, semester, subject);

        List<User> students = userRepository.findByRoles_NameAndClassNameAndIsActiveTrueOrderByNameAsc(RoleName.STUDENT, className);
        
        Map<Long, List<Grade>> gradesByStudent = grades.stream().collect(Collectors.groupingBy(Grade::getStudentId));
        
        List<TeacherGradeResponse> response = new java.util.ArrayList<>();
        
        for (User student : students) {
            List<Grade> studentGrades = gradesByStudent.getOrDefault(student.getId(), Collections.emptyList());
            
            if (studentGrades.isEmpty()) {
                TeacherGradeResponse res = new TeacherGradeResponse();
                res.setStudentId(student.getId());
                res.setStudentName(student.getName());
                res.setClassName(student.getClassName());
                res.setSemester(semester);
                res.setSubject(subject == null || subject.isBlank() ? "" : subject);
                res.setTx15(Collections.emptyList());
                res.setTx1tiet(Collections.emptyList());
                response.add(res);
            } else {
                for (Grade grade : studentGrades) {
                    TeacherGradeResponse res = new TeacherGradeResponse();
                    res.setGradeId(grade.getId());
                    res.setStudentId(student.getId());
                    res.setStudentName(student.getName());
                    res.setClassName(student.getClassName());
                    res.setSubject(grade.getSubject());
                    res.setSemester(grade.getSemester());
                    res.setTx15(readScores(grade.getTx15()));
                    res.setTx1tiet(readScores(grade.getTx1tiet()));
                    res.setGiuaKy(grade.getGiuaKy());
                    res.setCuoiKy(grade.getCuoiKy());
                    res.setAverage(grade.getAverage());
                    response.add(res);
                }
            }
        }

        return ResponseEntity.ok(new ApiResponse<>(true, response, "Lấy danh sách điểm thành công"));
    }

    private List<Double> readScores(String raw) {
        if (raw == null || raw.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(raw, new TypeReference<List<Double>>() { });
        } catch (JsonProcessingException ex) {
            return Collections.emptyList();
        }
    }
}
