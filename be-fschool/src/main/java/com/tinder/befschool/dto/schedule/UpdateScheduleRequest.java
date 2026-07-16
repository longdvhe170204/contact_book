package com.tinder.befschool.dto.schedule;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record UpdateScheduleRequest(
        @NotNull Long classId,
        @NotNull Long subjectId,
        @NotNull Long teacherId,
        @NotNull @Min(2) @Max(8) Integer dayOfWeek,
        @NotNull @Min(1) @Max(15) Integer period,
        @NotNull @Min(1) @Max(2) Integer semester,
        @NotBlank @Pattern(regexp = "^\\d{4}-\\d{4}$") String schoolYear,
        String room,
        @Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d$") String startTime,
        @Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d$") String endTime
) {}
