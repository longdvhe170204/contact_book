package com.tinder.befschool.dto.classroom;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.List;

public record AddStudentsToClassRequest(
        @NotEmpty List<Long> studentIds,
        @NotNull LocalDate joinedDate
) {}
