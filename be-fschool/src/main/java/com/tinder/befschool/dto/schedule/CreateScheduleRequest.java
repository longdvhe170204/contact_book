package com.tinder.befschool.dto.schedule;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record CreateScheduleRequest(

        @NotNull(message = "Vui lòng chọn lớp học")
        Long classId,

        @NotNull(message = "Vui lòng chọn môn học")
        Long subjectId,

        @NotNull(message = "Vui lòng chọn giáo viên")
        Long teacherId,

        @NotNull(message = "Vui lòng chọn ngày học")
        @Min(
                value = 0,
                message = "Ngày học phải từ Thứ 2 đến Chủ nhật"
        )
        @Max(
                value = 6,
                message = "Ngày học phải từ Thứ 2 đến Chủ nhật"
        )
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
        @Min(value = 1, message = "Học kỳ phải là 1 hoặc 2")
        @Max(value = 2, message = "Học kỳ phải là 1 hoặc 2")
        Integer semester,

        String room,

        String startTime,

        String endTime
) {
}
