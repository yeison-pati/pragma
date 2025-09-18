package com.example.userservice.application.rest.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

/**
 * DTO for returning a JWT access token upon successful login.
 */
@Getter
@AllArgsConstructor
@Builder
public class AuthenticationResponse {
    private final String token;
    private final String tokenType = "Bearer";
    private final UserResponseDto user;
}
