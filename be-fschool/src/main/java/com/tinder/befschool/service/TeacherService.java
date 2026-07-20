package com.tinder.befschool.service;

import com.tinder.befschool.dto.TeacherAssignmentRequest;
import com.tinder.befschool.dto.TeacherGradeResponse;
import com.tinder.befschool.dto.TeacherGradeUpsertRequest;
import com.tinder.befschool.entity.Assignment;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.entity.Schedule;
import com.tinder.befschool.entity.User;

import java.util.List;

public interface TeacherService {
    List<Schedule> findSchedules(Long teacherId);

    List<String> findClassNames(Long teacherId);

    List<User> findStudents(Long teacherId, String className);

    List<Assignment> findAssignments(Long teacherId);

    Assignment createAssignment(Long teacherId, TeacherAssignmentRequest request);

    List<TeacherGradeResponse> findGrades(Long teacherId, String className, Integer semester, String subject);

    Grade upsertGrade(Long teacherId, TeacherGradeUpsertRequest request);

    User saveStudent(Long teacherId, User student);

    List<Grade> bulkUpsertGrades(Long teacherId, List<TeacherGradeUpsertRequest> requests);
}
