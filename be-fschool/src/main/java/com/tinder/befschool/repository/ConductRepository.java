package com.tinder.befschool.repository;

import com.tinder.befschool.entity.Conduct;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ConductRepository extends JpaRepository<Conduct, Long> {

    List<Conduct> findByStudentIdOrderByYearDescMonthDesc(Long studentId);

    List<Conduct> findByClassNameAndMonthAndYearOrderByStudentName(String className, Integer month, Integer year);

    Optional<Conduct> findByStudentIdAndMonthAndYear(Long studentId, Integer month, Integer year);
}
