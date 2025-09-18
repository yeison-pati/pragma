package com.example.userservice.application.rest.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

/**
 * DTO for representing address information.
 */
@Getter
@Setter
@Builder
public class AddressDto {
    private String street;
    private String city;
    private String state;
    private String zipCode;
}
