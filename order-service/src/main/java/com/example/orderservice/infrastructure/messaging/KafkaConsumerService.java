package com.example.orderservice.infrastructure.messaging;


import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import com.example.orderservice.core.events.UserEvent;
import com.example.orderservice.core.service.OrderService;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaConsumerService {

    private final OrderService orderService;

    @KafkaListener(topics = "user-events", groupId = "order-service-group")
    public void consumeUserEvent(UserEvent event) {
        log.info("Received UserEvent: {}", event);

        switch (event.getEventType()) {
            case "USER_UPDATED":
                orderService.updateOrderCustomerData(event);
                break;

            case "USER_CREATED":
                log.info("No action required for USER_CREATED");
                break;

            default:
                log.warn("Unknown event type: {}", event.getEventType());
        }
    }
}
