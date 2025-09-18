package com.example.userservice.application.rest.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

/**
 * DTO for handling incoming requests to create a new user.
 * Using a DTO for input decouples the API from the internal domain model
 * and allows for tailored validation and data handling.
 */
@Getter
@Setter
@Builder
public class RegisterUserRequest {

    private String username;
    private String email;
    private String password;
    private AddressDto address;

}
