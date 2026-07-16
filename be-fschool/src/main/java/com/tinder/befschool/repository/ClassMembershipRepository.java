package com.tinder.befschool.repository;

import com.tinder.befschool.entity.ClassMembership;
import com.tinder.befschool.entity.ClassMembershipStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.Collection;

public interface ClassMembershipRepository extends JpaRepository<ClassMembership, Long> {
    Optional<ClassMembership> findByStudentIdAndSchoolYearAndStatus(
            Long studentId, String schoolYear, ClassMembershipStatus status);
    List<ClassMembership> findByClassIdAndStatusOrderByStudentIdAsc(
            Long classId, ClassMembershipStatus status);
    long countByClassIdAndStatus(Long classId, ClassMembershipStatus status);
    List<ClassMembership> findBySchoolYearAndStatus(String schoolYear, ClassMembershipStatus status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Optional<ClassMembership> findFirstByStudentIdAndSchoolYearAndStatus(
            Long studentId, String schoolYear, ClassMembershipStatus status);
}
