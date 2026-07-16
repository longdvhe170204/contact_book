package com.tinder.befschool.service.impl;

import com.tinder.befschool.dto.schedule.CreateScheduleRequest;
import com.tinder.befschool.dto.schedule.ScheduleResponse;
import com.tinder.befschool.dto.schedule.SubjectOptionResponse;
import com.tinder.befschool.dto.schedule.UpdateScheduleRequest;
import com.tinder.befschool.entity.*;
import com.tinder.befschool.exception.ApiException;
import com.tinder.befschool.exception.NotFoundException;
import com.tinder.befschool.repository.*;
import com.tinder.befschool.service.AdminScheduleService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class AdminScheduleServiceImpl implements AdminScheduleService {
    private final ScheduleRepository scheduleRepository;
    private final SchoolClassRepository classRepository;
    private final SubjectRepository subjectRepository;
    private final UserRepository userRepository;

    public AdminScheduleServiceImpl(ScheduleRepository scheduleRepository,
                                    SchoolClassRepository classRepository,
                                    SubjectRepository subjectRepository,
                                    UserRepository userRepository) {
        this.scheduleRepository = scheduleRepository;
        this.classRepository = classRepository;
        this.subjectRepository = subjectRepository;
        this.userRepository = userRepository;
    }

    @Override
    public List<ScheduleResponse> findAll(String schoolYear, Integer semester, Long classId) {
        List<Schedule> rows;
        if (schoolYear != null && semester != null && classId != null) {
            rows = scheduleRepository.findBySchoolYearAndSemesterAndClassIdOrderByDayOfWeekAscPeriodAsc(
                    schoolYear, semester, classId);
        } else if (schoolYear != null && semester != null) {
            rows = scheduleRepository.findBySchoolYearAndSemesterOrderByDayOfWeekAscPeriodAsc(schoolYear, semester);
        } else {
            rows = scheduleRepository.findAll();
        }
        return rows.stream().map(this::toResponse).toList();
    }

    @Override
    public ScheduleResponse findById(Long id) {
        return toResponse(getSchedule(id));
    }

    @Override
    @Transactional
    public ScheduleResponse create(CreateScheduleRequest request) {
        validateSchoolYear(request.schoolYear());
        SchoolClass schoolClass = getActiveClass(request.classId());
        Subject subject = getSubject(request.subjectId());
        User teacher = getTeacher(request.teacherId());
        validateTeacherSubject(teacher, subject);
        validateTimes(request.startTime(), request.endTime());
        assertNoConflict(null, request.classId(), request.teacherId(), request.room(), request.schoolYear(),
                request.semester(), request.dayOfWeek(), request.period());

        Schedule schedule = new Schedule();
        apply(schedule, schoolClass, subject, teacher, request.dayOfWeek(), request.period(), request.semester(),
                request.schoolYear(), request.room(), request.startTime(), request.endTime());
        return toResponse(scheduleRepository.save(schedule));
    }

    @Override
    @Transactional
    public ScheduleResponse update(Long id, UpdateScheduleRequest request) {
        validateSchoolYear(request.schoolYear());
        Schedule schedule = getSchedule(id);
        SchoolClass schoolClass = getActiveClass(request.classId());
        Subject subject = getSubject(request.subjectId());
        User teacher = getTeacher(request.teacherId());
        validateTeacherSubject(teacher, subject);
        validateTimes(request.startTime(), request.endTime());
        assertNoConflict(id, request.classId(), request.teacherId(), request.room(), request.schoolYear(),
                request.semester(), request.dayOfWeek(), request.period());

        apply(schedule, schoolClass, subject, teacher, request.dayOfWeek(), request.period(), request.semester(),
                request.schoolYear(), request.room(), request.startTime(), request.endTime());
        return toResponse(scheduleRepository.save(schedule));
    }

    @Override
    @Transactional
    public void delete(Long id) {
        scheduleRepository.delete(getSchedule(id));
    }

    @Override
    public List<SubjectOptionResponse> findSubjects() {
        return subjectRepository.findAll().stream()
                .sorted((a, b) -> a.getName().compareToIgnoreCase(b.getName()))
                .map(s -> new SubjectOptionResponse(s.getId(), s.getName()))
                .toList();
    }

    @Override
    public List<ScheduleResponse> findTeacherSchedule(Long teacherId, Integer dayOfWeek) {
        getTeacher(teacherId);
        List<Schedule> rows = dayOfWeek == null
                ? scheduleRepository.findByTeacherIdOrderByDayOfWeekAscPeriodAsc(teacherId)
                : scheduleRepository.findByTeacherIdAndDayOfWeekOrderByPeriodAsc(teacherId, dayOfWeek);
        return rows.stream().map(this::toResponse).toList();
    }

    private void apply(Schedule schedule, SchoolClass schoolClass, Subject subject, User teacher,
                       Integer dayOfWeek, Integer period, Integer semester, String schoolYear,
                       String room, String startTime, String endTime) {
        schedule.setClassId(schoolClass.getId());
        schedule.setClassName(schoolClass.getCode());
        schedule.setSubjectId(subject.getId());
        schedule.setSubject(subject.getName());
        schedule.setTeacherId(teacher.getId());
        schedule.setTeacher(teacher.getName());
        schedule.setDayOfWeek(dayOfWeek);
        schedule.setPeriod(String.valueOf(period));
        schedule.setSemester(semester);
        schedule.setSchoolYear(schoolYear);
        schedule.setRoom(normalize(room));
        schedule.setStartTime(normalize(startTime));
        schedule.setEndTime(normalize(endTime));
    }

    private void assertNoConflict(Long currentId, Long classId, Long teacherId, String room,
                                  String schoolYear, Integer semester, Integer dayOfWeek, Integer period) {
        String periodValue = String.valueOf(period);
        boolean classConflict = currentId == null
                ? scheduleRepository.existsByClassIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
                    classId, schoolYear, semester, dayOfWeek, periodValue)
                : scheduleRepository.existsByClassIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
                    classId, schoolYear, semester, dayOfWeek, periodValue, currentId);
        if (classConflict) throw new ApiException("Lớp đã có môn học ở thứ và tiết này");

        boolean teacherConflict = currentId == null
                ? scheduleRepository.existsByTeacherIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
                    teacherId, schoolYear, semester, dayOfWeek, periodValue)
                : scheduleRepository.existsByTeacherIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
                    teacherId, schoolYear, semester, dayOfWeek, periodValue, currentId);
        if (teacherConflict) throw new ApiException("Giáo viên đã có lịch dạy ở thứ và tiết này");

        String normalizedRoom = normalize(room);
        if (normalizedRoom != null) {
            boolean roomConflict = currentId == null
                    ? scheduleRepository.existsByRoomIgnoreCaseAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
                        normalizedRoom, schoolYear, semester, dayOfWeek, periodValue)
                    : scheduleRepository.existsByRoomIgnoreCaseAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
                        normalizedRoom, schoolYear, semester, dayOfWeek, periodValue, currentId);
            if (roomConflict) throw new ApiException("Phòng học đã được sử dụng ở thứ và tiết này");
        }
    }

    private SchoolClass getActiveClass(Long id) {
        SchoolClass schoolClass = classRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy lớp học"));
        if (schoolClass.getStatus() != SchoolClassStatus.ACTIVE) {
            throw new ApiException("Chỉ được xếp lịch cho lớp đang hoạt động");
        }
        return schoolClass;
    }

    private Subject getSubject(Long id) {
        return subjectRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy môn học"));
    }

    private User getTeacher(Long id) {
        return userRepository.findByIdAndRoles_Name(id, RoleName.TEACHER)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy giáo viên"));
    }

    private Schedule getSchedule(Long id) {
        return scheduleRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy tiết học"));
    }

    private void validateTeacherSubject(User teacher, Subject subject) {
        if (teacher.getSubject() != null && !teacher.getSubject().isBlank()
                && !teacher.getSubject().equalsIgnoreCase(subject.getName())) {
            throw new ApiException("Giáo viên " + teacher.getName() + " không phụ trách môn " + subject.getName());
        }
    }

    private void validateSchoolYear(String schoolYear) {
        try {
            String[] parts = schoolYear.split("-");
            if (parts.length != 2 || Integer.parseInt(parts[1]) != Integer.parseInt(parts[0]) + 1) {
                throw new ApiException("Năm học phải có dạng YYYY-YYYY và hai năm liên tiếp");
            }
        } catch (NumberFormatException ex) {
            throw new ApiException("Năm học không hợp lệ");
        }
    }

    private void validateTimes(String startTime, String endTime) {
        if (startTime != null && endTime != null && !startTime.isBlank() && !endTime.isBlank()
                && startTime.compareTo(endTime) >= 0) {
            throw new ApiException("Giờ bắt đầu phải trước giờ kết thúc");
        }
    }

    private String normalize(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private ScheduleResponse toResponse(Schedule s) {
        Integer period = null;
        try { period = s.getPeriod() == null ? null : Integer.valueOf(s.getPeriod()); } catch (NumberFormatException ignored) {}
        return new ScheduleResponse(s.getId(), s.getClassId(), s.getClassName(), s.getClassName(),
                s.getSubjectId(), s.getSubject(), s.getTeacherId(), s.getTeacher(), s.getDayOfWeek(), period,
                s.getSemester(), s.getSchoolYear(), s.getRoom(), s.getStartTime(), s.getEndTime());
    }
}
