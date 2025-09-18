package com.example.orderservice.application.rest;

import com.example.orderservice.application.rest.dto.OrderRequestDto;
import com.example.orderservice.application.rest.dto.OrderResponseDto;
import com.example.orderservice.core.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    /**
     * Endpoint to create a new order.
     * The entire operation is reactive. The request body is deserialized into a Mono,
     * and the response is sent when the 'createOrder' mono completes.
     * @param requestDto The order data from the request body.
     * @return A Mono emitting the created order DTO with HTTP status 201.
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<OrderResponseDto> createOrder(@RequestBody OrderRequestDto requestDto) {
        return orderService.createOrder(requestDto);
    }

    /**
     * Endpoint to retrieve an order by its ID.
     * @param id The ID of the order.
     * @return A Mono emitting a ResponseEntity. The response will be 200 OK with the order DTO
     *         if found, or 404 Not Found if not.
     */
    @GetMapping("/{id}")
    public Mono<ResponseEntity<OrderResponseDto>> getOrderById(@PathVariable String id) {
        return orderService.getOrderById(id)
                .map(ResponseEntity::ok)
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }

    /**
     * Endpoint to retrieve all orders for the authenticated user.
     * It uses the 'Authentication' principal from the security context to identify the user.
     * @param authentication The authentication principal.
     * @return A Flux emitting all order DTOs for the given user.
     */
    @GetMapping("/user/my-orders")
    public Flux<OrderResponseDto> getMyOrders(org.springframework.security.core.Authentication authentication) {
        String username = authentication.getName();
        return orderService.getOrdersByUsername(username);
    }

    /**
     * Endpoint to update an existing order.
     * @param id The ID of the order to update.
     * @param requestDto The DTO containing the updated order data.
     * @return A Mono emitting a ResponseEntity with the updated DTO if found, or 404 Not Found.
     */
    @PutMapping("/{id}")
    public Mono<ResponseEntity<OrderResponseDto>> updateOrder(@PathVariable String id, @RequestBody OrderRequestDto requestDto) {
        return orderService.updateOrder(id, requestDto)
                .map(ResponseEntity::ok)
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }

    /**
     * Endpoint to delete an order by its ID.
     * @param id The ID of the order to delete.
     * @return A Mono<Void> that completes when the deletion is done.
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteOrder(@PathVariable String id) {
        return orderService.deleteOrder(id);
    }
}
