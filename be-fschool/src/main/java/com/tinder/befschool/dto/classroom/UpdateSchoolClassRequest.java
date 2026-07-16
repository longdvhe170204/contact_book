package com.tinder.befschool.dto.classroom;

import com.tinder.befschool.entity.SchoolClassStatus;
import jakarta.validation.constraints.*;

public record UpdateSchoolClassRequest(
        @NotBlank @Size(max = 100) String name,
        @NotNull @Min(1) @Max(12) Integer gradeLevel,
        @Min(1) Integer maximumStudents,
        SchoolClassStatus status
) {}
