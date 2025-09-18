package com.example.orderservice.core.service.impl;

import com.example.orderservice.application.rest.dto.OrderRequestDto;
import com.example.orderservice.application.rest.dto.OrderResponseDto;
import com.example.orderservice.core.domain.document.Order;
import com.example.orderservice.core.domain.repository.OrderRepository;
import com.example.orderservice.core.events.UserEvent;
import com.example.orderservice.core.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.time.LocalDateTime;
import java.util.Objects;

@Service
@Slf4j
@RequiredArgsConstructor
public class OrderServiceImpl implements OrderService {

    private final OrderRepository orderRepository;

    @Override
    public Mono<OrderResponseDto> createOrder(OrderRequestDto requestDto) {
        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> ctx.getAuthentication().getName())
                .flatMap(username -> {
                    Order newOrder = Order.builder()
                            .username(username)
                            .customerName(requestDto.getCustomerName())
                            .productIds(requestDto.getProductIds())
                            .totalAmount(requestDto.getTotalAmount())
                            .orderDate(LocalDateTime.now())
                            .build();
                    return orderRepository.save(newOrder);
                })
                .map(this::toDto);
    }

    @Override
    @Cacheable(value = "orders", key = "#id")
    public Mono<OrderResponseDto> getOrderById(String id) {
        log.info("--- Database Hit: Fetching order with id {} from database. ---", id);
        return orderRepository.findById(id).map(this::toDto);
    }

    @Override
    public Flux<OrderResponseDto> getOrdersByUsername(String username) {
        return orderRepository.findByUsername(username).map(this::toDto);
    }

    @Override
    @CachePut(value = "orders", key = "#id")
    public Mono<OrderResponseDto> updateOrder(String id, OrderRequestDto requestDto) {
        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> ctx.getAuthentication().getName())
                .flatMap(username -> orderRepository.findById(id)
                        .flatMap(order -> {
                            if (!Objects.equals(order.getUsername(), username)) {
                                log.warn("User '{}' attempted to update order '{}' owned by '{}'", username, id, order.getUsername());
                                return Mono.error(new AccessDeniedException("You do not have permission to update this order."));
                            }
                            order.setCustomerName(requestDto.getCustomerName());
                            order.setProductIds(requestDto.getProductIds());
                            order.setTotalAmount(requestDto.getTotalAmount());
                            return orderRepository.save(order);
                        }))
                .map(this::toDto);
    }

    @Override
    @CacheEvict(value = "orders", key = "#id")
    public Mono<Void> deleteOrder(String id) {
        log.info("--- Cache Evict: Removing order with id {} from cache. ---", id);
        return orderRepository.deleteById(id);
    }

    @Override
    public Mono<Void> updateOrderCustomerData(UserEvent userEvent) {
        log.info("Updating customer name to '{}' for all orders of user: {}", userEvent.getUsername(), userEvent.getUsername());
        return orderRepository.findByUsername(userEvent.getUsername())
                .doOnSubscribe(subscription -> log.info("Subscribed to findByUsername stream for user: {}", userEvent.getUsername()))
                .subscribeOn(Schedulers.boundedElastic())
                .doOnNext(order -> log.info("Found order {} to update.", order.getId()))
                .publishOn(Schedulers.parallel())
                .flatMap(order -> {
                    log.info("Processing order {} on thread {}", order.getId(), Thread.currentThread().getName());
                    order.setCustomerName(userEvent.getUsername()); // Assuming the event carries the new customer name as 'username'
                    return orderRepository.save(order)
                            .onErrorResume(e -> {
                                log.error("Failed to save order {}. Continuing with other orders.", order.getId(), e);
                                return Mono.empty();
                            });
                })
                .then()
                .doOnError(e -> log.error("An unexpected error occurred during the update process for user: {}", userEvent.getUsername(), e));
    }

    private OrderResponseDto toDto(Order entity) {
        return OrderResponseDto.builder()
                .id(entity.getId())
                .username(entity.getUsername())
                .customerName(entity.getCustomerName())
                .productIds(entity.getProductIds())
                .totalAmount(entity.getTotalAmount())
                .orderDate(entity.getOrderDate())
                .build();
    }
}
