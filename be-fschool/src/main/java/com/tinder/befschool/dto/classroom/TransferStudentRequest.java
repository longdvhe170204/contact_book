package com.tinder.befschool.dto.classroom;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record TransferStudentRequest(
        @NotNull Long targetClassId,
        @NotNull LocalDate effectiveDate,
        String reason
) {}
