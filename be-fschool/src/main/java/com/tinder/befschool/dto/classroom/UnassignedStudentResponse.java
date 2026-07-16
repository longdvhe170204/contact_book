package com.tinder.befschool.dto.classroom;

public record UnassignedStudentResponse(
        Long id,
        String name,
        String phoneNumber,
        String email,
        String parentName,
        String parentPhone
) {}
