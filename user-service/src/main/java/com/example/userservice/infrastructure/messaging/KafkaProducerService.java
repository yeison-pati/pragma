package com.example.userservice.infrastructure.messaging;

import com.example.userservice.core.events.UserEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaProducerService {

    private final KafkaTemplate<String, UserEvent> kafkaTemplate;

    private String topic = "user-events";
    public void sendUserEvent(UserEvent event) {
        kafkaTemplate.send(topic, event.getId().toString(), event);
        log.info(" Published event to Kafka: {}", event);
    }
}

