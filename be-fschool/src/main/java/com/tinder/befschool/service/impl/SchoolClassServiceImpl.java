package com.tinder.befschool.service.impl;

import com.tinder.befschool.dto.classroom.*;
import com.tinder.befschool.entity.*;
import com.tinder.befschool.exception.ApiException;
import com.tinder.befschool.exception.NotFoundException;
import com.tinder.befschool.repository.*;
import com.tinder.befschool.service.SchoolClassService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class SchoolClassServiceImpl implements SchoolClassService {
    private final SchoolClassRepository classRepository;
    private final ClassMembershipRepository membershipRepository;
    private final UserRepository userRepository;

    public SchoolClassServiceImpl(SchoolClassRepository classRepository,
                                  ClassMembershipRepository membershipRepository,
                                  UserRepository userRepository) {
        this.classRepository = classRepository;
        this.membershipRepository = membershipRepository;
        this.userRepository = userRepository;
    }

    @Override
    public List<SchoolClassResponse> findAll() {
        return classRepository.findAllByOrderBySchoolYearDescGradeLevelAscCodeAsc()
                .stream().map(this::toResponse).toList();
    }

    @Override
    public SchoolClassResponse findById(Long classId) { return toResponse(getClassOrThrow(classId)); }

    @Override
    @Transactional
    public SchoolClassResponse create(CreateSchoolClassRequest request) {
        validateSchoolYear(request.schoolYear());
        String code = normalizeCode(request.code());
        if (classRepository.existsByCodeIgnoreCaseAndSchoolYear(code, request.schoolYear())) {
            throw new ApiException("Mã lớp đã tồn tại trong năm học này");
        }
        if (request.homeroomTeacherId() != null) {
            validateTeacher(request.homeroomTeacherId());
            ensureTeacherAvailable(request.homeroomTeacherId(), request.schoolYear(), null);
        }
        SchoolClass entity = new SchoolClass();
        entity.setCode(code);
        entity.setName(request.name().trim());
        entity.setGradeLevel(request.gradeLevel());
        entity.setSchoolYear(request.schoolYear());
        entity.setHomeroomTeacherId(request.homeroomTeacherId());
        entity.setMaximumStudents(request.maximumStudents());
        entity.setStatus(SchoolClassStatus.ACTIVE);
        return toResponse(classRepository.save(entity));
    }

    @Override
    @Transactional
    public SchoolClassResponse update(Long classId, UpdateSchoolClassRequest request) {
        SchoolClass entity = getClassOrThrow(classId);
        entity.setName(request.name().trim());
        entity.setGradeLevel(request.gradeLevel());
        entity.setMaximumStudents(request.maximumStudents());
        if (request.status() != null) entity.setStatus(request.status());
        ensureCapacity(entity, 0);
        return toResponse(classRepository.save(entity));
    }

    @Override
    @Transactional
    public SchoolClassResponse close(Long classId) {
        SchoolClass entity = getClassOrThrow(classId);
        entity.setStatus(SchoolClassStatus.CLOSED);
        return toResponse(classRepository.save(entity));
    }

    @Override
    @Transactional
    public SchoolClassResponse assignHomeroomTeacher(Long classId, Long teacherId) {
        SchoolClass entity = getActiveClass(classId);
        validateTeacher(teacherId);
        ensureTeacherAvailable(teacherId, entity.getSchoolYear(), classId);
        entity.setHomeroomTeacherId(teacherId);
        return toResponse(classRepository.save(entity));
    }

    @Override
    @Transactional
    public SchoolClassResponse removeHomeroomTeacher(Long classId) {
        SchoolClass entity = getClassOrThrow(classId);
        entity.setHomeroomTeacherId(null);
        return toResponse(classRepository.save(entity));
    }

    @Override
    public List<UnassignedStudentResponse> getUnassignedStudents(String schoolYear) {
        validateSchoolYear(schoolYear);
        Set<Long> assignedIds = membershipRepository
                .findBySchoolYearAndStatus(schoolYear, ClassMembershipStatus.ACTIVE)
                .stream()
                .map(ClassMembership::getStudentId)
                .collect(Collectors.toSet());

        return userRepository.findByRoles_NameOrderByNameAsc(RoleName.STUDENT)
                .stream()
                .filter(student -> !assignedIds.contains(student.getId()))
                .map(student -> new UnassignedStudentResponse(
                        student.getId(), student.getName(), student.getPhoneNumber(), student.getEmail(),
                        student.getParentName(), student.getParentPhone()))
                .toList();
    }

    @Override
    public List<ClassStudentResponse> getStudents(Long classId) {
        getClassOrThrow(classId);
        List<ClassMembership> memberships = membershipRepository
                .findByClassIdAndStatusOrderByStudentIdAsc(classId, ClassMembershipStatus.ACTIVE);
        Map<Long, User> users = userRepository.findAllById(
                        memberships.stream().map(ClassMembership::getStudentId).toList())
                .stream().collect(Collectors.toMap(User::getId, Function.identity()));
        return memberships.stream()
                .filter(m -> users.containsKey(m.getStudentId()))
                .map(m -> toStudentResponse(users.get(m.getStudentId()), m))
                .toList();
    }

    @Override
    @Transactional
    public List<ClassStudentResponse> addStudents(Long classId, AddStudentsToClassRequest request) {
        SchoolClass target = getActiveClass(classId);
        List<Long> distinctIds = request.studentIds().stream().distinct().toList();
        if (distinctIds.size() != request.studentIds().size()) {
            throw new ApiException("Danh sách học sinh chứa ID trùng");
        }
        List<User> students = userRepository.findAllById(distinctIds);
        if (students.size() != distinctIds.size()) throw new NotFoundException("Có học sinh không tồn tại");
        students.forEach(this::validateStudent);
        ensureCapacity(target, students.size());

        for (User student : students) {
            if (membershipRepository.findByStudentIdAndSchoolYearAndStatus(
                    student.getId(), target.getSchoolYear(), ClassMembershipStatus.ACTIVE).isPresent()) {
                throw new ApiException("Học sinh " + student.getName() + " đã thuộc một lớp trong năm học này");
            }
        }

        List<ClassMembership> memberships = new ArrayList<>();
        for (User student : students) {
            ClassMembership membership = new ClassMembership();
            membership.setStudentId(student.getId());
            membership.setClassId(target.getId());
            membership.setSchoolYear(target.getSchoolYear());
            membership.setJoinedDate(request.joinedDate());
            membership.setStatus(ClassMembershipStatus.ACTIVE);
            memberships.add(membership);

            // Tương thích ngược với các module hiện đang đọc User.className.
            student.setClassName(target.getCode());
        }
        membershipRepository.saveAll(memberships);
        userRepository.saveAll(students);
        return getStudents(classId);
    }

    @Override
    @Transactional
    public void removeStudent(Long classId, Long studentId, RemoveStudentRequest request) {
        SchoolClass schoolClass = getClassOrThrow(classId);
        ClassMembership membership = membershipRepository
                .findFirstByStudentIdAndSchoolYearAndStatus(studentId, schoolClass.getSchoolYear(), ClassMembershipStatus.ACTIVE)
                .orElseThrow(() -> new NotFoundException("Học sinh không có membership đang hoạt động"));
        if (!Objects.equals(membership.getClassId(), classId)) throw new ApiException("Học sinh không thuộc lớp này");
        membership.setStatus(ClassMembershipStatus.REMOVED);
        membership.setLeftDate(request.effectiveDate());
        membership.setReason(request.reason());
        membershipRepository.save(membership);
        User student = getUserOrThrow(studentId);
        student.setClassName(null);
        userRepository.save(student);
    }

    @Override
    @Transactional
    public void transferStudent(Long studentId, TransferStudentRequest request) {
        User student = getUserOrThrow(studentId);
        validateStudent(student);
        SchoolClass target = getActiveClass(request.targetClassId());
        ensureCapacity(target, 1);
        ClassMembership current = membershipRepository
                .findFirstByStudentIdAndSchoolYearAndStatus(studentId, target.getSchoolYear(), ClassMembershipStatus.ACTIVE)
                .orElseThrow(() -> new NotFoundException("Học sinh chưa thuộc lớp nào trong năm học này"));
        if (Objects.equals(current.getClassId(), target.getId())) throw new ApiException("Học sinh đã thuộc lớp đích");
        if (request.effectiveDate().isBefore(current.getJoinedDate())) throw new ApiException("Ngày chuyển lớp không hợp lệ");

        current.setStatus(ClassMembershipStatus.TRANSFERRED);
        current.setLeftDate(request.effectiveDate().minusDays(1));
        current.setReason(request.reason());
        membershipRepository.save(current);

        ClassMembership next = new ClassMembership();
        next.setStudentId(studentId);
        next.setClassId(target.getId());
        next.setSchoolYear(target.getSchoolYear());
        next.setJoinedDate(request.effectiveDate());
        next.setStatus(ClassMembershipStatus.ACTIVE);
        next.setReason(request.reason());
        membershipRepository.save(next);

        student.setClassName(target.getCode());
        userRepository.save(student);
    }

    private SchoolClass getClassOrThrow(Long id) {
        return classRepository.findById(id).orElseThrow(() -> new NotFoundException("Không tìm thấy lớp học"));
    }

    private SchoolClass getActiveClass(Long id) {
        SchoolClass result = getClassOrThrow(id);
        if (result.getStatus() != SchoolClassStatus.ACTIVE) throw new ApiException("Lớp không ở trạng thái hoạt động");
        return result;
    }

    private User getUserOrThrow(Long id) {
        return userRepository.findById(id).orElseThrow(() -> new NotFoundException("Không tìm thấy người dùng"));
    }

    private void validateTeacher(Long id) {
        User user = getUserOrThrow(id);
        boolean teacher = user.getRoles() != null && user.getRoles().stream()
                .anyMatch(role -> role.getName() == RoleName.TEACHER);
        if (!teacher) throw new ApiException("Người dùng được chọn không phải giáo viên");
    }

    private void validateStudent(User user) {
        boolean student = user.getRoles() != null && user.getRoles().stream()
                .anyMatch(role -> role.getName() == RoleName.STUDENT);
        if (!student) throw new ApiException("Người dùng " + user.getId() + " không phải học sinh");
    }

    private void ensureTeacherAvailable(Long teacherId, String year, Long currentClassId) {
        classRepository.findByHomeroomTeacherIdAndSchoolYearAndStatus(teacherId, year, SchoolClassStatus.ACTIVE)
                .filter(found -> !Objects.equals(found.getId(), currentClassId))
                .ifPresent(found -> { throw new ApiException("Giáo viên đã chủ nhiệm lớp " + found.getCode()); });
    }

    private void ensureCapacity(SchoolClass schoolClass, int adding) {
        if (schoolClass.getMaximumStudents() == null) return;
        long current = membershipRepository.countByClassIdAndStatus(schoolClass.getId(), ClassMembershipStatus.ACTIVE);
        if (current + adding > schoolClass.getMaximumStudents()) throw new ApiException("Lớp đã vượt sĩ số tối đa");
    }

    private SchoolClassResponse toResponse(SchoolClass entity) {
        String teacherName = null;
        if (entity.getHomeroomTeacherId() != null) {
            teacherName = userRepository.findById(entity.getHomeroomTeacherId()).map(User::getName).orElse(null);
        }
        long count = membershipRepository.countByClassIdAndStatus(entity.getId(), ClassMembershipStatus.ACTIVE);
        return new SchoolClassResponse(entity.getId(), entity.getCode(), entity.getName(),
                entity.getGradeLevel(), entity.getSchoolYear(), entity.getHomeroomTeacherId(),
                teacherName, count, entity.getMaximumStudents(), entity.getStatus());
    }

    private ClassStudentResponse toStudentResponse(User user, ClassMembership membership) {
        return new ClassStudentResponse(user.getId(), user.getName(), user.getPhoneNumber(), user.getEmail(),
                user.getParentName(), user.getParentPhone(), membership.getJoinedDate(), membership.getStatus());
    }

    private String normalizeCode(String code) { return code.trim().toUpperCase(Locale.ROOT); }

    private void validateSchoolYear(String schoolYear) {
        if (schoolYear == null || schoolYear.isBlank()) {
            throw new ApiException("Năm học không được để trống");
        }
        try {
            String[] parts = schoolYear.split("-");
            if (parts.length != 2) {
                throw new ApiException("Năm học phải có dạng YYYY-YYYY");
            }
            int start = Integer.parseInt(parts[0]);
            int end = Integer.parseInt(parts[1]);
            if (end != start + 1) {
                throw new ApiException("Năm học phải có dạng YYYY-YYYY và năm sau bằng năm trước + 1");
            }
        } catch (NumberFormatException exception) {
            throw new ApiException("Năm học phải có dạng YYYY-YYYY");
        }
    }
}
