package com.example.userservice.application.rest.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

/**
 * DTO for returning user information in API responses.
 * This object is used to control what information is sent to the client,
 * for example, by omitting sensitive data like passwords.
 */
@Getter
@Setter
@Builder
public class UserResponseDto {

    private Long id;
    private String username;
    private String email;
    private AddressDto address;

}
