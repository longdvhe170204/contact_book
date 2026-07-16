package com.tinder.befschool.dto.classroom;

import jakarta.validation.constraints.NotNull;

public record AssignHomeroomTeacherRequest(@NotNull Long teacherId) {}
