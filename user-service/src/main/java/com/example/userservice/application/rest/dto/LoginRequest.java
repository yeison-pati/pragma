package com.example.userservice.application.rest.dto;

import lombok.Data;

/**
 * DTO for handling user login requests.
 */
@Data
public class LoginRequest {
    private String username;
    private String password;
}
