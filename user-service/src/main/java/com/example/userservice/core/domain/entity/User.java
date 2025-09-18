package com.example.userservice.core.domain.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Represents the User entity in the database.
 * This class is mapped to the 'users' table.
 *
 * It uses the Builder pattern (@Builder) for easy and readable object instantiation.
 * Lombok's @Data has been avoided in favor of more granular annotations (@Getter, @Setter)
 * to provide finer control over generated boilerplate code and avoid potential issues
 * with bi-directional relationships or unintended mutability.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false, unique = true)
    private String email;

    /**
     * In a real-world application, this password would be securely hashed
     * using an algorithm like BCrypt before being persisted.
     */
    @Column(nullable = false)
    private String password;

    // By using CascadeType.ALL, any operations (persist, remove, refresh, merge, detach)
    // performed on the User entity will be cascaded to the associated Address entity.
    // 'mappedBy = "user"' indicates that the 'user' field in the Address class is the owner of this relationship.
    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY, optional = false)
    private Address address;
}
