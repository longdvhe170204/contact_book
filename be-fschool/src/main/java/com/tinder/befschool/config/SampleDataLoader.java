package com.tinder.befschool.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tinder.befschool.entity.Assignment;
import com.tinder.befschool.entity.Grade;
import com.tinder.befschool.entity.Invoice;
import com.tinder.befschool.entity.Notification;
import com.tinder.befschool.entity.Role;
import com.tinder.befschool.entity.RoleName;
import com.tinder.befschool.entity.Schedule;
import com.tinder.befschool.entity.SchoolClass;
import com.tinder.befschool.entity.SchoolClassStatus;
import com.tinder.befschool.entity.Subject;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.repository.AssignmentRepository;
import com.tinder.befschool.repository.GradeRepository;
import com.tinder.befschool.repository.InvoiceRepository;
import com.tinder.befschool.repository.NotificationRepository;
import com.tinder.befschool.repository.RoleRepository;
import com.tinder.befschool.repository.ScheduleRepository;
import com.tinder.befschool.repository.SchoolClassRepository;
import com.tinder.befschool.repository.SubjectRepository;
import com.tinder.befschool.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Configuration
public class SampleDataLoader {

    private static final String DEFAULT_PASSWORD = "123456";
    private static final String DEFAULT_SCHOOL_YEAR = "2026-2027";
    private static final int DEFAULT_SEMESTER = 1;
    private static final int DEFAULT_MAXIMUM_STUDENTS = 45;
    private static final String NOT_APPLICABLE = "Không áp dụng";

    private record PeriodTime(String startTime, String endTime) {
    }

    private static final Map<String, PeriodTime> PERIOD_TIMES = Map.ofEntries(
            Map.entry("1", new PeriodTime("07:00", "07:45")),
            Map.entry("2", new PeriodTime("07:50", "08:35")),
            Map.entry("3", new PeriodTime("08:50", "09:35")),
            Map.entry("4", new PeriodTime("09:40", "10:25")),
            Map.entry("5", new PeriodTime("10:30", "11:15")),
            Map.entry("6", new PeriodTime("13:00", "13:45")),
            Map.entry("7", new PeriodTime("13:50", "14:35")),
            Map.entry("8", new PeriodTime("14:50", "15:35")),
            Map.entry("9", new PeriodTime("15:40", "16:25")),
            Map.entry("10", new PeriodTime("16:30", "17:15"))
    );

    @Bean
    CommandLineRunner runner(
            UserRepository userRepository,
            RoleRepository roleRepository,
            GradeRepository gradeRepository,
            ScheduleRepository scheduleRepository,
            NotificationRepository notificationRepository,
            AssignmentRepository assignmentRepository,
            SubjectRepository subjectRepository,
            SchoolClassRepository schoolClassRepository,
            InvoiceRepository invoiceRepository,
            ObjectMapper objectMapper,
            PasswordEncoder passwordEncoder
    ) {
        return args -> {
            Role studentRole = ensureRole(
                    roleRepository,
                    RoleName.STUDENT,
                    "Tài khoản học sinh"
            );

            Role teacherRole = ensureRole(
                    roleRepository,
                    RoleName.TEACHER,
                    "Tài khoản giáo viên"
            );

            ensureSubjects(subjectRepository);
            ensureUsers(userRepository, studentRole, teacherRole, passwordEncoder);

            Map<String, User> studentsByPhone = userRepository
                    .findByRoles_NameOrderByNameAsc(RoleName.STUDENT)
                    .stream()
                    .collect(Collectors.toMap(
                            User::getPhoneNumber,
                            Function.identity(),
                            (first, second) -> first
                    ));

            Map<String, User> teachersByName = userRepository
                    .findByRoles_NameOrderByNameAsc(RoleName.TEACHER)
                    .stream()
                    .collect(Collectors.toMap(
                            User::getName,
                            Function.identity(),
                            (first, second) -> first
                    ));

            Map<String, Subject> subjectsByName = subjectRepository
                    .findAll()
                    .stream()
                    .collect(Collectors.toMap(
                            Subject::getName,
                            Function.identity(),
                            (first, second) -> first
                    ));

            User homeroom10A1 = requireTeacher(
                    teachersByName,
                    "GV. Nguyễn Văn A"
            );

            User homeroom10A2 = requireTeacher(
                    teachersByName,
                    "GV. Lê Văn C"
            );

            SchoolClass class10A1 = ensureSchoolClass(
                    schoolClassRepository,
                    "10A1",
                    "Lớp 10A1",
                    10,
                    DEFAULT_SCHOOL_YEAR,
                    homeroom10A1.getId()
            );

            ensureSchoolClass(
                    schoolClassRepository,
                    "10A2",
                    "Lớp 10A2",
                    10,
                    DEFAULT_SCHOOL_YEAR,
                    homeroom10A2.getId()
            );

            User studentA = requireStudent(
                    studentsByPhone,
                    "0123456789"
            );

            ensureGrades(
                    gradeRepository,
                    objectMapper,
                    studentA,
                    teachersByName
            );

            ensureSchedules(
                    scheduleRepository,
                    class10A1,
                    subjectsByName,
                    teachersByName
            );

            ensureNotifications(notificationRepository);
            ensureAssignments(assignmentRepository, teachersByName);
            ensureInvoices(invoiceRepository, studentA);
        };
    }

