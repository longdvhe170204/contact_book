package com.tinder.befschool.dto.schedule;


public record LegacyScheduleResponse(
        Long id,
        String className,
        Integer dayOfWeek,
        String period,
        String subject,
        String teacher,
        Long teacherId,
        String room,
        String startTime,
        String endTime
) {}
