package com.tinder.befschool.service.impl;

import com.tinder.befschool.dto.ImportSummaryResponse;
import com.tinder.befschool.entity.Role;
import com.tinder.befschool.entity.RoleName;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.repository.RoleRepository;
import com.tinder.befschool.repository.UserRepository;
import com.tinder.befschool.service.DataImportService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Service
@Transactional
public class DataImportServiceImpl implements DataImportService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    public DataImportServiceImpl(UserRepository userRepository,
                                 RoleRepository roleRepository,
                                 PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public ImportSummaryResponse importStudents(List<User> students) {
        Role studentRole = roleRepository.findByName(RoleName.STUDENT)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy vai trò STUDENT trên hệ thống"));

        int imported = 0;
        int skipped = 0;
        List<String> skippedPhones = new ArrayList<>();

        for (User student : students) {
            String phone = student.getPhoneNumber();
            if (phone == null || phone.isBlank() || phone.length() != 10 || !phone.matches("\\d{10}")) {
                skipped++;
                skippedPhones.add(phone != null ? phone + " (SĐT không hợp lệ)" : "N/A (SĐT trống)");
                continue;
            }

            if (userRepository.existsByPhoneNumber(phone)) {
                skipped++;
                skippedPhones.add(phone + " (Số điện thoại đã tồn tại)");
                continue;
            }

            // Set default settings for student account
            student.setRoles(Collections.singleton(studentRole));
            student.setRoleId(1L); // STUDENT role ID

            String rawPw = student.getPassword();
            if (rawPw == null || rawPw.isBlank()) {
                rawPw = "123456"; // Default password
            }
            student.setPassword(passwordEncoder.encode(rawPw));

            if (student.getParentName() == null || student.getParentName().isBlank()) {
                student.setParentName("Phụ huynh " + student.getName());
            }
            if (student.getParentPhone() == null || student.getParentPhone().isBlank()) {
                student.setParentPhone("0900000000");
            }

            try {
                userRepository.save(student);
                imported++;
            } catch (Exception ex) {
                skipped++;
                skippedPhones.add(phone + " (Lỗi hệ thống khi lưu: " + ex.getMessage() + ")");
            }
        }

        ImportSummaryResponse summary = new ImportSummaryResponse();
        summary.setSuccess(true);
        summary.setImportedCount(imported);
        summary.setSkippedCount(skipped);
        summary.setSkippedPhones(skippedPhones);
        summary.setMessage(String.format("Đã nhập thành công %d học sinh. Bỏ qua %d học sinh.", imported, skipped));

        return summary;
    }
}
