package com.example.userservice.infrastructure.config;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.example.userservice.core.exceptions.UserNotFoundException;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleUserNotFound(UserNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "User not found", "message", ex.getMessage()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, String>> handleDataIntegrityViolation(DataIntegrityViolationException ex) {
        String message = "Data already exists";
        if (ex.getMessage().contains("email")) {
            message = "Email already exists";
        } else if (ex.getMessage().contains("username")) {
            message = "Username already exists";
        }
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Map.of("error", "Duplicate data", "message", message));
    }

    @ExceptionHandler(NullPointerException.class)
    public ResponseEntity<Map<String, String>> handleNullPointer(NullPointerException ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Internal error", "message", "Required data is missing"));
    }

    @ExceptionHandler(java.util.concurrent.CompletionException.class)
    public ResponseEntity<Map<String, String>> handleCompletionException(java.util.concurrent.CompletionException ex) {
        Throwable cause = ex.getCause();
        if (cause instanceof DataIntegrityViolationException) {
            return handleDataIntegrityViolation((DataIntegrityViolationException) cause);
        } else if (cause instanceof NullPointerException) {
            return handleNullPointer((NullPointerException) cause);
        }
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Internal server error", "message", cause != null ? cause.getMessage() : "Unknown error"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneric(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Internal server error", "message", ex.getMessage()));
    }
}

