package com.tinder.befschool.service.impl;

import com.tinder.befschool.dto.schedule.LegacyScheduleResponse;
import com.tinder.befschool.entity.*;
import com.tinder.befschool.exception.ApiException;
import com.tinder.befschool.exception.NotFoundException;
import com.tinder.befschool.repository.*;
import com.tinder.befschool.service.PrmCompatibilityService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class PrmCompatibilityServiceImpl implements PrmCompatibilityService {
    private final UserRepository userRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final ClassMembershipRepository membershipRepository;
    private final ScheduleRepository scheduleRepository;

    public PrmCompatibilityServiceImpl(UserRepository userRepository,
                                       SchoolClassRepository schoolClassRepository,
                                       ClassMembershipRepository membershipRepository,
                                       ScheduleRepository scheduleRepository) {
        this.userRepository = userRepository;
        this.schoolClassRepository = schoolClassRepository;
        this.membershipRepository = membershipRepository;
        this.scheduleRepository = scheduleRepository;
    }

    @Override
    public List<String> findTeacherClasses(Long authenticatedUserId, Long requestedTeacherId) {
        assertSelf(authenticatedUserId, requestedTeacherId);
        getTeacher(requestedTeacherId);

        Set<String> classNames = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        classNames.addAll(scheduleRepository.findDistinctClassNamesByTeacherId(requestedTeacherId));
        schoolClassRepository.findAllByOrderBySchoolYearDescGradeLevelAscCodeAsc().stream()
                .filter(c -> c.getStatus() == SchoolClassStatus.ACTIVE)
                .filter(c -> Objects.equals(c.getHomeroomTeacherId(), requestedTeacherId))
                .map(SchoolClass::getCode)
                .forEach(classNames::add);

        return List.copyOf(classNames);
    }

    @Override
    public List<User> findTeacherStudents(Long authenticatedUserId, Long requestedTeacherId, String className) {
        assertSelf(authenticatedUserId, requestedTeacherId);
        getTeacher(requestedTeacherId);

        List<String> allowedClasses = findTeacherClasses(authenticatedUserId, requestedTeacherId);
        if (className != null && !className.isBlank()) {
            boolean allowed = allowedClasses.stream().anyMatch(c -> c.equalsIgnoreCase(className.trim()));
            if (!allowed) {
                throw new ApiException("Giáo viên không được phân quyền với lớp " + className);
            }
            return userRepository.findByRoles_NameAndClassNameAndIsActiveTrueOrderByNameAsc(RoleName.STUDENT, className.trim());
        }

        if (allowedClasses.isEmpty()) {
            return List.of();
        }
        return userRepository.findByRoles_NameAndClassNameInOrderByClassNameAscNameAsc(
                RoleName.STUDENT, allowedClasses);
    }

    @Override
    public List<LegacyScheduleResponse> findTeacherSchedules(Long authenticatedUserId, Long requestedTeacherId) {
        assertSelf(authenticatedUserId, requestedTeacherId);
        getTeacher(requestedTeacherId);
        return scheduleRepository.findByTeacherIdOrderByDayOfWeekAscPeriodAsc(requestedTeacherId)
                .stream().map(this::toLegacy).toList();
    }

    @Override
    public List<LegacyScheduleResponse> findClassSchedules(String className) {
        requireClassName(className);
        return scheduleRepository.findByClassNameOrderByDayOfWeekAscPeriodAsc(className.trim())
                .stream().map(this::toLegacy).toList();
    }

    @Override
    public List<LegacyScheduleResponse> findClassSchedulesByPrmDay(String className, Integer prmDayOfWeek) {
        requireClassName(className);
        int storedDay = toStoredDay(prmDayOfWeek);
        return scheduleRepository.findByClassNameAndDayOfWeekOrderByPeriodAsc(className.trim(), storedDay)
                .stream().map(this::toLegacy).toList();
    }

    private User getTeacher(Long teacherId) {
        return userRepository.findByIdAndRoles_Name(teacherId, RoleName.TEACHER)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy giáo viên"));
    }

    private void assertSelf(Long authenticatedUserId, Long requestedTeacherId) {
        if (authenticatedUserId == null || !Objects.equals(authenticatedUserId, requestedTeacherId)) {
            throw new ApiException("Không được truy cập dữ liệu của giáo viên khác");
        }
    }

    private void requireClassName(String className) {
        if (className == null || className.isBlank()) {
            throw new ApiException("Tên lớp không được để trống");
        }
    }

    private int toStoredDay(Integer prmDay) {
        if (prmDay == null || prmDay < 0 || prmDay > 6) {
            throw new ApiException("Ngày trong tuần của PRM phải nằm trong khoảng 0..6");
        }
        return prmDay;
    }

    private int toPrmDay(Integer storedDay) {
        if (storedDay == null) return 0;
        if (storedDay >= 2 && storedDay <= 8) return storedDay;
        // Backward compatibility for legacy rows already stored as 0..6.
        if (storedDay >= 0 && storedDay <= 6) return storedDay;
        return 0;
    }

    private LegacyScheduleResponse toLegacy(Schedule row) {
        return new LegacyScheduleResponse(
                row.getId(), row.getClassName(), toPrmDay(row.getDayOfWeek()), row.getPeriod(),
                row.getSubject(), row.getTeacher(), row.getTeacherId(), row.getRoom(),
                row.getStartTime(), row.getEndTime());
    }
}
