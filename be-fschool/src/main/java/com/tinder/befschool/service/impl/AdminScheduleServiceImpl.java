package com.tinder.befschool.service.impl;

import com.tinder.befschool.dto.schedule.CreateScheduleRequest;
import com.tinder.befschool.dto.schedule.ScheduleResponse;
import com.tinder.befschool.dto.schedule.SubjectOptionResponse;
import com.tinder.befschool.dto.schedule.UpdateScheduleRequest;
import com.tinder.befschool.entity.RoleName;
import com.tinder.befschool.entity.Schedule;
import com.tinder.befschool.entity.SchoolClass;
import com.tinder.befschool.entity.SchoolClassStatus;
import com.tinder.befschool.entity.Subject;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.exception.ApiException;
import com.tinder.befschool.exception.NotFoundException;
import com.tinder.befschool.repository.ScheduleRepository;
import com.tinder.befschool.repository.SchoolClassRepository;
import com.tinder.befschool.repository.SubjectRepository;
import com.tinder.befschool.repository.UserRepository;
import com.tinder.befschool.service.AdminScheduleService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@Transactional(readOnly = true)
public class AdminScheduleServiceImpl implements AdminScheduleService {

    private record PeriodTime(String startTime, String endTime) {
    }

    /*
     * period dùng String xuyên suốt service để khớp với:
     * - CreateScheduleRequest.period()
     * - UpdateScheduleRequest.period()
     * - Schedule.period
     * - ScheduleRepository
     *
     * Database lưu "1", "2", ..., "10".
     */
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

    private final ScheduleRepository scheduleRepository;
    private final SchoolClassRepository classRepository;
    private final SubjectRepository subjectRepository;
    private final UserRepository userRepository;

    public AdminScheduleServiceImpl(
            ScheduleRepository scheduleRepository,
            SchoolClassRepository classRepository,
            SubjectRepository subjectRepository,
            UserRepository userRepository
    ) {
        this.scheduleRepository = scheduleRepository;
        this.classRepository = classRepository;
        this.subjectRepository = subjectRepository;
        this.userRepository = userRepository;
    }

