package com.tinder.befschool.repository;

import com.tinder.befschool.entity.RoleName;
import com.tinder.befschool.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByPhoneNumber(String phoneNumber);

    Optional<User> findByIdAndRoles_Name(Long id, RoleName roleName);

    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT u.className FROM User u WHERE u.className IS NOT NULL ORDER BY u.className ASC")
    List<String> findDistinctClassNames();

    List<User> findByRoles_NameAndIsActiveTrueOrderByNameAsc(RoleName roleName);

    List<User> findByRoles_NameAndClassNameAndIsActiveTrueOrderByNameAsc(RoleName roleName, String className);

    List<User> findByRoles_NameAndClassNameInOrderByClassNameAscNameAsc(RoleName roleName, Collection<String> classNames);

    List<User> findByIdIn(Collection<Long> ids);

    boolean existsByPhoneNumber(String phoneNumber);
}
