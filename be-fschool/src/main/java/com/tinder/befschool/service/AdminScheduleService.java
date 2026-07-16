package com.tinder.befschool.service;

import com.tinder.befschool.dto.schedule.CreateScheduleRequest;
import com.tinder.befschool.dto.schedule.ScheduleResponse;
import com.tinder.befschool.dto.schedule.SubjectOptionResponse;
import com.tinder.befschool.dto.schedule.UpdateScheduleRequest;

import java.util.List;

public interface AdminScheduleService {
    List<ScheduleResponse> findAll(String schoolYear, Integer semester, Long classId);
    ScheduleResponse findById(Long id);
    ScheduleResponse create(CreateScheduleRequest request);
    ScheduleResponse update(Long id, UpdateScheduleRequest request);
    void delete(Long id);
    List<SubjectOptionResponse> findSubjects();
    List<ScheduleResponse> findTeacherSchedule(Long teacherId, Integer dayOfWeek);
}
