package com.chat.controller;

import com.chat.config.UserPrincipal;
import com.chat.dto.auth.UserDto;
import com.chat.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public ResponseEntity<List<UserDto>> searchUsers(
        @RequestParam(required = false) String query,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        List<UserDto> users = userService.searchUsers(query, principal.getId());
        return ResponseEntity.ok(users);
    }
}
