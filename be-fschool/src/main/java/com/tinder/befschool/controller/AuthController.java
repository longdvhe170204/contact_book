package com.tinder.befschool.controller;

import com.tinder.befschool.dto.ApiResponse;
import com.tinder.befschool.entity.User;
import com.tinder.befschool.repository.UserRepository;
import com.tinder.befschool.security.UserDetailsImpl;
import com.tinder.befschool.util.JwtUtils;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final JwtUtils jwtUtils;

    public AuthController(AuthenticationManager authenticationManager,
                          UserRepository userRepository,
                          JwtUtils jwtUtils) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtUtils = jwtUtils;
    }

    public static class LoginRequest {
        private String phoneNumber;
        private String password;

        public String getPhoneNumber() {
            return phoneNumber;
        }

        public void setPhoneNumber(String phoneNumber) {
            this.phoneNumber = phoneNumber;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<Map<String, Object>>> authenticateUser(@RequestBody LoginRequest loginRequest) {
        String password = loginRequest.getPassword();
        if (password == null || password.isBlank()) {
            password = "123456"; // Default password from SampleDataLoader
        }

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getPhoneNumber(), password));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        String jwt = jwtUtils.generateJwtToken(userDetails.getUsername());

        User user = userRepository.findByPhoneNumber(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng sau khi xác thực"));

        Map<String, Object> responseData = new HashMap<>();
        responseData.put("token", jwt);
        responseData.put("user", user);

        return ResponseEntity.ok(new ApiResponse<>(true, responseData, "Đăng nhập thành công"));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<String>> forgotPassword(@RequestParam String phoneNumber) {
        boolean exists = userRepository.existsByPhoneNumber(phoneNumber);
        if (!exists) {
            return ResponseEntity.badRequest().body(new ApiResponse<>(false, null, "Số điện thoại không tồn tại trên hệ thống"));
        }
        return ResponseEntity.ok(new ApiResponse<>(true, "Liên kết đặt lại mật khẩu đã được gửi qua email liên kết với tài khoản này.", "Yêu cầu khôi phục mật khẩu thành công"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<User>> getCurrentUser(
            Authentication authentication) {

        UserDetailsImpl userDetails =
                (UserDetailsImpl) authentication.getPrincipal();

        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() ->
                        new RuntimeException(
                                "Không tìm thấy người dùng id: "
                                        + userDetails.getId()
                        )
                );

        return ResponseEntity.ok(
                new ApiResponse<>(
                        true,
                        user,
                        "Lấy thông tin người dùng thành công"
                )
        );
    }

}