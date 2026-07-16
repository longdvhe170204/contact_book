package com.tinder.befschool.dto.classroom;

import com.tinder.befschool.entity.ClassMembershipStatus;
import java.time.LocalDate;

public record ClassStudentResponse(
        Long id,
        String name,
        String phoneNumber,
        String email,
        String parentName,
        String parentPhone,
        LocalDate joinedDate,
        ClassMembershipStatus membershipStatus
) {}
