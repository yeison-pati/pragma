package com.example.orderservice.application.rest.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;

/**
 * DTO for handling incoming requests to create a new order.
 */
@Getter
@Setter
@Builder
public class OrderRequestDto {

    private String customerName;
    private List<String> productIds;
    private BigDecimal totalAmount;

}
