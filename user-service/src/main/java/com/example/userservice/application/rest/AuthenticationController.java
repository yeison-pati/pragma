package com.example.userservice.application.rest;

import com.example.userservice.application.rest.dto.LoginRequest;
import com.example.userservice.application.rest.dto.RegisterUserRequest;
import com.example.userservice.core.service.impl.AuthenticationService;
import com.example.userservice.application.rest.dto.AuthenticationResponse;

import lombok.RequiredArgsConstructor;

import java.util.concurrent.CompletableFuture;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthenticationController {

    private final AuthenticationService authenticationService;

    @PostMapping("/register")
    public CompletableFuture<ResponseEntity<AuthenticationResponse>> register(
            @RequestBody RegisterUserRequest request) {
        return authenticationService.register(request)
                .thenApply(auth -> ResponseEntity.status(HttpStatus.CREATED).body(auth));
    }

    @PostMapping("/login")
    public CompletableFuture<ResponseEntity<AuthenticationResponse>> login(
            @RequestBody LoginRequest request) {
        return authenticationService.login(request)
                .thenApply(auth -> ResponseEntity.ok(auth));
    }
}

