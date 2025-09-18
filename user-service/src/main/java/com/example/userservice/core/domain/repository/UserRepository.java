package com.example.userservice.core.domain.repository;

import com.example.userservice.core.domain.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Spring Data JPA repository for the User entity.
 * This interface provides the mechanism for storage, retrieval,
 * and search behavior for User objects.
 */
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Finds a user by their username.
     * Spring Data JPA automatically generates the query for this method based on its name.
     *
     * @param username The username to search for.
     * @return An Optional containing the user if found, or an empty Optional otherwise.
     */
    Optional<User> findByUsername(String username);
}
