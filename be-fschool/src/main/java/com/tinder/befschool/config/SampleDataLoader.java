package com.tinder.befschool.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tinder.befschool.entity.*;
import com.tinder.befschool.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Configuration
public class SampleDataLoader {

    @Bean
    CommandLineRunner runner(UserRepository userRepository,
                             RoleRepository roleRepository,
                             GradeRepository gradeRepository,
                             ScheduleRepository scheduleRepository,
                             NotificationRepository notificationRepository,
                             AssignmentRepository assignmentRepository,
                             SubjectRepository subjectRepository,
                             SchoolClassRepository schoolClassRepository,
                             ClassMembershipRepository classMembershipRepository,
                             ObjectMapper objectMapper,
                             PasswordEncoder passwordEncoder) {
        return args -> {
            Role studentRole = ensureRole(roleRepository, RoleName.STUDENT, "Student account");
            Role teacherRole = ensureRole(roleRepository, RoleName.TEACHER, "Teacher account");
            Role adminRole = ensureRole(roleRepository, RoleName.ADMIN, "Admin account");

            if (subjectRepository.count() == 0) {
                List<String> subjectNames = List.of("Toán", "Văn", "Anh Văn", "Vật Lý", "Hóa Học",
                        "Sinh Học", "Lịch Sử", "Địa Lý", "Thể Dục", "Tin Học", "GDCD");
                subjectRepository.saveAll(subjectNames.stream().map(name -> {
                    Subject subject = new Subject();
                    subject.setName(name);
                    subject.setDescription("Môn " + name);
                    return subject;
                }).toList());
            }

            if (userRepository.count() == 0) {
                List<User> initialUsers = List.of(
                        createStudent("Nguyễn Văn A", "0123456789", "10A1", "a@example.com", LocalDate.of(2008, 1, 1), studentRole),
                        createStudent("Trần Thị B", "0987654321", "10A1", "b@example.com", LocalDate.of(2008, 2, 2), studentRole),
                        createStudent("Lê Văn C", "0111222333", "10A1", "c@example.com", LocalDate.of(2008, 3, 3), studentRole),
                        createTeacher("GV. Nguyễn Văn A", "0200000001", "Toán", "T001", teacherRole),
                        createTeacher("GV. Trần Thị B", "0200000002", "Văn", "T002", teacherRole),
                        createTeacher("GV. Lê Văn C", "0200000003", "Anh Văn", "T003", teacherRole),
                        createTeacher("GV. Nguyễn Văn D", "0200000004", "Vật Lý", "T004", teacherRole),
                        createTeacher("GV. Trần Thị E", "0200000005", "Hóa Học", "T005", teacherRole),
                        createTeacher("GV. X", "0200000006", "Sinh Học", "T006", teacherRole),
                        createTeacher("GV. Y", "0200000007", "Lịch Sử", "T007", teacherRole),
                        createTeacher("GV. Z", "0200000008", "Địa Lý", "T008", teacherRole),
                        createTeacher("GV. Sport", "0200000009", "Thể Dục", "T009", teacherRole),
                        createTeacher("GV. Tech", "0200000010", "Tin Học", "T010", teacherRole),
                        createTeacher("GV. Moral", "0200000011", "GDCD", "T011", teacherRole),
                        createAdmin("Admin Hệ Thống", "0999999999", "admin@fschool.edu.vn", adminRole)
                );
                initialUsers.forEach(user -> user.setPassword(passwordEncoder.encode(user.getPassword())));
                userRepository.saveAll(initialUsers);

                if (schoolClassRepository.count() == 0) {
                    SchoolClass class10A1 = new SchoolClass();
                    class10A1.setCode("10A1");
                    class10A1.setName("10A1");
                    class10A1.setGradeLevel(10);
                    class10A1.setSchoolYear("2025-2026");
                    class10A1.setMaximumStudents(40);
                    class10A1.setStatus(SchoolClassStatus.ACTIVE);
                    schoolClassRepository.save(class10A1);

                    List<String> phones = List.of("0123456789", "0987654321", "0111222333");
                    for (String p : phones) {
                        userRepository.findByPhoneNumber(p).ifPresent(student -> {
                            ClassMembership cm = new ClassMembership();
                            cm.setStudentId(student.getId());
                            cm.setClassId(class10A1.getId());
                            cm.setSchoolYear("2025-2026");
                            cm.setJoinedDate(LocalDate.now());
                            cm.setStatus(ClassMembershipStatus.ACTIVE);
                            classMembershipRepository.save(cm);
                        });
                    }
                }
            } else {
                // Migration: Ensure existing users have roles and encrypted password
                userRepository.findAll().forEach(user -> {
                    boolean updated = false;
                    if (user.getRoles() == null || user.getRoles().isEmpty()) {
                        if (user.getPhoneNumber() != null && user.getPhoneNumber().startsWith("02")) {
                            user.setRoles(Collections.singleton(teacherRole));
                        } else {
                            user.setRoles(Collections.singleton(studentRole));
                        }
                        updated = true;
                    }

                    if (user.getRoleId() == null) {
                        if (user.getPhoneNumber() != null && user.getPhoneNumber().startsWith("02")) {
                            user.setRoleId(2L);
                        } else {
                            user.setRoleId(1L);
                        }
                        updated = true;
                    }

                    // Encrypt if password is null or plain text '123456' or doesn't look like BCrypt
                    String currentPw = user.getPassword();
                    if (currentPw == null || currentPw.isEmpty() || currentPw.equals("123456") || !currentPw.startsWith("$2a$")) {
                        user.setPassword(passwordEncoder.encode(currentPw == null || currentPw.isEmpty() ? "123456" : currentPw));
                        updated = true;
                    }

                    if (updated) {
                        userRepository.save(user);
                    }
                });
            }

            Map<String, User> studentsByPhone = userRepository.findByRoles_NameAndIsActiveTrueOrderByNameAsc(RoleName.STUDENT).stream()
                    .collect(Collectors.toMap(User::getPhoneNumber, Function.identity()));
            Map<String, User> teachersByName = userRepository.findByRoles_NameAndIsActiveTrueOrderByNameAsc(RoleName.TEACHER).stream()
                    .collect(Collectors.toMap(User::getName, Function.identity()));

            User studentA = studentsByPhone.get("0123456789");

            if (gradeRepository.count() == 0 && studentA != null) {
                String[] subjects = {"Toán", "Văn", "Anh Văn", "Vật Lý", "Hóa Học", "Sinh Học", "Lịch Sử", "Địa Lý", "Thể Dục", "Tin Học"};
                for (String subject : subjects) {
                    Grade grade = new Grade();
                    grade.setStudentId(studentA.getId());
                    grade.setClassName(studentA.getClassName());
                    grade.setTeacherId(resolveTeacherId(teachersByName, subject));
                    grade.setSemester(1);
                    grade.setSubject(subject);
                    try {
                        if (subject.equals("Toán")) {
                            grade.setTx15(objectMapper.writeValueAsString(List.of(8.5, 9.0, 7.5)));
                            grade.setTx1tiet(objectMapper.writeValueAsString(List.of(8.0, 8.5)));
                            grade.setGiuaKy(8.5);
                            grade.setCuoiKy(9.0);
                            grade.setAverage(8.5);
                        } else if (subject.equals("Văn")) {
                            grade.setTx15(objectMapper.writeValueAsString(List.of(8.0, 7.5, 8.5)));
                            grade.setTx1tiet(objectMapper.writeValueAsString(List.of(8.0, 7.5)));
                            grade.setGiuaKy(8.0);
                            grade.setCuoiKy(8.5);
                            grade.setAverage(8.1);
                        } else if (subject.equals("Anh Văn")) {
                            grade.setTx15(objectMapper.writeValueAsString(List.of(9.0, 9.5, 9.0)));
                            grade.setTx1tiet(objectMapper.writeValueAsString(List.of(9.0, 9.5)));
                            grade.setGiuaKy(9.0);
                            grade.setCuoiKy(9.5);
                            grade.setAverage(9.2);
                        } else {
                            grade.setTx15(objectMapper.writeValueAsString(List.of(8.0, 8.0, 8.0)));
                            grade.setTx1tiet(objectMapper.writeValueAsString(List.of(8.0, 8.0)));
                            grade.setGiuaKy(8.0);
                            grade.setCuoiKy(8.0);
                            grade.setAverage(8.0);
                        }
                    } catch (JsonProcessingException ignored) {
                    }
                    gradeRepository.save(grade);
                }
            }

            if (scheduleRepository.count() == 0) {
                SchoolClass class10A1 = schoolClassRepository.findAll().stream().filter(c -> c.getCode().equals("10A1")).findFirst().orElse(null);
                Long classId = class10A1 != null ? class10A1.getId() : 1L;

                scheduleRepository.saveAll(List.of(
                        createSchedule(classId, "10A1", 0, "1", "Toán", teachersByName.get("GV. Nguyễn Văn A"), "Phòng 301", "07:00", "07:45"),
                        createSchedule(classId, "10A1", 0, "2", "Văn", teachersByName.get("GV. Trần Thị B"), "Phòng 302", "07:50", "08:35"),
                        createSchedule(classId, "10A1", 0, "3", "Anh Văn", teachersByName.get("GV. Lê Văn C"), "Phòng 303", "08:40", "09:25"),
                        createSchedule(classId, "10A1", 0, "4", "Vật Lý", teachersByName.get("GV. Nguyễn Văn D"), "Phòng 304", "09:30", "10:15"),
                        createSchedule(classId, "10A1", 0, "5", "Hóa Học", teachersByName.get("GV. Trần Thị E"), "Phòng 305", "10:20", "11:05"),
                        createSchedule(classId, "10A1", 1, "1", "Sinh Học", teachersByName.get("GV. X"), "Phòng 201", "07:00", "07:45"),
                        createSchedule(classId, "10A1", 1, "2", "Lịch Sử", teachersByName.get("GV. Y"), "Phòng 202", "07:50", "08:35"),
                        createSchedule(classId, "10A1", 1, "3", "Địa Lý", teachersByName.get("GV. Z"), "Phòng 203", "08:40", "09:25"),
                        createSchedule(classId, "10A1", 1, "4", "Toán", teachersByName.get("GV. Nguyễn Văn A"), "Phòng 301", "09:30", "10:15"),
                        createSchedule(classId, "10A1", 2, "1", "Văn", teachersByName.get("GV. Trần Thị B"), "Phòng 302", "07:00", "07:45"),
                        createSchedule(classId, "10A1", 2, "2", "Anh Văn", teachersByName.get("GV. Lê Văn C"), "Phòng 303", "07:50", "08:35"),
                        createSchedule(classId, "10A1", 2, "3", "Thể Dục", teachersByName.get("GV. Sport"), "Sân bóng", "08:40", "09:25"),
                        createSchedule(classId, "10A1", 3, "1", "Toán", teachersByName.get("GV. Nguyễn Văn A"), "Phòng 301", "07:00", "07:45"),
                        createSchedule(classId, "10A1", 3, "2", "Vật Lý", teachersByName.get("GV. Nguyễn Văn D"), "Phòng 304", "07:50", "08:35"),
                        createSchedule(classId, "10A1", 3, "3", "Hóa Học", teachersByName.get("GV. Trần Thị E"), "Phòng 305", "08:40", "09:25"),
                        createSchedule(classId, "10A1", 3, "4", "Tin Học", teachersByName.get("GV. Tech"), "Phòng Lab", "09:30", "10:15"),
                        createSchedule(classId, "10A1", 4, "1", "Văn", teachersByName.get("GV. Trần Thị B"), "Phòng 302", "07:00", "07:45"),
                        createSchedule(classId, "10A1", 4, "2", "Anh Văn", teachersByName.get("GV. Lê Văn C"), "Phòng 303", "07:50", "08:35"),
                        createSchedule(classId, "10A1", 4, "3", "GDCD", teachersByName.get("GV. Moral"), "Phòng 306", "08:40", "09:25")
                ));
            }

            if (notificationRepository.count() == 0) {
                notificationRepository.saveAll(List.of(
                        createNotification("Thông báo đóng học phí học kỳ 2", "Học sinh vui lòng đóng học phí trước ngày 15/04.", "Ban Giám Hiệu", "FEE", "02/03/2026"),
                        createNotification("Thông báo nghỉ học ngày 08/03", "Trường nghỉ học để kỷ niệm.", "Ban Giám Hiệu", "IMPORTANT", "08/03/2026"),
                        createNotification("Kết quả kiểm tra giữa kỳ", "Kết quả đã được đăng.", "Phòng Giáo Vụ", "SCHOOL", "10/03/2026"),
                        createNotification("Hội thi văn nghệ chào mừng 20/11", "Tham gia đông đủ.", "Ban Tổ Chức", "SCHOOL", "20/11/2025"),
                        createNotification("Thông báo về đồng phục học sinh", "Quy định mới về đồng phục.", "Ban Giám Hiệu", "IMPORTANT", "01/02/2026"),
                        createNotification("Lịch thi học kỳ 2", "Lịch thi được cập nhật.", "Phòng Giáo Vụ", "IMPORTANT", "15/04/2026"),
                        createNotification("Hoạt động ngoại khóa tháng 3", "Các hoạt động sẽ diễn ra.", "Ban Học Sinh", "SCHOOL", "05/03/2026")
                ));
            }

            if (assignmentRepository.count() == 0) {
                assignmentRepository.saveAll(List.of(
                        createAssignment("10A1", "Toán", "Bài tập về hàm số", teachersByName.get("GV. Nguyễn Văn A"), LocalDate.now().plusDays(7)),
                        createAssignment("10A1", "Văn", "Làm văn tả người thân", teachersByName.get("GV. Trần Thị B"), LocalDate.now().plusDays(5)),
                        createAssignment("10A1", "Anh Văn", "Unit 5 - Speaking exercises", teachersByName.get("GV. Lê Văn C"), LocalDate.now().plusDays(10))
                ));
            }
        };
    }

