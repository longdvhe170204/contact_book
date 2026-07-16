package com.tinder.befschool.dto.schedule;

public record ScheduleResponse(
        Long id,
        Long classId,
        String classCode,
        String className,
        Long subjectId,
        String subjectName,
        Long teacherId,
        String teacherName,
        Integer dayOfWeek,
        Integer period,
        Integer semester,
        String schoolYear,
        String room,
        String startTime,
        String endTime
) {}
