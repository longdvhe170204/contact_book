package com.tinder.befschool.service;

import com.tinder.befschool.dto.TeacherAssignmentRequest;
import com.tinder.befschool.entity.Assignment;

import java.util.List;

public interface AssignmentService {
    List<Assignment> findByClass(String className);
    Assignment update(Long id, TeacherAssignmentRequest request);
    void delete(Long id);
}
