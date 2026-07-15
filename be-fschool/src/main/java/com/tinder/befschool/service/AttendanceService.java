package com.tinder.befschool.service;

import com.tinder.befschool.dto.AttendanceRequest;
import com.tinder.befschool.entity.Attendance;

import java.time.LocalDate;
import java.util.List;

public interface AttendanceService {

    List<Attendance> saveAttendance(Long teacherId, AttendanceRequest request);

    List<Attendance> getStudentAttendance(Long studentId);

    List<Attendance> getClassAttendance(String className, LocalDate date);
}
