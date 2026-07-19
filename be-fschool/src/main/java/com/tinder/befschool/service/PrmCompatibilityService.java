package com.tinder.befschool.service;

import com.tinder.befschool.dto.schedule.LegacyScheduleResponse;
import com.tinder.befschool.entity.User;

import java.util.List;

public interface PrmCompatibilityService {
    List<String> findTeacherClasses(Long authenticatedUserId, Long requestedTeacherId);
    List<User> findTeacherStudents(Long authenticatedUserId, Long requestedTeacherId, String className);
    List<LegacyScheduleResponse> findTeacherSchedules(Long authenticatedUserId, Long requestedTeacherId);
    List<LegacyScheduleResponse> findClassSchedules(String className);
    List<LegacyScheduleResponse> findClassSchedulesByPrmDay(String className, Integer prmDayOfWeek);
}
