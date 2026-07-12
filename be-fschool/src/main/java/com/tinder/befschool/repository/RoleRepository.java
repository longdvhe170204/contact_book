package com.tinder.befschool.repository;

import com.tinder.befschool.entity.Role;
import com.tinder.befschool.entity.RoleName;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByName(RoleName name);
}