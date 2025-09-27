package com.concert.repository;

import com.concert.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneId;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("docker")
@Testcontainers
@Transactional
public class UserRepositoryDockerTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("testuser")
            .withPassword("testpass");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "com.mysql.cj.jdbc.Driver");
    }

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    protected void setUp() {
        userRepository.deleteAll();
    }

    private User createValidUser(String name, String username, String email, String password) {
        User user = new User();
        user.setName(name);
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(password);
        return user;
    }

    @Test
    public void testSaveAndFindUser() {
        // Create user
        User user = new User();
        user.setName("Test User");
        user.setUsername("testuser");
        user.setEmail("test@example.com");
        user.setPassword("hashedpassword");

        // Save user
        User savedUser = userRepository.save(user);

        // Verify save
        assertNotNull(savedUser.getId());
        assertEquals("testuser", savedUser.getUsername());
        assertEquals("test@example.com", savedUser.getEmail());
        assertNotNull(savedUser.getCreatedAt());
        assertNotNull(savedUser.getUpdatedAt());

        // Find by ID
        Optional<User> foundUser = userRepository.findById(savedUser.getId());
        assertTrue(foundUser.isPresent());
        assertEquals("testuser", foundUser.get().getUsername());
    }

    @Test
    public void testFindByUsername() {
        // Create and save user
        User user = new User();
        user.setName("Find Me User");
        user.setUsername("findme");
        user.setEmail("findme@example.com");
        user.setPassword("password");
        
        userRepository.save(user);

        // Find by username
        Optional<User> found = userRepository.findByUsername("findme");
        assertTrue(found.isPresent());
        assertEquals("findme@example.com", found.get().getEmail());

        // Test not found
        Optional<User> notFound = userRepository.findByUsername("notexist");
        assertFalse(notFound.isPresent());
    }

    @Test
    public void testFindByEmail() {
        // Create and save user
        User user = new User();
        user.setName("Email Test User");
        user.setUsername("emailtest");
        user.setEmail("email@example.com");
        user.setPassword("password");
        
        userRepository.save(user);

        // Find by email
        Optional<User> found = userRepository.findByEmail("email@example.com");
        assertTrue(found.isPresent());
        assertEquals("emailtest", found.get().getUsername());

        // Test not found
        Optional<User> notFound = userRepository.findByEmail("notexist@example.com");
        assertFalse(notFound.isPresent());
    }

    @Test
    public void testFindByUsernameOrEmail() {
        // Create and save user
        User user = new User();
        user.setName("Combined Test User");
        user.setUsername("combined");
        user.setEmail("combined@example.com");
        user.setPassword("password");
        
        userRepository.save(user);

        // Find by username
        Optional<User> foundByUsername = userRepository.findByUsernameOrEmail("combined", "wrong@email.com");
        assertTrue(foundByUsername.isPresent());
        assertEquals("combined", foundByUsername.get().getUsername());

        // Find by email
        Optional<User> foundByEmail = userRepository.findByUsernameOrEmail("wronguser", "combined@example.com");
        assertTrue(foundByEmail.isPresent());
        assertEquals("combined@example.com", foundByEmail.get().getEmail());

        // Test not found
        Optional<User> notFound = userRepository.findByUsernameOrEmail("notexist", "notexist@example.com");
        assertFalse(notFound.isPresent());
    }

    @Test
    public void testExistsByUsername() {
        // Create and save user
        User user = new User();
        user.setName("Exists Test User");
        user.setUsername("exists");
        user.setEmail("exists@example.com");
        user.setPassword("password");
        
        userRepository.save(user);

        // Test exists
        assertTrue(userRepository.existsByUsername("exists"));
        assertFalse(userRepository.existsByUsername("notexists"));
    }

    @Test
    public void testExistsByEmail() {
        // Create and save user
        User user = new User();
        user.setName("Email Exists User");
        user.setUsername("emailexists");
        user.setEmail("exists@example.com");
        user.setPassword("password");
        
        userRepository.save(user);

        // Test exists
        assertTrue(userRepository.existsByEmail("exists@example.com"));
        assertFalse(userRepository.existsByEmail("notexists@example.com"));
    }

    @Test
    public void testUserCreationTime() {
        LocalDateTime beforeCreation = LocalDateTime.now();
        
        User user = new User();
        user.setName("Time Test User");
        user.setUsername("timetest");
        user.setEmail("time@example.com");
        user.setPassword("password");
        
        User savedUser = userRepository.save(user);
        
        LocalDateTime afterCreation = LocalDateTime.now();
        
        assertNotNull(savedUser.getCreatedAt());
        assertNotNull(savedUser.getUpdatedAt());
        
        // Convert to same timezone for comparison - allow 1 microsecond difference
        long createdAtMillis = savedUser.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
        long beforeMillis = beforeCreation.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
        long afterMillis = afterCreation.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
        
        assertTrue(createdAtMillis >= beforeMillis, 
            String.format("Creation time %d should be after before time %d", createdAtMillis, beforeMillis));
        assertTrue(createdAtMillis <= afterMillis, 
            String.format("Creation time %d should be before after time %d", createdAtMillis, afterMillis));
        
        // Allow microsecond precision difference between createdAt and updatedAt
        long timeDiff = Math.abs(savedUser.getCreatedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli() 
                               - savedUser.getUpdatedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
        assertTrue(timeDiff <= 1, "CreatedAt and UpdatedAt should be within 1 millisecond of each other");
    }

    @Test
    public void testMultipleUsersInDocker() {
        // Create multiple users to test Docker container can handle multiple operations
        for (int i = 0; i < 5; i++) {
            User user = new User();
            user.setName("User " + i);
            user.setUsername("user" + i);
            user.setEmail("user" + i + "@example.com");
            user.setPassword("password" + i);
            userRepository.save(user);
        }

        // Verify all users were saved
        assertEquals(5, userRepository.count());

        // Verify we can find each user
        for (int i = 0; i < 5; i++) {
            assertTrue(userRepository.existsByUsername("user" + i));
            assertTrue(userRepository.existsByEmail("user" + i + "@example.com"));
        }
    }

    @Test
    public void testDockerPersistenceAcrossOperations() {
        // Save a user
        User user = new User();
        user.setName("Persistent User");
        user.setUsername("persistent");
        user.setEmail("persistent@example.com");
        user.setPassword("password");
        
        User savedUser = userRepository.save(user);

        // Verify the user persists
        Optional<User> foundUser = userRepository.findById(savedUser.getId());
        assertTrue(foundUser.isPresent());
        assertEquals("persistent", foundUser.get().getUsername());
        assertEquals("persistent@example.com", foundUser.get().getEmail());
    }
}
