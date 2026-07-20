package com.tinder.befschool.dto.schedule;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record UpdateScheduleRequest(
        @NotNull(message = "Vui lòng chọn lớp học")
        Long classId,

        @NotNull(message = "Vui lòng chọn môn học")
        Long subjectId,

        @NotNull(message = "Vui lòng chọn giáo viên")
        Long teacherId,

        @NotNull(message = "Vui lòng chọn ngày học")
        @Min(value = 0, message = "Ngày học không hợp lệ")
        @Max(value = 6, message = "Ngày học không hợp lệ")
        Integer dayOfWeek,

        @NotBlank(message = "Vui lòng chọn tiết học")
        @Pattern(
                regexp = "^(?:[1-9]|10)$",
                message = "Tiết học phải từ 1 đến 10"
        )
        String period,

        @NotBlank(message = "Vui lòng nhập năm học")
        String schoolYear,

        @NotNull(message = "Vui lòng chọn học kỳ")
        @Min(1)
        @Max(2)
        Integer semester,

        String room,

        String startTime,

        String endTime
) {
}
