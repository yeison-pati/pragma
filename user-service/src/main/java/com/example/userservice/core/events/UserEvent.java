package com.example.userservice.core.events;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserEvent {
    private String eventType; // USER_CREATED, USER_UPDATED
    private Long id;
    private String username;
    private String email;
}
