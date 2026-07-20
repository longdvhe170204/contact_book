package com.tinder.befschool.security;

import com.tinder.befschool.entity.User;
import com.tinder.befschool.repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {
    private final UserRepository userRepository;

    public UserDetailsServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String phoneNumber) throws UsernameNotFoundException {
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UsernameNotFoundException("User Not Found with phone: " + phoneNumber));

        if (user.getIsActive() != null && !user.getIsActive()) {
            throw new RuntimeException("Tài khoản của bạn đã bị vô hiệu hóa");
        }

        System.out.println("Loaded user: " + user.getPhoneNumber() + " with password: " + user.getPassword());
        return UserDetailsImpl.build(user);
    }
}
