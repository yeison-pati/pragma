package com.example.userservice.core.service;

import com.example.userservice.application.rest.dto.UserResponseDto;
import com.example.userservice.application.rest.dto.UserUpdateRequestDto;

import java.util.List;
import java.util.concurrent.CompletableFuture;

public interface UserService {

    CompletableFuture<UserResponseDto> getUserById(Long id);
    CompletableFuture<List<UserResponseDto>> getAllUsers();
    CompletableFuture<UserResponseDto> updateUser(Long id, UserUpdateRequestDto updateRequest);
    CompletableFuture<Void> deleteUser(Long id);
    CompletableFuture<String> generateUserReport(Long userId);
}
