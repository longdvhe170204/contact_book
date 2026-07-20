package com.tinder.befschool.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tinder.befschool.dto.TeacherAssignmentRequest;
import com.tinder.befschool.dto.TeacherGradeResponse;
import com.tinder.befschool.dto.TeacherGradeUpsertRequest;
import com.tinder.befschool.entity.Assignment;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.entity.Role;
import com.tinder.befschool.entity.RoleName;
import com.tinder.befschool.entity.Schedule;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.exception.ApiException;
import com.tinder.befschool.repository.AssignmentRepository;
import com.tinder.befschool.repository.GradeRepository;
import com.tinder.befschool.repository.RoleRepository;
import com.tinder.befschool.repository.ScheduleRepository;
import com.tinder.befschool.repository.UserRepository;
import com.tinder.befschool.service.EmailService;
import com.tinder.befschool.service.TeacherService;
import com.tinder.befschool.service.UserService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional
public class TeacherServiceImpl implements TeacherService {

    private final UserService userService;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final ScheduleRepository scheduleRepository;
    private final AssignmentRepository assignmentRepository;
    private final GradeRepository gradeRepository;
    private final ObjectMapper objectMapper;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    public TeacherServiceImpl(UserService userService,
                              UserRepository userRepository,
                              RoleRepository roleRepository,
                              ScheduleRepository scheduleRepository,
                              AssignmentRepository assignmentRepository,
                              GradeRepository gradeRepository,
                              ObjectMapper objectMapper,
                              PasswordEncoder passwordEncoder,
                              EmailService emailService) {
        this.userService = userService;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.scheduleRepository = scheduleRepository;
        this.assignmentRepository = assignmentRepository;
        this.gradeRepository = gradeRepository;
        this.objectMapper = objectMapper;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Schedule> findSchedules(Long teacherId) {
        userService.findTeacherById(teacherId);
        return scheduleRepository.findByTeacherIdOrderByDayOfWeekAscPeriodAsc(teacherId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<String> findClassNames(Long teacherId) {
        userService.findTeacherById(teacherId);
        return scheduleRepository.findDistinctClassNamesByTeacherId(teacherId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<User> findStudents(Long teacherId, String className) {
        userService.findTeacherById(teacherId);
        List<String> assignedClasses = scheduleRepository.findDistinctClassNamesByTeacherId(teacherId);
        if (assignedClasses.isEmpty()) {
            return Collections.emptyList();
        }

        if (className != null && !className.isBlank()) {
            assertTeacherAssignedToClass(teacherId, className);
            return userRepository.findByRoles_NameAndClassNameAndIsActiveTrueOrderByNameAsc(RoleName.STUDENT, className);
        }

        return userRepository.findByRoles_NameAndClassNameInOrderByClassNameAscNameAsc(RoleName.STUDENT, assignedClasses);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Assignment> findAssignments(Long teacherId) {
        userService.findTeacherById(teacherId);
        return assignmentRepository.findByTeacherIdOrderByDueDateDesc(teacherId);
    }

    @Override
    public Assignment createAssignment(Long teacherId, TeacherAssignmentRequest request) {
        User teacher = userService.findTeacherById(teacherId);
        assertTeacherAssignedToClassAndSubject(teacherId, request.getClassName(), request.getSubject());

        Assignment assignment = new Assignment();
        assignment.setClassName(request.getClassName());
        assignment.setSubject(request.getSubject());
        assignment.setTitle(request.getTitle());
        assignment.setDescription(request.getDescription() == null || request.getDescription().isBlank()
                ? request.getTitle()
                : request.getDescription());
        assignment.setTeacher(teacher.getName());
        assignment.setTeacherId(teacher.getId());
        assignment.setDueDate(request.getDueDate());
        assignment.setCreatedAtCustom(LocalDateTime.now());
        assignment.setFileUrl(request.getFileUrl());

        Assignment saved = assignmentRepository.save(assignment);
        
        // Notify students via email
        try {
            List<User> students = userRepository.findByRoles_NameAndClassNameAndIsActiveTrueOrderByNameAsc(RoleName.STUDENT, request.getClassName());
            String dueDateStr = request.getDueDate() != null ? request.getDueDate().toString() : "N/A";
            
            for (User student : students) {
                if (student.getEmail() != null && !student.getEmail().isBlank()) {
                    emailService.sendAssignmentNotification(
                        student.getEmail(),
                        student.getName(),
                        teacher.getName(),
                        request.getSubject(),
                        request.getTitle(),
                        dueDateStr
                    );
                }
            }
        } catch (Exception e) {
            // Log and continue
        }
        
        return saved;
    }

    @Override
    @Transactional(readOnly = true)
    public List<TeacherGradeResponse> findGrades(Long teacherId, String className, Integer semester, String subject) {
        userService.findTeacherById(teacherId);
        assertTeacherAssignedToClass(teacherId, className);

        List<Grade> grades = subject == null || subject.isBlank()
                ? gradeRepository.findByTeacherIdAndClassNameAndSemesterOrderBySubjectAscStudentIdAsc(teacherId, className, semester)
                : gradeRepository.findByTeacherIdAndClassNameAndSemesterAndSubjectOrderByStudentIdAsc(teacherId, className, semester, subject);

        List<User> students = userRepository.findByRoles_NameAndClassNameAndIsActiveTrueOrderByNameAsc(RoleName.STUDENT, className);
        Map<Long, User> studentsById = students.stream().collect(Collectors.toMap(User::getId, Function.identity()));

        return grades.stream().map(grade -> toTeacherGradeResponse(grade, studentsById.get(grade.getStudentId()))).toList();
    }

    @Override
    public Grade upsertGrade(Long teacherId, TeacherGradeUpsertRequest request) {
        User teacher = userService.findTeacherById(teacherId);
        User student = userService.findStudentById(request.getStudentId());

        if (student.getClassName() == null || student.getClassName().isBlank()) {
            throw new ApiException("Student does not belong to any class");
        }

        assertTeacherAssignedToClassAndSubject(teacherId, student.getClassName(), request.getSubject());

        Grade grade = gradeRepository.findByStudentIdAndSemesterAndSubject(
                        request.getStudentId(),
                        request.getSemester(),
                        request.getSubject())
                .orElseGet(Grade::new);

        grade.setStudentId(student.getId());
        grade.setClassName(student.getClassName());
        grade.setTeacherId(teacher.getId());
        grade.setSubject(request.getSubject());
        grade.setSemester(request.getSemester());
        grade.setTx15(writeScores(request.getTx15()));
        grade.setTx1tiet(writeScores(request.getTx1tiet()));
        grade.setGiuaKy(request.getGiuaKy());
        grade.setCuoiKy(request.getCuoiKy());
        grade.setAverage(request.getAverage() != null ? request.getAverage() : calculateAverage(request));
        return gradeRepository.save(grade);
    }

    @Override
    public User saveStudent(Long teacherId, User student) {
        userService.findTeacherById(teacherId);
        assertTeacherAssignedToClass(teacherId, student.getClassName());

        if (userRepository.existsByPhoneNumber(student.getPhoneNumber())) {
            throw new ApiException("Số điện thoại đã tồn tại trên hệ thống");
        }

        Role studentRole = roleRepository.findByName(RoleName.STUDENT)
                .orElseThrow(() -> new ApiException("Không tìm thấy role STUDENT"));

        Set<Role> roles = new HashSet<>();
        roles.add(studentRole);
        student.setRoles(roles);
        student.setRoleId(1L); // STUDENT ID
        
        // Default password if not provided, else encrypt provided
        String rawPassword = (student.getPassword() == null || student.getPassword().isBlank()) ? "123456" : student.getPassword();
        student.setPassword(passwordEncoder.encode(rawPassword));
        
        return userRepository.save(student);
    }

    @Override
    public List<Grade> bulkUpsertGrades(Long teacherId, List<TeacherGradeUpsertRequest> requests) {
        List<Grade> result = new ArrayList<>();
        for (TeacherGradeUpsertRequest request : requests) {
            result.add(upsertGrade(teacherId, request));
        }
        return result;
    }

    private void assertTeacherAssignedToClass(Long teacherId, String className) {
        List<String> assignedClasses = scheduleRepository.findDistinctClassNamesByTeacherId(teacherId);
        if (!assignedClasses.contains(className)) {
            throw new ApiException("Teacher is not assigned to class: " + className);
        }
    }

    private void assertTeacherAssignedToClassAndSubject(Long teacherId, String className, String subject) {
        if (!scheduleRepository.existsByTeacherIdAndClassNameAndSubject(teacherId, className, subject)) {
            throw new ApiException("Teacher is not assigned to subject " + subject + " for class " + className);
        }
    }

    private TeacherGradeResponse toTeacherGradeResponse(Grade grade, User student) {
        TeacherGradeResponse response = new TeacherGradeResponse();
        response.setGradeId(grade.getId());
        response.setStudentId(grade.getStudentId());
        response.setStudentName(student != null ? student.getName() : null);
        response.setClassName(grade.getClassName());
        response.setSubject(grade.getSubject());
        response.setSemester(grade.getSemester());
        response.setTx15(readScores(grade.getTx15()));
        response.setTx1tiet(readScores(grade.getTx1tiet()));
        response.setGiuaKy(grade.getGiuaKy());
        response.setCuoiKy(grade.getCuoiKy());
        response.setAverage(grade.getAverage());
        return response;
    }

    private List<Double> readScores(String raw) {
        if (raw == null || raw.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(raw, new TypeReference<List<Double>>() { });
        } catch (JsonProcessingException ex) {
            throw new ApiException("Cannot parse stored score data");
        }
    }

    private String writeScores(List<Double> scores) {
        if (scores == null || scores.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(scores);
        } catch (JsonProcessingException ex) {
            throw new ApiException("Cannot serialize score data");
        }
    }

    private Double calculateAverage(TeacherGradeUpsertRequest request) {
        double total = 0;
        int weight = 0;

        if (request.getTx15() != null && !request.getTx15().isEmpty()) {
            total += request.getTx15().stream().mapToDouble(Double::doubleValue).average().orElse(0);
            weight += 1;
        }
        if (request.getTx1tiet() != null && !request.getTx1tiet().isEmpty()) {
            total += request.getTx1tiet().stream().mapToDouble(Double::doubleValue).average().orElse(0) * 2;
            weight += 2;
        }
        if (request.getGiuaKy() != null) {
            total += request.getGiuaKy() * 2;
            weight += 2;
        }
        if (request.getCuoiKy() != null) {
            total += request.getCuoiKy() * 3;
            weight += 3;
        }

        if (weight == 0) {
            return null;
        }

        return Math.round((total / weight) * 100.0) / 100.0;
    }
}