    @Override
    public List<ScheduleResponse> findAll(
            String schoolYear,
            Integer semester,
            Long classId
    ) {
        List<Schedule> schedules;

        if (schoolYear != null
                && !schoolYear.isBlank()
                && semester != null
                && classId != null) {

            schedules = scheduleRepository
                    .findBySchoolYearAndSemesterAndClassIdOrderByDayOfWeekAscPeriodAsc(
                            schoolYear.trim(),
                            semester,
                            classId
                    );

        } else if (schoolYear != null
                && !schoolYear.isBlank()
                && semester != null) {

            schedules = scheduleRepository
                    .findBySchoolYearAndSemesterOrderByDayOfWeekAscPeriodAsc(
                            schoolYear.trim(),
                            semester
                    );

        } else {
            schedules = scheduleRepository.findAll();
        }

        return schedules.stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    public ScheduleResponse findById(Long id) {
        return toResponse(getSchedule(id));
    }

    @Override
    @Transactional
    public ScheduleResponse create(CreateScheduleRequest request) {
        validateRequiredFields(
                request.classId(),
                request.subjectId(),
                request.teacherId(),
                request.semester()
        );

        String schoolYear =
                validateAndNormalizeSchoolYear(request.schoolYear());

        Integer dayOfWeek =
                validateDayOfWeek(request.dayOfWeek());

        String period =
                validatePeriod(request.period());

        PeriodTime periodTime =
                getPeriodTime(period);

        SchoolClass schoolClass =
                getActiveClass(request.classId());

        Subject subject =
                getSubject(request.subjectId());

        User teacher =
                getTeacher(request.teacherId());

        validateTeacherSubject(teacher, subject);

        String room = normalize(request.room());

        assertNoConflict(
                null,
                schoolClass.getId(),
                teacher.getId(),
                room,
                schoolYear,
                request.semester(),
                dayOfWeek,
                period
        );

        Schedule schedule = new Schedule();

        apply(
                schedule,
                schoolClass,
                subject,
                teacher,
                dayOfWeek,
                period,
                request.semester(),
                schoolYear,
                room,
                periodTime.startTime(),
                periodTime.endTime()
        );

        return toResponse(
                scheduleRepository.save(schedule)
        );
    }

    @Override
    @Transactional
    public ScheduleResponse update(
            Long id,
            UpdateScheduleRequest request
    ) {
        if (id == null) {
            throw new ApiException(
                    "ID thời khóa biểu không được để trống"
            );
        }

        validateRequiredFields(
                request.classId(),
                request.subjectId(),
                request.teacherId(),
                request.semester()
        );

        String schoolYear =
                validateAndNormalizeSchoolYear(request.schoolYear());

        Integer dayOfWeek =
                validateDayOfWeek(request.dayOfWeek());

        String period =
                validatePeriod(request.period());

        PeriodTime periodTime =
                getPeriodTime(period);

        Schedule schedule =
                getSchedule(id);

        SchoolClass schoolClass =
                getActiveClass(request.classId());

        Subject subject =
                getSubject(request.subjectId());

        User teacher =
                getTeacher(request.teacherId());

        validateTeacherSubject(teacher, subject);

        String room = normalize(request.room());

        assertNoConflict(
                id,
                schoolClass.getId(),
                teacher.getId(),
                room,
                schoolYear,
                request.semester(),
                dayOfWeek,
                period
        );

        apply(
                schedule,
                schoolClass,
                subject,
                teacher,
                dayOfWeek,
                period,
                request.semester(),
                schoolYear,
                room,
                periodTime.startTime(),
                periodTime.endTime()
        );

        return toResponse(
                scheduleRepository.save(schedule)
        );
    }

    @Override
    @Transactional
    public void delete(Long id) {
        scheduleRepository.delete(
                getSchedule(id)
        );
    }

    @Override
    public List<SubjectOptionResponse> findSubjects() {
        return subjectRepository.findAll()
                .stream()
                .sorted(
                        (first, second) ->
                                first.getName()
                                        .compareToIgnoreCase(
                                                second.getName()
                                        )
                )
                .map(
                        subject ->
                                new SubjectOptionResponse(
                                        subject.getId(),
                                        subject.getName()
                                )
                )
                .toList();
    }

    @Override
    public List<ScheduleResponse> findTeacherSchedule(
            Long teacherId,
            Integer dayOfWeek
    ) {
        getTeacher(teacherId);

        List<Schedule> schedules;

        if (dayOfWeek == null) {
            schedules = scheduleRepository
                    .findByTeacherIdOrderByDayOfWeekAscPeriodAsc(
                            teacherId
                    );
        } else {
            schedules = scheduleRepository
                    .findByTeacherIdAndDayOfWeekOrderByPeriodAsc(
                            teacherId,
                            validateDayOfWeek(dayOfWeek)
                    );
        }

        return schedules.stream()
                .map(this::toResponse)
                .toList();
    }

    private void apply(
            Schedule schedule,
            SchoolClass schoolClass,
            Subject subject,
            User teacher,
            Integer dayOfWeek,
            String period,
            Integer semester,
            String schoolYear,
            String room,
            String startTime,
            String endTime
    ) {
        schedule.setClassId(schoolClass.getId());
        schedule.setClassName(schoolClass.getCode());

        schedule.setSubjectId(subject.getId());
        schedule.setSubject(subject.getName());

        schedule.setTeacherId(teacher.getId());
        schedule.setTeacher(teacher.getName());

        /*
         * Chuẩn:
         * 0 = Thứ 2
         * 1 = Thứ 3
         * ...
         * 6 = Chủ nhật
         */
        schedule.setDayOfWeek(dayOfWeek);

        /*
         * Không lưu "Tiết 1".
         * Chỉ lưu "1".
         */
        schedule.setPeriod(period);

        schedule.setSemester(semester);
        schedule.setSchoolYear(schoolYear);

        schedule.setRoom(room);
        schedule.setStartTime(startTime);
        schedule.setEndTime(endTime);
    }

    private void assertNoConflict(
            Long currentId,
            Long classId,
            Long teacherId,
            String room,
            String schoolYear,
            Integer semester,
            Integer dayOfWeek,
            String period
    ) {
        boolean classConflict = currentId == null
                ? scheduleRepository
                .existsByClassIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
                        classId,
                        schoolYear,
                        semester,
                        dayOfWeek,
                        period
                )
                : scheduleRepository
                .existsByClassIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
                        classId,
                        schoolYear,
                        semester,
                        dayOfWeek,
                        period,
                        currentId
                );