    private Role ensureRole(RoleRepository roleRepository, RoleName roleName, String description) {
        return roleRepository.findByName(roleName).orElseGet(() -> {
            Role role = new Role();
            role.setName(roleName);
            role.setDescription(description);
            return roleRepository.save(role);
        });
    }

    private User createStudent(String name, String phoneNumber, String className, String email, LocalDate dateOfBirth, Role role) {
        User user = new User();
        user.setName(name);
        user.setPhoneNumber(phoneNumber);
        user.setClassName(className);
        user.setEmail(email);
        user.setDateOfBirth(dateOfBirth);
        user.setRoles(Collections.singleton(role));
        user.setRoleId(1L);
        user.setParentName("Phụ huynh " + name);
        user.setParentPhone("0900000000");
        user.setPassword("123456");
        return user;
    }

    private User createTeacher(String name, String phoneNumber, String subject, String employeeCode, Role role) {
        User user = new User();
        user.setName(name);
        user.setPhoneNumber(phoneNumber);
        user.setEmail(employeeCode.toLowerCase() + "@fschool.edu.vn");
        user.setSubject(subject);
        user.setEmployeeCode(employeeCode);
        user.setRoles(Collections.singleton(role));
        user.setRoleId(2L);
        user.setPassword("123456");
        return user;
    }

