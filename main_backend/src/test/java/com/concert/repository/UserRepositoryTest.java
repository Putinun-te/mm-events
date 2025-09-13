package com.concert.repository;

import com.concert.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.ActiveProfiles;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest
@ActiveProfiles("test")
class UserRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private UserRepository userRepository;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User("testuser", "test@example.com", "password123");
    }

    @Test
    void testSaveAndFindById() {
        // Act
        User savedUser = userRepository.save(testUser);
        Optional<User> foundUser = userRepository.findById(savedUser.getId());

        // Assert
        assertTrue(foundUser.isPresent());
        assertEquals(testUser.getUsername(), foundUser.get().getUsername());
        assertEquals(testUser.getEmail(), foundUser.get().getEmail());
        assertEquals(testUser.getPassword(), foundUser.get().getPassword());
    }

    @Test
    void testFindByUsername() {
        // Arrange
        entityManager.persistAndFlush(testUser);

        // Act
        Optional<User> foundUser = userRepository.findByUsername("testuser");

        // Assert
        assertTrue(foundUser.isPresent());
        assertEquals(testUser.getUsername(), foundUser.get().getUsername());
        assertEquals(testUser.getEmail(), foundUser.get().getEmail());
    }

    @Test
    void testFindByUsernameNotFound() {
        // Act
        Optional<User> foundUser = userRepository.findByUsername("nonexistent");

        // Assert
        assertFalse(foundUser.isPresent());
    }

    @Test
    void testFindByEmail() {
        // Arrange
        entityManager.persistAndFlush(testUser);

        // Act
        Optional<User> foundUser = userRepository.findByEmail("test@example.com");

        // Assert
        assertTrue(foundUser.isPresent());
        assertEquals(testUser.getUsername(), foundUser.get().getUsername());
        assertEquals(testUser.getEmail(), foundUser.get().getEmail());
    }

    @Test
    void testFindByEmailNotFound() {
        // Act
        Optional<User> foundUser = userRepository.findByEmail("nonexistent@example.com");

        // Assert
        assertFalse(foundUser.isPresent());
    }

    @Test
    void testFindByUsernameOrEmail() {
        // Arrange
        entityManager.persistAndFlush(testUser);

        // Act
        Optional<User> foundByUsername = userRepository.findByUsernameOrEmail("testuser", "testuser");
        Optional<User> foundByEmail = userRepository.findByUsernameOrEmail("test@example.com", "test@example.com");

        // Assert
        assertTrue(foundByUsername.isPresent());
        assertTrue(foundByEmail.isPresent());
        assertEquals(testUser.getId(), foundByUsername.get().getId());
        assertEquals(testUser.getId(), foundByEmail.get().getId());
    }

    @Test
    void testExistsByUsername() {
        // Arrange
        entityManager.persistAndFlush(testUser);

        // Act
        Boolean exists = userRepository.existsByUsername("testuser");
        Boolean notExists = userRepository.existsByUsername("nonexistent");

        // Assert
        assertTrue(exists);
        assertFalse(notExists);
    }

    @Test
    void testExistsByEmail() {
        // Arrange
        entityManager.persistAndFlush(testUser);

        // Act
        Boolean exists = userRepository.existsByEmail("test@example.com");
        Boolean notExists = userRepository.existsByEmail("nonexistent@example.com");

        // Assert
        assertTrue(exists);
        assertFalse(notExists);
    }

    @Test
    void testUniqueConstraints() {
        // Arrange
        entityManager.persistAndFlush(testUser);
        User duplicateUsernameUser = new User("testuser", "different@example.com", "password456");

        // Act & Assert
        assertThrows(Exception.class, () -> {
            entityManager.persistAndFlush(duplicateUsernameUser);
        });
    }

    @Test
    void testUserCreationTime() {
        // Act
        User savedUser = userRepository.save(testUser);

        // Assert
        assertNotNull(savedUser.getCreatedAt());
        assertNotNull(savedUser.getUpdatedAt());
        assertEquals(savedUser.getCreatedAt(), savedUser.getUpdatedAt());
    }
}
