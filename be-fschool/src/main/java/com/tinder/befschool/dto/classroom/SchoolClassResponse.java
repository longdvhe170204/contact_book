package com.tinder.befschool.dto.classroom;

import com.tinder.befschool.entity.SchoolClassStatus;

public record SchoolClassResponse(
        Long id,
        String code,
        String name,
        Integer gradeLevel,
        String schoolYear,
        Long homeroomTeacherId,
        String homeroomTeacherName,
        long studentCount,
        Integer maximumStudents,
        SchoolClassStatus status
) {}
