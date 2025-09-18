package com.example.orderservice.core.domain.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Represents an Order document in the MongoDB database.
 * The 'collection' attribute specifies the name of the collection in Mongo.
 *
 * It uses the Builder pattern (@Builder) for easy and readable object instantiation.
 * Lombok's @Data has been avoided in favor of more granular annotations (@Getter, @Setter)
 * to provide finer control over generated boilerplate code.
 */
@Document(collection = "orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {

    @Id
    private String id;
    
    private String username;

    private String customerName;

    private List<String> productIds;

    private BigDecimal totalAmount;

    private LocalDateTime orderDate;
}
