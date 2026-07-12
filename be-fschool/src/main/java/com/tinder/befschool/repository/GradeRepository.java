package com.tinder.befschool.repository;

import com.tinder.befschool.entity.Grade;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GradeRepository extends JpaRepository<Grade, Long> {
    List<Grade> findByStudentIdAndSemester(Long studentId, Integer semester);

    Optional<Grade> findByStudentIdAndSemesterAndSubject(Long studentId, Integer semester, String subject);

    List<Grade> findByTeacherIdAndClassNameAndSemesterOrderBySubjectAscStudentIdAsc(Long teacherId, String className, Integer semester);

    List<Grade> findByTeacherIdAndClassNameAndSemesterAndSubjectOrderByStudentIdAsc(Long teacherId, String className, Integer semester, String subject);
}
