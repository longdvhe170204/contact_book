package com.tinder.befschool.dto.classroom;

import jakarta.validation.constraints.*;

public record CreateSchoolClassRequest(
        @NotBlank @Pattern(regexp = "^[0-9]{1,2}[A-Za-z0-9]{1,3}$") String code,
        @NotBlank @Size(max = 100) String name,
        @NotNull @Min(1) @Max(12) Integer gradeLevel,
        @NotBlank @Pattern(regexp = "^\\d{4}-\\d{4}$") String schoolYear,
        Long homeroomTeacherId,
        @Min(1) Integer maximumStudents
) {}
