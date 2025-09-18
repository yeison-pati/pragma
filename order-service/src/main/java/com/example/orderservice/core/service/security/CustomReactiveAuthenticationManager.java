package com.example.orderservice.core.service.security;

import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

/**
 * Custom AuthenticationManager for the reactive stack.
 * It validates the JWT and returns an Authentication object if the token is valid.
 */
@Component
@RequiredArgsConstructor
public class CustomReactiveAuthenticationManager implements ReactiveAuthenticationManager {

    private final JwtTokenProvider tokenProvider;

    @Override
    public Mono<Authentication> authenticate(Authentication authentication) {
        String authToken = authentication.getCredentials().toString();

        if (tokenProvider.validateToken(authToken)) {
            return Mono.just(tokenProvider.getAuthentication(authToken));
        } else {
            return Mono.empty();
        }
    }
}
