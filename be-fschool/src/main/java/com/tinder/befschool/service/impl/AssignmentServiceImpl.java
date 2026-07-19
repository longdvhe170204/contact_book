package com.tinder.befschool.service.impl;

import com.tinder.befschool.dto.TeacherAssignmentRequest;
import com.tinder.befschool.entity.Assignment;
import com.tinder.befschool.repository.AssignmentRepository;
import com.tinder.befschool.service.AssignmentService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class AssignmentServiceImpl implements AssignmentService {

    private final AssignmentRepository assignmentRepository;

    public AssignmentServiceImpl(AssignmentRepository assignmentRepository) {
        this.assignmentRepository = assignmentRepository;
    }

    @Override
    public List<Assignment> findByClass(String className) {
        return assignmentRepository.findByClassNameOrderByDueDateDesc(className);
    }

    @Override
    public Assignment update(Long id, TeacherAssignmentRequest request) {
        Assignment assignment = assignmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy bài tập với ID: " + id));
        assignment.setClassName(request.getClassName());
        assignment.setSubject(request.getSubject());
        assignment.setTitle(request.getTitle());
        assignment.setDescription(request.getDescription() == null || request.getDescription().isBlank()
                ? request.getTitle()
                : request.getDescription());
        assignment.setDueDate(request.getDueDate());
        assignment.setFileUrl(request.getFileUrl());
        return assignmentRepository.save(assignment);
    }

    @Override
    public void delete(Long id) {
        if (!assignmentRepository.existsById(id)) {
            throw new RuntimeException("Không tìm thấy bài tập với ID: " + id);
        }
        assignmentRepository.deleteById(id);
    }
}
