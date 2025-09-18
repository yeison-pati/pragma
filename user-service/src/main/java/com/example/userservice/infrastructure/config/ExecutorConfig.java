package com.example.userservice.infrastructure.config;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ExecutorConfig {
    
    @Bean(name = "authExecutor")
    public ExecutorService authExecutor() {
        return Executors.newFixedThreadPool(5); // auth ops livianas
    }

    @Bean(name = "userExecutor")
    public ExecutorService userExecutor() {
        return Executors.newCachedThreadPool(); // consultas que pueden crecer
    }
}

