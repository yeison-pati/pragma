package com.example.userservice.application.rest;

import com.example.userservice.application.rest.dto.UserResponseDto;
import com.example.userservice.application.rest.dto.UserUpdateRequestDto;
import com.example.userservice.core.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public CompletableFuture<ResponseEntity<UserResponseDto>> getUser(@PathVariable Long id) {
        return userService.getUserById(id)
                .thenApply(opt -> new ResponseEntity<>(opt, HttpStatus.OK));
    }

    @GetMapping
    public CompletableFuture<ResponseEntity<List<UserResponseDto>>> getAllUsers() {
        return userService.getAllUsers()
                .thenApply(list -> new ResponseEntity<>(list, HttpStatus.OK));
    }

    @PutMapping("/{id}")
    public CompletableFuture<ResponseEntity<UserResponseDto>> updateUser(
            @PathVariable Long id,
            @RequestBody UserUpdateRequestDto request) {
        return userService.updateUser(id, request)
                .thenApply(opt -> new ResponseEntity<>(opt, HttpStatus.OK));
    }

    @DeleteMapping("/{id}")
    public CompletableFuture<ResponseEntity<Void>> deleteUser(@PathVariable Long id) {
        return CompletableFuture.runAsync(() -> userService.deleteUser(id))
                .thenApply(v -> ResponseEntity.noContent().build());
    }

    @GetMapping("/{id}/report")
    public CompletableFuture<ResponseEntity<String>> generateReport(@PathVariable Long id) {
        return userService.generateUserReport(id)
                .thenApply(ResponseEntity::ok);
    }
}

