package com.example.userservice.core.service.impl;

import com.example.userservice.core.domain.entity.User;
import com.example.userservice.core.domain.repository.UserRepository;
import com.example.userservice.core.events.UserEvent;
import com.example.userservice.core.service.security.JwtService;
import com.example.userservice.infrastructure.messaging.KafkaProducerService;

import jakarta.transaction.Transactional;

import com.example.userservice.application.rest.dto.RegisterUserRequest;
import com.example.userservice.application.rest.dto.UserResponseDto;
import com.example.userservice.application.rest.dto.LoginRequest;
import com.example.userservice.application.rest.dto.AddressDto;
import com.example.userservice.application.rest.dto.AuthenticationResponse;

import lombok.RequiredArgsConstructor;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final KafkaProducerService kafkaProducerService;
    private final ExecutorService authExecutor;

    @Transactional
    public AuthenticationResponse registerTransactional(RegisterUserRequest request) {
        var address = com.example.userservice.core.domain.entity.Address.builder()
                .street(request.getAddress().getStreet())
                .city(request.getAddress().getCity())
                .state(request.getAddress().getState())
                .zipCode(request.getAddress().getZipCode())
                .build();

        var user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .address(address)
                .build();

        address.setUser(user);
        User savedUser = userRepository.save(user);

        kafkaProducerService.sendUserEvent(
                new UserEvent("USER_CREATED", savedUser.getId(), savedUser.getUsername(), savedUser.getEmail())
        );

        String jwtToken = jwtService.generateToken(savedUser);

        return AuthenticationResponse.builder()
                .token(jwtToken)
                .user(toDto(savedUser)) // devolvemos entidad convertida a DTO
                .build();
    }

    public CompletableFuture<AuthenticationResponse> register(RegisterUserRequest request) {
        return CompletableFuture.supplyAsync(() -> registerTransactional(request), authExecutor);
    }

    public CompletableFuture<AuthenticationResponse> login(LoginRequest request) {
        return CompletableFuture.supplyAsync(() -> {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
            );

            var user = userRepository.findByUsername(request.getUsername())
                    .orElseThrow();

            String jwtToken = jwtService.generateToken(user);

            return AuthenticationResponse.builder()
                    .token(jwtToken)
                    .user(toDto(user))
                    .build();
        }, authExecutor);
    }

    private UserResponseDto toDto(User entity) {
        AddressDto addressDto = AddressDto.builder()
                .street(entity.getAddress().getStreet())
                .city(entity.getAddress().getCity())
                .state(entity.getAddress().getState())
                .zipCode(entity.getAddress().getZipCode())
                .build();

        return UserResponseDto.builder()
                .id(entity.getId())
                .username(entity.getUsername())
                .email(entity.getEmail())
                .address(addressDto)
                .build();
    }
}