    private Role ensureRole(
            RoleRepository roleRepository,
            RoleName roleName,
            String description
    ) {
        Role role = roleRepository.findByName(roleName)
                .orElseGet(() -> {
                    Role created = new Role();
                    created.setName(roleName);
                    created.setDescription(description);
                    return roleRepository.save(created);
                });

        if (role.getDescription() == null || role.getDescription().isBlank()) {
            role.setDescription(description);
            role = roleRepository.save(role);
        }

        return role;
    }

    private void ensureSubjects(SubjectRepository subjectRepository) {
        List<String> subjectNames = List.of(
                "Toán",
                "Văn",
                "Anh Văn",
                "Vật Lý",
                "Hóa Học",
                "Sinh Học",
                "Lịch Sử",
                "Địa Lý",
                "Thể Dục",
                "Tin Học",
                "GDCD"
        );

        Map<String, Subject> existingSubjects = subjectRepository
                .findAll()
                .stream()
                .collect(Collectors.toMap(
                        Subject::getName,
                        Function.identity(),
                        (first, second) -> first
                ));

        for (String subjectName : subjectNames) {
            Subject subject = existingSubjects.get(subjectName);

            if (subject == null) {
                subject = new Subject();
                subject.setName(subjectName);
                subject.setDescription("Môn " + subjectName);
                subjectRepository.save(subject);
                continue;
            }

            if (subject.getDescription() == null
                    || subject.getDescription().isBlank()) {
                subject.setDescription("Môn " + subjectName);
                subjectRepository.save(subject);
            }
        }
    }

