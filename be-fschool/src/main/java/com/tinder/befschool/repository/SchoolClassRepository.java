package com.tinder.befschool.repository;

import com.tinder.befschool.entity.SchoolClass;
import com.tinder.befschool.entity.SchoolClassStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface SchoolClassRepository extends JpaRepository<SchoolClass, Long> {
    boolean existsByCodeIgnoreCaseAndSchoolYear(String code, String schoolYear);
    Optional<SchoolClass> findByCodeIgnoreCaseAndSchoolYear(String code, String schoolYear);
    Optional<SchoolClass> findByHomeroomTeacherIdAndSchoolYearAndStatus(
            Long teacherId, String schoolYear, SchoolClassStatus status);
    List<SchoolClass> findAllByOrderBySchoolYearDescGradeLevelAscCodeAsc();
    long countByStatus(SchoolClassStatus status);
}
