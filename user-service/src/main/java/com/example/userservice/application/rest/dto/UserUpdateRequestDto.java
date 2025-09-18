package com.example.userservice.application.rest.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

/**
 * DTO for handling incoming requests to update an existing user.
 * Fields are optional, allowing clients to send only the data they wish to change.
 */
@Getter
@Setter
@Builder
public class UserUpdateRequestDto {

    private String username;
    private String email;
    private String password; // Optional: for changing the password

}
