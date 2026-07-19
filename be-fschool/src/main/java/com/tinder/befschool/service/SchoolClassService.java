package com.tinder.befschool.service;

import com.tinder.befschool.dto.classroom.*;
import java.util.List;

public interface SchoolClassService {
    List<SchoolClassResponse> findAll();
    SchoolClassResponse findById(Long classId);
    SchoolClassResponse create(CreateSchoolClassRequest request);
    SchoolClassResponse update(Long classId, UpdateSchoolClassRequest request);
    SchoolClassResponse close(Long classId);
    SchoolClassResponse assignHomeroomTeacher(Long classId, Long teacherId);
    SchoolClassResponse removeHomeroomTeacher(Long classId);
    List<ClassStudentResponse> getStudents(Long classId);
    List<UnassignedStudentResponse> getUnassignedStudents(String schoolYear);
    List<ClassStudentResponse> addStudents(Long classId, AddStudentsToClassRequest request);
    void removeStudent(Long classId, Long studentId, RemoveStudentRequest request);
    void transferStudent(Long studentId, TransferStudentRequest request);
}