    private User createAdmin(String name, String phoneNumber, String email, Role role) {
        User user = new User();
        user.setName(name);
        user.setPhoneNumber(phoneNumber);
        user.setEmail(email);
        user.setRoles(Collections.singleton(role));
        user.setRoleId(3L);
        user.setPassword("123456");
        return user;
    }

    private Long resolveTeacherId(Map<String, User> teachersByName, String subject) {
        User teacher = teachersByName.get(resolveTeacherName(subject));
        return teacher != null ? teacher.getId() : null;
    }

    private String resolveTeacherName(String subject) {
        return switch (subject) {
            case "Toán" -> "GV. Nguyễn Văn A";
            case "Văn" -> "GV. Trần Thị B";
            case "Anh Văn" -> "GV. Lê Văn C";
            case "Vật Lý" -> "GV. Nguyễn Văn D";
            case "Hóa Học" -> "GV. Trần Thị E";
            case "Sinh Học" -> "GV. X";
            case "Lịch Sử" -> "GV. Y";
            case "Địa Lý" -> "GV. Z";
            case "Thể Dục" -> "GV. Sport";
            case "Tin Học" -> "GV. Tech";
            case "GDCD" -> "GV. Moral";
            default -> null;
        };
    }

    private Schedule createSchedule(Long classId, String className, int day, String period, String subject, User teacher, String room, String start, String end) {
        Schedule s = new Schedule();
        s.setClassId(classId);
        s.setClassName(className);
        s.setSchoolYear("2025-2026");
        s.setSemester(1);
        s.setDayOfWeek(day);
        s.setPeriod(period);
        s.setSubject(subject);
        s.setTeacher(teacher != null ? teacher.getName() : null);
        s.setTeacherId(teacher != null ? teacher.getId() : null);
        s.setRoom(room);
        s.setStartTime(start);
        s.setEndTime(end);
        return s;
    }

    private Notification createNotification(String title, String content, String sender, String category, String date) {
        Notification n = new Notification();
        n.setTitle(title);
        n.setContent(content);
        n.setSender(sender);
        n.setCategory(category);
        n.setCreatedAtCustom(LocalDateTime.now());
        n.setDate(date);
        return n;
    }

    private Assignment createAssignment(String className, String subject, String title, User teacher, LocalDate dueDate) {
        Assignment a = new Assignment();
        a.setClassName(className);
        a.setSubject(subject);
        a.setTitle(title);
        a.setDescription(title + " - chi tiết bài tập");
        a.setTeacher(teacher != null ? teacher.getName() : null);
        a.setTeacherId(teacher != null ? teacher.getId() : null);
        a.setDueDate(dueDate);
        a.setCreatedAtCustom(LocalDateTime.now());
        return a;
    }
}
