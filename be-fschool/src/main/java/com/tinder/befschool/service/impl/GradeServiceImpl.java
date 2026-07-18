package com.tinder.befschool.service.impl;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.repository.GradeRepository;
import com.tinder.befschool.service.GradeService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class GradeServiceImpl implements GradeService {

    private final GradeRepository gradeRepository;
    private final ObjectMapper objectMapper;

    public GradeServiceImpl(GradeRepository gradeRepository, ObjectMapper objectMapper) {
        this.gradeRepository = gradeRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    public List<Grade> findByStudentAndSemester(Long studentId, Integer semester) {
        List<Grade> grades = gradeRepository.findByStudentIdAndSemester(studentId, semester);
        // ensure tx15 and tx1tiet are valid JSON; leave parsing to controller/dto
        return grades;
    }
}
