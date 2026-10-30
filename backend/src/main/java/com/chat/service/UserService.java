package com.chat.service;

import com.chat.domain.User;
import com.chat.dto.auth.UserDto;
import com.chat.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<UserDto> searchUsers(String query, UUID currentUserId) {
        List<User> users;
        if (query == null || query.trim().isEmpty()) {
            users = userRepository.findAll();
        } else {
            String q = query.trim();
            users = userRepository.findByUsernameContainingIgnoreCaseOrDisplayNameContainingIgnoreCase(q, q);
        }

        return users.stream()
            .filter(u -> !u.getId().equals(currentUserId))
            .map(UserDto::fromEntity)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UserDto getUserById(UUID userId) {
        return userRepository.findById(userId)
            .map(UserDto::fromEntity)
            .orElse(null);
    }
}
