package com.tinder.befschool.service;

import com.tinder.befschool.dto.ImportSummaryResponse;
import com.tinder.befschool.entity.User;

import java.util.List;

public interface DataImportService {
    ImportSummaryResponse importStudents(List<User> students);
}
