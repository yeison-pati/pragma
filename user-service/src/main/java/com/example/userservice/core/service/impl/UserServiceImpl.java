package com.example.userservice.core.service.impl;

import com.example.userservice.application.rest.dto.UserResponseDto;
import com.example.userservice.application.rest.dto.UserUpdateRequestDto;
import com.example.userservice.application.rest.dto.AddressDto;
import com.example.userservice.core.domain.entity.User;
import com.example.userservice.core.domain.repository.UserRepository;
import com.example.userservice.core.service.UserService;
import com.example.userservice.infrastructure.messaging.KafkaProducerService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.example.userservice.core.events.UserEvent;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final KafkaProducerService kafkaProducerService;
    private final PasswordEncoder passwordEncoder;
    private final ExecutorService userExecutor;

    @Override
    @Cacheable(value = "users", key = "#id")
    public CompletableFuture<UserResponseDto> getUserById(Long id) {
        return CompletableFuture.supplyAsync(() -> {
            log.info("DB hit -> fetching user {}", id);
            Optional<User> user = userRepository.findById(id);
            return toDto(user.orElseThrow());
        }, userExecutor);
    }

    @Override
    public CompletableFuture<List<UserResponseDto>> getAllUsers() {
        return CompletableFuture.supplyAsync(() -> userRepository.findAll()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList()), userExecutor);
    }

    
    @Transactional
    @CachePut(value = "users", key = "#id")
    public UserResponseDto updateUserTransactional(Long id, UserUpdateRequestDto update) {
        
            User user = userRepository.findById(id)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            if (update.getUsername() != null) user.setUsername(update.getUsername());
            if (update.getEmail() != null) user.setEmail(update.getEmail());
            if (update.getPassword() != null && !update.getPassword().isBlank()) {
                user.setPassword(passwordEncoder.encode(update.getPassword()));
            }
            User userUpdated = userRepository.save(user);
            kafkaProducerService.sendUserEvent(
                new UserEvent("USER_UPDATED", userUpdated.getId(), userUpdated.getUsername(), userUpdated.getEmail())
            );
            return toDto(userUpdated);
    }

    @Override
    public CompletableFuture<UserResponseDto> updateUser(Long id, UserUpdateRequestDto updateRequest) {
        return CompletableFuture.supplyAsync(() -> updateUserTransactional(id, updateRequest), userExecutor);
    }

    @Override
    @CacheEvict(value = "users", key = "#id")
    public CompletableFuture<Void> deleteUser(Long id) {
        return CompletableFuture.runAsync(() -> userRepository.deleteById(id), userExecutor);
    }

    @Override
    public CompletableFuture<String> generateUserReport(Long userId) {
        return CompletableFuture.supplyAsync(() -> {
            log.info("Generating report for {}", userId);
            try { Thread.sleep(5000); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
            return userRepository.findById(userId)
                    .map(u -> String.format("Report for %s (%s)", u.getUsername(), u.getEmail()))
                    .orElse("User not found");
        }, userExecutor);
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
