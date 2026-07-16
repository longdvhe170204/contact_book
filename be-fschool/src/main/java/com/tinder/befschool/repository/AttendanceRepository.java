package com.tinder.befschool.repository;

import com.tinder.befschool.entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {

    List<Attendance> findByStudentIdOrderByDateDesc(Long studentId);

    List<Attendance> findByClassNameAndDateOrderByStudentId(String className, LocalDate date);

    List<Attendance> findByStudentIdAndDateBetweenOrderByDateDesc(Long studentId, LocalDate from, LocalDate to);

    Optional<Attendance> findByStudentIdAndDateAndClassNameAndSubject(Long studentId, LocalDate date, String className, String subject);
}
