package com.tinder.befschool.dto.schedule;

/**
 * Response contract kept compatible with the existing PRM Schedule model.
 * dayOfWeek is returned as 0..6 (Monday..Sunday), while the admin domain stores 2..8.
 */
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
