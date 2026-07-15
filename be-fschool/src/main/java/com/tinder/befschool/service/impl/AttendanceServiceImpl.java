package com.tinder.befschool.service.impl;

import com.tinder.befschool.dto.AttendanceRequest;
import com.tinder.befschool.entity.Attendance;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.exception.ApiException;
import com.tinder.befschool.repository.AttendanceRepository;
import com.tinder.befschool.service.AttendanceService;
import com.tinder.befschool.service.UserService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@Transactional
public class AttendanceServiceImpl implements AttendanceService {

    private final AttendanceRepository attendanceRepository;
    private final UserService userService;

    public AttendanceServiceImpl(AttendanceRepository attendanceRepository,
                                 UserService userService) {
        this.attendanceRepository = attendanceRepository;
        this.userService = userService;
    }

    @Override
    public List<Attendance> saveAttendance(Long teacherId, AttendanceRequest request) {
        User teacher = userService.findTeacherById(teacherId);
        if (request.getRecords() == null || request.getRecords().isEmpty()) {
            throw new ApiException("Attendance records cannot be empty");
        }

        List<Attendance> result = new ArrayList<>();
        for (AttendanceRequest.AttendanceRecord record : request.getRecords()) {
            // Upsert: nếu đã có bản ghi trong ngày thì cập nhật, chưa có thì tạo mới
            Attendance existing = attendanceRepository
                    .findByStudentIdAndDateAndClassNameAndSubject(record.getStudentId(), request.getDate(), request.getClassName(), request.getSubject())
                    .stream().findFirst().orElse(null);

            Attendance attendance = existing != null ? existing : new Attendance();
            attendance.setStudentId(record.getStudentId());
            attendance.setTeacherId(teacher.getId());
            attendance.setClassName(request.getClassName());
            attendance.setSubject(request.getSubject());
            attendance.setDate(request.getDate());
            attendance.setStatus(record.getStatus());
            attendance.setNote(record.getNote());
            result.add(attendanceRepository.save(attendance));
        }
        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Attendance> getStudentAttendance(Long studentId) {
        userService.findStudentById(studentId);
        return attendanceRepository.findByStudentIdOrderByDateDesc(studentId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Attendance> getClassAttendance(String className, LocalDate date) {
        return attendanceRepository.findByClassNameAndDateOrderByStudentId(className, date);
    }
}
