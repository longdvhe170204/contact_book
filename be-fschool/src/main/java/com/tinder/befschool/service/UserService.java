package com.tinder.befschool.service;

import com.tinder.befschool.entity.User;

import java.util.List;
import java.util.Optional;

public interface UserService {
    Optional<User> findByPhoneNumber(String phoneNumber);

    User findById(Long id);

    User findStudentById(Long id);

    User findTeacherById(Long id);

    List<User> findAllStudents();

    List<User> findAllTeachers();

    List<User> findStudentsByClassName(String className);

    List<User> findTeachersByClassName(String className);

    String resetPassword(String phoneNumber);
}