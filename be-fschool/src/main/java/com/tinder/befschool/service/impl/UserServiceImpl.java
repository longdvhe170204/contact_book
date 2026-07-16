package com.tinder.befschool.service.impl;

import com.tinder.befschool.entity.RoleName;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.exception.NotFoundException;
import com.tinder.befschool.repository.UserRepository;
import com.tinder.befschool.service.UserService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.Random;

@Service
@Transactional
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final com.tinder.befschool.repository.ScheduleRepository scheduleRepository;
    private final PasswordEncoder passwordEncoder;

    public UserServiceImpl(UserRepository userRepository,
                           com.tinder.befschool.repository.ScheduleRepository scheduleRepository,
                           PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.scheduleRepository = scheduleRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public Optional<User> findByPhoneNumber(String phoneNumber) {
        return userRepository.findByPhoneNumber(phoneNumber);
    }

    @Override
    public User findById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("User not found with id: " + id));
    }

    @Override
    public User findStudentById(Long id) {
        return userRepository.findByIdAndRoles_Name(id, RoleName.STUDENT)
                .orElseThrow(() -> new NotFoundException("Student not found with id: " + id));
    }

    @Override
    public User findTeacherById(Long id) {
        return userRepository.findByIdAndRoles_Name(id, RoleName.TEACHER)
                .orElseThrow(() -> new NotFoundException("Teacher not found with id: " + id));
    }

    @Override
    public List<User> findAllStudents() {
        return userRepository.findByRoles_NameOrderByNameAsc(RoleName.STUDENT);
    }

    @Override
    public List<User> findAllTeachers() {
        return userRepository.findByRoles_NameOrderByNameAsc(RoleName.TEACHER);
    }

    @Override
    public List<User> findStudentsByClassName(String className) {
        return userRepository.findByRoles_NameAndClassNameOrderByNameAsc(RoleName.STUDENT, className);
    }

    @Override
    public List<User> findTeachersByClassName(String className) {
        List<Long> teacherIds = scheduleRepository.findDistinctTeacherIdsByClassName(className);
        if (teacherIds.isEmpty()) return List.of();
        return userRepository.findByIdIn(teacherIds);
    }

    @Override
    public String resetPassword(String phoneNumber) {
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new NotFoundException("User not found with phone: " + phoneNumber));

        String newPassword = String.format("%06d", new Random().nextInt(999999));
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        return newPassword;
    }
}