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

    List<User> findByRoles_NameOrderByNameAsc(RoleName roleName);

    List<User> findByRoles_NameAndClassNameOrderByNameAsc(RoleName roleName, String className);

    List<User> findByRoles_NameAndClassNameInOrderByClassNameAscNameAsc(RoleName roleName, Collection<String> classNames);

    List<User> findByIdIn(Collection<Long> ids);

    boolean existsByPhoneNumber(String phoneNumber);
}