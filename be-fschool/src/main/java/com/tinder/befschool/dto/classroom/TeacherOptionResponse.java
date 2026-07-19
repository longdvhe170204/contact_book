package com.tinder.befschool.dto.classroom;

public record TeacherOptionResponse(
        Long id,
        String name,
        String phoneNumber,
        String employeeCode,
        String subject
) {}