    private void ensureUsers(
            UserRepository userRepository,
            Role studentRole,
            Role teacherRole,
            PasswordEncoder passwordEncoder
    ) {
        ensureUser(
                userRepository,
                createStudent(
                        "Nguyễn Văn A",
                        "0123456789",
                        "10A1",
                        "a@example.com",
                        LocalDate.of(2008, 1, 1),
                        studentRole
                ),
                studentRole,
                passwordEncoder
        );

        ensureUser(
                userRepository,
                createStudent(
                        "Trần Thị B",
                        "0987654321",
                        "10A1",
                        "b@example.com",
                        LocalDate.of(2008, 2, 2),
                        studentRole
                ),
                studentRole,
                passwordEncoder
        );

        ensureUser(
                userRepository,
                createStudent(
                        "Lê Văn C",
                        "0111222333",
                        "10A2",
                        "c@example.com",
                        LocalDate.of(2008, 3, 3),
                        studentRole
                ),
                studentRole,
                passwordEncoder
        );

        ensureUser(userRepository, createTeacher("GV. Nguyễn Văn A", "0200000001", "Toán", "T001", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Trần Thị B", "0200000002", "Văn", "T002", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Lê Văn C", "0200000003", "Anh Văn", "T003", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Nguyễn Văn D", "0200000004", "Vật Lý", "T004", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Trần Thị E", "0200000005", "Hóa Học", "T005", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. X", "0200000006", "Sinh Học", "T006", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Y", "0200000007", "Lịch Sử", "T007", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Z", "0200000008", "Địa Lý", "T008", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Sport", "0200000009", "Thể Dục", "T009", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Tech", "0200000010", "Tin Học", "T010", teacherRole), teacherRole, passwordEncoder);
        ensureUser(userRepository, createTeacher("GV. Moral", "0200000011", "GDCD", "T011", teacherRole), teacherRole, passwordEncoder);
    }

    private void ensureUser(
            UserRepository userRepository,
            User sample,
            Role requiredRole,
            PasswordEncoder passwordEncoder
    ) {
        User user = userRepository.findAll()
                .stream()
                .filter(item -> sample.getPhoneNumber().equals(item.getPhoneNumber()))
                .findFirst()
                .orElse(sample);

        user.setName(defaultText(user.getName(), sample.getName()));
        user.setPhoneNumber(sample.getPhoneNumber());
        user.setClassName(defaultText(user.getClassName(), sample.getClassName()));
        user.setEmail(defaultText(user.getEmail(), sample.getEmail()));
        user.setDateOfBirth(user.getDateOfBirth() != null ? user.getDateOfBirth() : sample.getDateOfBirth());
        user.setAddress(defaultText(user.getAddress(), sample.getAddress()));
        user.setParentName(defaultText(user.getParentName(), sample.getParentName()));
        user.setParentPhone(defaultText(user.getParentPhone(), sample.getParentPhone()));
        user.setSubject(defaultText(user.getSubject(), sample.getSubject()));
        user.setEmployeeCode(defaultText(user.getEmployeeCode(), sample.getEmployeeCode()));
        user.setRoles(Collections.singleton(requiredRole));
        user.setRoleId(requiredRole.getId());

        String currentPassword = user.getPassword();
        if (currentPassword == null
                || currentPassword.isBlank()
                || !isBcrypt(currentPassword)) {
            String rawPassword = currentPassword == null || currentPassword.isBlank()
                    ? DEFAULT_PASSWORD
                    : currentPassword;
            user.setPassword(passwordEncoder.encode(rawPassword));
        }

        userRepository.save(user);
    }

    private boolean isBcrypt(String password) {
        return password.startsWith("$2a$")
                || password.startsWith("$2b$")
                || password.startsWith("$2y$");
    }

    private User createStudent(
            String name,
            String phoneNumber,
            String className,
            String email,
            LocalDate dateOfBirth,
            Role role
    ) {
        User user = new User();
        user.setName(name);
        user.setPhoneNumber(phoneNumber);
        user.setClassName(className);
        user.setEmail(email);
        user.setDateOfBirth(dateOfBirth);
        user.setAddress("Hà Nội");
        user.setParentName("Phụ huynh " + name);
        user.setParentPhone("0900000000");
        user.setSubject(NOT_APPLICABLE);
        user.setEmployeeCode(NOT_APPLICABLE);
        user.setPassword(DEFAULT_PASSWORD);
        user.setRoles(Collections.singleton(role));
        user.setRoleId(role.getId());
        return user;
    }

    private User createTeacher(
            String name,
            String phoneNumber,
            String subject,
            String employeeCode,
            Role role
    ) {
        User user = new User();
        user.setName(name);
        user.setPhoneNumber(phoneNumber);
        user.setClassName(NOT_APPLICABLE);
        user.setEmail(employeeCode.toLowerCase() + "@fschool.edu.vn");
        user.setDateOfBirth(LocalDate.of(1990, 1, 1));
        user.setAddress("Hà Nội");
        user.setParentName(NOT_APPLICABLE);
        user.setParentPhone("0000000000");
        user.setSubject(subject);
        user.setEmployeeCode(employeeCode);
        user.setPassword(DEFAULT_PASSWORD);
        user.setRoles(Collections.singleton(role));
        user.setRoleId(role.getId());
        return user;
    }

    private SchoolClass ensureSchoolClass(
            SchoolClassRepository schoolClassRepository,
            String code,
            String name,
            int gradeLevel,
            String schoolYear,
            Long homeroomTeacherId
    ) {
        SchoolClass schoolClass = schoolClassRepository
                .findByCodeIgnoreCaseAndSchoolYear(code, schoolYear)
                .orElseGet(SchoolClass::new);

        schoolClass.setCode(code);
        schoolClass.setName(name);
        schoolClass.setGradeLevel(gradeLevel);
        schoolClass.setSchoolYear(schoolYear);
        schoolClass.setHomeroomTeacherId(homeroomTeacherId);
        schoolClass.setMaximumStudents(DEFAULT_MAXIMUM_STUDENTS);
        schoolClass.setStatus(SchoolClassStatus.ACTIVE);

        return schoolClassRepository.save(schoolClass);
    }

    private void ensureGrades(
            GradeRepository gradeRepository,
            ObjectMapper objectMapper,
            User student,
            Map<String, User> teachersByName
    ) {
        if (gradeRepository.count() != 0) {
            return;
        }

        List<String> subjects = List.of(
                "Toán",
                "Văn",
                "Anh Văn",
                "Vật Lý",
                "Hóa Học",
                "Sinh Học",
                "Lịch Sử",
                "Địa Lý",
                "Thể Dục",
                "Tin Học"
        );

        for (String subject : subjects) {
            Grade grade = new Grade();
            grade.setStudentId(student.getId());
            grade.setClassName(requireText(student.getClassName(), "Lớp của học sinh"));
            grade.setTeacherId(resolveTeacherIdRequired(teachersByName, subject));
            grade.setSemester(DEFAULT_SEMESTER);
            grade.setSubject(subject);

            try {
                if ("Toán".equals(subject)) {
                    setGradeValues(objectMapper, grade, List.of(8.5, 9.0, 7.5), List.of(8.0, 8.5), 8.5, 9.0, 8.5);
                } else if ("Văn".equals(subject)) {
                    setGradeValues(objectMapper, grade, List.of(8.0, 7.5, 8.5), List.of(8.0, 7.5), 8.0, 8.5, 8.1);
                } else if ("Anh Văn".equals(subject)) {
                    setGradeValues(objectMapper, grade, List.of(9.0, 9.5, 9.0), List.of(9.0, 9.5), 9.0, 9.5, 9.2);
                } else {
                    setGradeValues(objectMapper, grade, List.of(8.0, 8.0, 8.0), List.of(8.0, 8.0), 8.0, 8.0, 8.0);
                }
            } catch (JsonProcessingException exception) {
                throw new IllegalStateException(
                        "Không thể chuyển điểm sang JSON cho môn " + subject,
                        exception
                );
            }

            gradeRepository.save(grade);
        }
    }

    private void setGradeValues(
            ObjectMapper objectMapper,
            Grade grade,
            List<Double> tx15,
            List<Double> tx1Tiet,
            double giuaKy,
            double cuoiKy,
            double average
    ) throws JsonProcessingException {
        grade.setTx15(objectMapper.writeValueAsString(tx15));
        grade.setTx1tiet(objectMapper.writeValueAsString(tx1Tiet));
        grade.setGiuaKy(giuaKy);
        grade.setCuoiKy(cuoiKy);
        grade.setAverage(average);
    }

    private void ensureSchedules(
            ScheduleRepository scheduleRepository,
            SchoolClass schoolClass,
            Map<String, Subject> subjectsByName,
            Map<String, User> teachersByName
    ) {
        if (scheduleRepository.count() != 0) {
            return;
        }

        scheduleRepository.saveAll(List.of(
                createSchedule(schoolClass, 0, "1", requireSubject(subjectsByName, "Toán"), requireTeacher(teachersByName, "GV. Nguyễn Văn A"), "Phòng 301"),
                createSchedule(schoolClass, 0, "2", requireSubject(subjectsByName, "Văn"), requireTeacher(teachersByName, "GV. Trần Thị B"), "Phòng 302"),
                createSchedule(schoolClass, 0, "3", requireSubject(subjectsByName, "Anh Văn"), requireTeacher(teachersByName, "GV. Lê Văn C"), "Phòng 303"),
                createSchedule(schoolClass, 0, "4", requireSubject(subjectsByName, "Vật Lý"), requireTeacher(teachersByName, "GV. Nguyễn Văn D"), "Phòng 304"),
                createSchedule(schoolClass, 0, "5", requireSubject(subjectsByName, "Hóa Học"), requireTeacher(teachersByName, "GV. Trần Thị E"), "Phòng 305"),

                createSchedule(schoolClass, 1, "1", requireSubject(subjectsByName, "Sinh Học"), requireTeacher(teachersByName, "GV. X"), "Phòng 201"),
                createSchedule(schoolClass, 1, "2", requireSubject(subjectsByName, "Lịch Sử"), requireTeacher(teachersByName, "GV. Y"), "Phòng 202"),
                createSchedule(schoolClass, 1, "3", requireSubject(subjectsByName, "Địa Lý"), requireTeacher(teachersByName, "GV. Z"), "Phòng 203"),
                createSchedule(schoolClass, 1, "4", requireSubject(subjectsByName, "Toán"), requireTeacher(teachersByName, "GV. Nguyễn Văn A"), "Phòng 301"),

                createSchedule(schoolClass, 2, "1", requireSubject(subjectsByName, "Văn"), requireTeacher(teachersByName, "GV. Trần Thị B"), "Phòng 302"),
                createSchedule(schoolClass, 2, "2", requireSubject(subjectsByName, "Anh Văn"), requireTeacher(teachersByName, "GV. Lê Văn C"), "Phòng 303"),
                createSchedule(schoolClass, 2, "3", requireSubject(subjectsByName, "Thể Dục"), requireTeacher(teachersByName, "GV. Sport"), "Sân bóng"),

                createSchedule(schoolClass, 3, "1", requireSubject(subjectsByName, "Toán"), requireTeacher(teachersByName, "GV. Nguyễn Văn A"), "Phòng 301"),
                createSchedule(schoolClass, 3, "2", requireSubject(subjectsByName, "Vật Lý"), requireTeacher(teachersByName, "GV. Nguyễn Văn D"), "Phòng 304"),
                createSchedule(schoolClass, 3, "3", requireSubject(subjectsByName, "Hóa Học"), requireTeacher(teachersByName, "GV. Trần Thị E"), "Phòng 305"),
                createSchedule(schoolClass, 3, "4", requireSubject(subjectsByName, "Tin Học"), requireTeacher(teachersByName, "GV. Tech"), "Phòng Lab"),

                createSchedule(schoolClass, 4, "1", requireSubject(subjectsByName, "Văn"), requireTeacher(teachersByName, "GV. Trần Thị B"), "Phòng 302"),
                createSchedule(schoolClass, 4, "2", requireSubject(subjectsByName, "Anh Văn"), requireTeacher(teachersByName, "GV. Lê Văn C"), "Phòng 303"),
                createSchedule(schoolClass, 4, "3", requireSubject(subjectsByName, "GDCD"), requireTeacher(teachersByName, "GV. Moral"), "Phòng 306")
        ));
    }

    private Schedule createSchedule(
            SchoolClass schoolClass,
            int dayOfWeek,
            String period,
            Subject subject,
            User teacher,
            String room
    ) {
        if (schoolClass == null || schoolClass.getId() == null) {
            throw new IllegalArgumentException("Lớp học không hợp lệ");
        }

        if (subject == null || subject.getId() == null) {
            throw new IllegalArgumentException("Môn học không hợp lệ");
        }

        if (teacher == null || teacher.getId() == null) {
            throw new IllegalArgumentException("Giáo viên không hợp lệ");
        }

        if (dayOfWeek < 0 || dayOfWeek > 6) {
            throw new IllegalArgumentException("Ngày học phải từ 0 đến 6");
        }

        String normalizedPeriod = requireText(period, "Tiết học");
        PeriodTime periodTime = PERIOD_TIMES.get(normalizedPeriod);

        if (periodTime == null) {
            throw new IllegalArgumentException("Tiết học phải từ 1 đến 10");
        }

        Schedule schedule = new Schedule();
        schedule.setClassId(schoolClass.getId());
        schedule.setClassName(requireText(schoolClass.getCode(), "Mã lớp"));
        schedule.setDayOfWeek(dayOfWeek);
        schedule.setPeriod(normalizedPeriod);
        schedule.setSubjectId(subject.getId());
        schedule.setSubject(requireText(subject.getName(), "Tên môn học"));
        schedule.setTeacherId(teacher.getId());
        schedule.setTeacher(requireText(teacher.getName(), "Tên giáo viên"));
        schedule.setRoom(requireText(room, "Phòng học"));
        schedule.setSchoolYear(DEFAULT_SCHOOL_YEAR);
        schedule.setSemester(DEFAULT_SEMESTER);
        schedule.setStartTime(periodTime.startTime());
        schedule.setEndTime(periodTime.endTime());
        return schedule;
    }

    private void ensureNotifications(NotificationRepository notificationRepository) {
        if (notificationRepository.count() != 0) {
            return;
        }

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

    private Notification createNotification(
            String title,
            String content,
            String sender,
            String category,
            String date
    ) {
        Notification notification = new Notification();
        notification.setTitle(requireText(title, "Tiêu đề thông báo"));
        notification.setContent(requireText(content, "Nội dung thông báo"));
        notification.setSender(requireText(sender, "Người gửi"));
        notification.setCategory(requireText(category, "Loại thông báo"));
        notification.setCreatedAtCustom(LocalDateTime.now());
        notification.setDate(requireText(date, "Ngày hiển thị"));
        return notification;
    }

    private void ensureAssignments(
            AssignmentRepository assignmentRepository,
            Map<String, User> teachersByName
    ) {
        if (assignmentRepository.count() != 0) {
            return;
        }

        assignmentRepository.saveAll(List.of(
                createAssignment("10A1", "Toán", "Bài tập về hàm số", requireTeacher(teachersByName, "GV. Nguyễn Văn A"), LocalDate.now().plusDays(7)),
                createAssignment("10A1", "Văn", "Làm văn tả người thân", requireTeacher(teachersByName, "GV. Trần Thị B"), LocalDate.now().plusDays(5)),
                createAssignment("10A1", "Anh Văn", "Unit 5 - Speaking exercises", requireTeacher(teachersByName, "GV. Lê Văn C"), LocalDate.now().plusDays(10))
        ));
    }

    private Assignment createAssignment(
            String className,
            String subject,
            String title,
            User teacher,
            LocalDate dueDate
    ) {
        if (teacher == null || teacher.getId() == null) {
            throw new IllegalArgumentException("Giáo viên không hợp lệ");
        }

        if (dueDate == null) {
            throw new IllegalArgumentException("Hạn nộp không được để trống");
        }

        Assignment assignment = new Assignment();
        assignment.setClassName(requireText(className, "Tên lớp"));
        assignment.setSubject(requireText(subject, "Tên môn học"));
        assignment.setTitle(requireText(title, "Tiêu đề bài tập"));
        assignment.setDescription(title + " - chi tiết bài tập");
        assignment.setTeacher(requireText(teacher.getName(), "Tên giáo viên"));
        assignment.setTeacherId(teacher.getId());
        assignment.setDueDate(dueDate);
        assignment.setCreatedAtCustom(LocalDateTime.now());
        return assignment;
    }

    private void ensureInvoices(
            InvoiceRepository invoiceRepository,
            User student
    ) {
        if (invoiceRepository.count() != 0) {
            return;
        }

        // Tạo 3 hóa đơn mẫu cho học sinh Nguyễn Văn A
        invoiceRepository.saveAll(List.of(
                createInvoice(
                        student,
                        "Học phí Học kỳ 1 - Năm học 2026-2027",
                        "Tiền học phí chuẩn theo quy định của trường",
                        new java.math.BigDecimal("1500000"),
                        LocalDateTime.now().plusDays(15),
                        "PENDING"
                ),
                createInvoice(
                        student,
                        "Phí hoạt động ngoại khóa Họk1",
                        "Phí tham gia các hoạt động ngoại khóa và câu lạc bộ",
                        new java.math.BigDecimal("200000"),
                        LocalDateTime.now().plusDays(10),
                        "PENDING"
                ),
                createInvoice(
                        student,
                        "Phí ăn bán trú tháng 01/2026",
                        "Phí dịch vụ ăn bán trú tại trường",
                        new java.math.BigDecimal("600000"),
                        LocalDateTime.now().minusDays(5),
                        "PAID" // Hóa đơn này đã được thanh toán rồi (để demo)
                )
        ));
    }

    private Invoice createInvoice(
            User student,
            String title,
            String description,
            java.math.BigDecimal amount,
            LocalDateTime dueDate,
            String status
    ) {
        Invoice invoice = new Invoice();
        invoice.setStudent(student);
        invoice.setTitle(title);
        invoice.setDescription(description);
        invoice.setAmount(amount);
        invoice.setDueDate(dueDate);
        invoice.setStatus(status);
        return invoice;
    }

    private Long resolveTeacherIdRequired(
            Map<String, User> teachersByName,
            String subject
    ) {
        String teacherName = resolveTeacherName(subject);

        if (teacherName == null) {
            throw new IllegalStateException(
                    "Không có giáo viên được cấu hình cho môn " + subject
            );
        }

        return requireTeacher(teachersByName, teacherName).getId();
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

    private Subject requireSubject(
            Map<String, Subject> subjectsByName,
            String subjectName
    ) {
        Subject subject = subjectsByName.get(subjectName);

        if (subject == null || subject.getId() == null) {
            throw new IllegalStateException(
                    "Không tìm thấy môn học: " + subjectName
            );
        }

        return subject;
    }

    private User requireTeacher(
            Map<String, User> teachersByName,
            String teacherName
    ) {
        User teacher = teachersByName.get(teacherName);

        if (teacher == null || teacher.getId() == null) {
            throw new IllegalStateException(
                    "Không tìm thấy giáo viên: " + teacherName
            );
        }

        return teacher;
    }

    private User requireStudent(
            Map<String, User> studentsByPhone,
            String phoneNumber
    ) {
        User student = studentsByPhone.get(phoneNumber);

        if (student == null || student.getId() == null) {
            throw new IllegalStateException(
                    "Không tìm thấy học sinh có số điện thoại: " + phoneNumber
            );
        }

        return student;
    }

    private String defaultText(String currentValue, String defaultValue) {
        return currentValue == null || currentValue.isBlank()
                ? requireText(defaultValue, "Giá trị mặc định")
                : currentValue.trim();
    }

    private String requireText(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    fieldName + " không được để trống"
            );
        }

        return value.trim();
    }
}