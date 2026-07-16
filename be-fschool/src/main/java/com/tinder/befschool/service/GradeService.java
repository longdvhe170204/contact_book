package com.tinder.befschool.service;

import com.tinder.befschool.entity.Grade;

import java.util.List;

public interface GradeService {
    List<Grade> findByStudentAndSemester(Long studentId, Integer semester);
}
