package com.example.orderservice.application.rest.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO for returning order information in API responses.
 */
@Getter
@Setter
@Builder
public class OrderResponseDto {

    private String id;
    private String username;
    private String customerName;
    private List<String> productIds;
    private BigDecimal totalAmount;
    private LocalDateTime orderDate;

}
