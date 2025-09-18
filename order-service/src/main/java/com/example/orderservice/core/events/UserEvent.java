package com.example.orderservice.core.events;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class UserEvent {
    private String eventType;
    private Long id;
    private String username;
    private String email;
}