        if (classConflict) {
            throw new ApiException(
                    "Lớp đã có môn học ở ngày và tiết này"
            );
        }

        boolean teacherConflict = currentId == null
                ? scheduleRepository
                .existsByTeacherIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
                        teacherId,
                        schoolYear,
                        semester,
                        dayOfWeek,
                        period
                )
                : scheduleRepository
                .existsByTeacherIdAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
                        teacherId,
                        schoolYear,
                        semester,
                        dayOfWeek,
                        period,
                        currentId
                );

        if (teacherConflict) {
            throw new ApiException(
                    "Giáo viên đã có lịch dạy ở ngày và tiết này"
            );
        }

        if (room == null) {
            return;
        }

        boolean roomConflict = currentId == null
                ? scheduleRepository
                .existsByRoomIgnoreCaseAndSchoolYearAndSemesterAndDayOfWeekAndPeriod(
                        room,
                        schoolYear,
                        semester,
                        dayOfWeek,
                        period
                )
                : scheduleRepository
                .existsByRoomIgnoreCaseAndSchoolYearAndSemesterAndDayOfWeekAndPeriodAndIdNot(
                        room,
                        schoolYear,
                        semester,
                        dayOfWeek,
                        period,
                        currentId
                );

        if (roomConflict) {
            throw new ApiException(
                    "Phòng học đã được sử dụng ở ngày và tiết này"
            );
        }
    }

    private void validateRequiredFields(
            Long classId,
            Long subjectId,
            Long teacherId,
            Integer semester
    ) {
        if (classId == null) {
            throw new ApiException(
                    "Vui lòng chọn lớp học"
            );
        }

        if (subjectId == null) {
            throw new ApiException(
                    "Vui lòng chọn môn học"
            );
        }

        if (teacherId == null) {
            throw new ApiException(
                    "Vui lòng chọn giáo viên"
            );
        }

        if (semester == null) {
            throw new ApiException(
                    "Vui lòng chọn học kỳ"
            );
        }

        if (semester < 1 || semester > 2) {
            throw new ApiException(
                    "Học kỳ phải là 1 hoặc 2"
            );
        }
    }

    private Integer validateDayOfWeek(
            Integer dayOfWeek
    ) {
        if (dayOfWeek == null) {
            throw new ApiException(
                    "Vui lòng chọn ngày học"
            );
        }

        if (dayOfWeek < 0 || dayOfWeek > 6) {
            throw new ApiException(
                    "Ngày học không hợp lệ, giá trị phải từ 0 đến 6"
            );
        }

        return dayOfWeek;
    }

    private String validatePeriod(
            String period
    ) {
        if (period == null || period.isBlank()) {
            throw new ApiException(
                    "Vui lòng chọn tiết học"
            );
        }

        String normalized = period.trim();

        int periodNumber;

        try {
            periodNumber = Integer.parseInt(normalized);
        } catch (NumberFormatException exception) {
            throw new ApiException(
                    "Tiết học không hợp lệ"
            );
        }

        if (periodNumber < 1 || periodNumber > 10) {
            throw new ApiException(
                    "Tiết học phải từ tiết 1 đến tiết 10"
            );
        }

        /*
         * Chuẩn hóa "01" thành "1".
         */
        return String.valueOf(periodNumber);
    }

    private PeriodTime getPeriodTime(
            String period
    ) {
        PeriodTime periodTime =
                PERIOD_TIMES.get(period);

        if (periodTime == null) {
            throw new ApiException(
                    "Không tìm thấy thời gian tương ứng với tiết học"
            );
        }

        return periodTime;
    }

    private SchoolClass getActiveClass(Long id) {
        if (id == null) {
            throw new ApiException(
                    "Vui lòng chọn lớp học"
            );
        }

        SchoolClass schoolClass =
                classRepository.findById(id)
                        .orElseThrow(
                                () ->
                                        new NotFoundException(
                                                "Không tìm thấy lớp học"
                                        )
                        );

        if (schoolClass.getStatus()
                != SchoolClassStatus.ACTIVE) {
            throw new ApiException(
                    "Chỉ được xếp lịch cho lớp đang hoạt động"
            );
        }

        return schoolClass;
    }

    private Subject getSubject(Long id) {
        if (id == null) {
            throw new ApiException(
                    "Vui lòng chọn môn học"
            );
        }

        return subjectRepository.findById(id)
                .orElseThrow(
                        () ->
                                new NotFoundException(
                                        "Không tìm thấy môn học"
                                )
                );
    }

    private User getTeacher(Long id) {
        if (id == null) {
            throw new ApiException(
                    "Vui lòng chọn giáo viên"
            );
        }

        return userRepository
                .findByIdAndRoles_Name(
                        id,
                        RoleName.TEACHER
                )
                .orElseThrow(
                        () ->
                                new NotFoundException(
                                        "Không tìm thấy giáo viên"
                                )
                );
    }

    private Schedule getSchedule(Long id) {
        if (id == null) {
            throw new ApiException(
                    "ID thời khóa biểu không được để trống"
            );
        }

        return scheduleRepository.findById(id)
                .orElseThrow(
                        () ->
                                new NotFoundException(
                                        "Không tìm thấy tiết học"
                                )
                );
    }

    private void validateTeacherSubject(
            User teacher,
            Subject subject
    ) {
        String teacherSubject =
                normalize(teacher.getSubject());

        if (teacherSubject != null
                && !teacherSubject.equalsIgnoreCase(
                subject.getName()
        )) {
            throw new ApiException(
                    "Giáo viên "
                            + teacher.getName()
                            + " không phụ trách môn "
                            + subject.getName()
            );
        }
    }

    private String validateAndNormalizeSchoolYear(
            String schoolYear
    ) {
        String normalized =
                normalize(schoolYear);

        if (normalized == null) {
            throw new ApiException(
                    "Vui lòng nhập năm học"
            );
        }

        try {
            String[] parts =
                    normalized.split("-");

            if (parts.length != 2) {
                throw new ApiException(
                        "Năm học phải có dạng YYYY-YYYY"
                );
            }

            int startYear =
                    Integer.parseInt(parts[0]);

            int endYear =
                    Integer.parseInt(parts[1]);

            if (endYear != startYear + 1) {
                throw new ApiException(
                        "Năm học phải có dạng YYYY-YYYY và hai năm liên tiếp"
                );
            }

            return startYear + "-" + endYear;

        } catch (NumberFormatException exception) {
            throw new ApiException(
                    "Năm học không hợp lệ"
            );
        }
    }

    private String normalize(String value) {
        if (value == null) {
            return null;
        }

        String trimmed =
                value.trim();

        return trimmed.isEmpty()
                ? null
                : trimmed;
    }

    private ScheduleResponse toResponse(
            Schedule schedule
    ) {
        return new ScheduleResponse(
                schedule.getId(),
                schedule.getClassId(),
                schedule.getClassName(),
                schedule.getClassName(),
                schedule.getSubjectId(),
                schedule.getSubject(),
                schedule.getTeacherId(),
                schedule.getTeacher(),
                schedule.getDayOfWeek(),
                schedule.getPeriod(),
                schedule.getSemester(),
                schedule.getSchoolYear(),
                schedule.getRoom(),
                schedule.getStartTime(),
                schedule.getEndTime()
        );
    }
}