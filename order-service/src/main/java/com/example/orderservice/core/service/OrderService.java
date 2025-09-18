package com.example.orderservice.core.service;

import com.example.orderservice.application.rest.dto.OrderRequestDto;
import com.example.orderservice.application.rest.dto.OrderResponseDto;
import com.example.orderservice.core.events.UserEvent;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * Service layer interface for managing Orders using a reactive paradigm.
 * All methods return reactive publishers (Mono or Flux), ensuring that
 * the execution is non-blocking from the controller down to the database.
 * The service operates on DTOs to decouple the API from the domain model.
 */
public interface OrderService {

    Mono<OrderResponseDto> createOrder(OrderRequestDto requestDto);

    Mono<OrderResponseDto> getOrderById(String id);

    Flux<OrderResponseDto> getOrdersByUsername(String username);

    Mono<OrderResponseDto> updateOrder(String id, OrderRequestDto requestDto);

    Mono<Void> deleteOrder(String id);

    Mono<Void> updateOrderCustomerData(UserEvent userEvent);
}
