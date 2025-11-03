package com.concert.controller;

import com.concert.dto.UserProfileResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.DisabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@DisabledIfSystemProperty(named = "java.specification.version", matches = "24")
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserRepository userRepository;

    @MockBean
    private com.concert.service.JwtService jwtService;

    @MockBean
    private com.concert.service.UserProfileService userProfileService;

    private User testUser1;
    private User testUser2;

    @BeforeEach
    void setUp() {
        testUser1 = new User();
        testUser1.setId(1L);
        testUser1.setUsername("testuser1");
        testUser1.setEmail("test1@example.com");
        testUser1.setName("Test User 1");
        testUser1.setPassword("password123");
        testUser1.setCreatedAt(LocalDateTime.now());

        testUser2 = new User();
        testUser2.setId(2L);
        testUser2.setUsername("testuser2");
        testUser2.setEmail("test2@example.com");
        testUser2.setName("Test User 2");
        testUser2.setPassword("password456");
        testUser2.setCreatedAt(LocalDateTime.now());

        when(userProfileService.buildResponse(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            UserProfileResponse response = new UserProfileResponse();
            response.setId(user.getId());
            response.setUsername(user.getUsername());
            response.setEmail(user.getEmail());
            response.setName(user.getName());
            response.setPhone(user.getPhone());
            response.setAddress(user.getAddress());
            response.setCity(user.getCity());
            response.setCountry(user.getCountry());
            response.setPincode(user.getPincode());
            response.setProfilePhoto(user.getProfilePhoto());
            response.setCompany(user.getCompany());
            response.setWebsite(user.getWebsite());
            return response;
        });
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetAllUsers_Success() throws Exception {
        // Arrange
        List<User> mockUsers = Arrays.asList(testUser1, testUser2);
        when(userRepository.findAll()).thenReturn(mockUsers);

        // Act & Assert
        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].username").value("testuser1"))
                .andExpect(jsonPath("$[0].email").value("test1@example.com"))
                .andExpect(jsonPath("$[0].name").value("Test User 1"))
                .andExpect(jsonPath("$[1].id").value(2))
                .andExpect(jsonPath("$[1].username").value("testuser2"))
                .andExpect(jsonPath("$[1].email").value("test2@example.com"))
                .andExpect(jsonPath("$[1].name").value("Test User 2"));
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetUserById_Success() throws Exception {
        // Arrange
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser1));

        // Act & Assert
        mockMvc.perform(get("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.username").value("testuser1"))
                .andExpect(jsonPath("$.email").value("test1@example.com"))
                .andExpect(jsonPath("$.name").value("Test User 1"));
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetUserById_NotFound() throws Exception {
        // Arrange
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        // Act & Assert
        mockMvc.perform(get("/api/users/999")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    void testGetAllUsers_Unauthorized() throws Exception {
        // Test without authentication
        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetAllUsers_EmptyList() throws Exception {
        // Arrange
        when(userRepository.findAll()).thenReturn(Arrays.asList());

        // Act & Assert
        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(0));
    }
    
    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetUserById_ValidUserDetailed() throws Exception {
        // Arrange
        testUser1.setPhone("1234567890");
        testUser1.setAddress("123 Test Street");
        when(userRepository.findById(1L)).thenReturn(Optional.of(testUser1));

        // Act & Assert
        mockMvc.perform(get("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.username").value("testuser1"))
                .andExpect(jsonPath("$.email").value("test1@example.com"))
                .andExpect(jsonPath("$.name").value("Test User 1"));
    }
    
    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetAllUsers_MultipleUsersReturned() throws Exception {
        // Arrange
        List<User> users = Arrays.asList(testUser1, testUser2);
        when(userRepository.findAll()).thenReturn(users);

        // Act & Assert
        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].username").value("testuser1"))
                .andExpect(jsonPath("$[1].username").value("testuser2"));
    }
    
    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetUserById_WithZeroId() throws Exception {
        // Arrange
        when(userRepository.findById(0L)).thenReturn(Optional.empty());

        // Act & Assert
        mockMvc.perform(get("/api/users/0")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isNotFound());
    }

    // ==================== Exception Path Tests (Branch Coverage) ====================

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetAllUsers_ExceptionThrown() throws Exception {
        // Arrange - Mock repository to throw exception
        when(userRepository.findAll()).thenThrow(new RuntimeException("Database error"));

        // Act & Assert - Should return 500 Internal Server Error
        mockMvc.perform(get("/api/users")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError());
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testGetUserById_ExceptionThrown() throws Exception {
        // Arrange - Mock repository to throw exception
        when(userRepository.findById(any(Long.class))).thenThrow(new RuntimeException("Database error"));

        // Act & Assert - Should return 500 Internal Server Error
        mockMvc.perform(get("/api/users/1")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError());
    }

    // ==================== PUT /me Tests (Missing Coverage) ====================

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_Success_AllFields() throws Exception {
        // Arrange
        String requestBody = """
            {
                "firstName": "John",
                "lastName": "Doe",
                "phone": "1234567890",
                "address": "123 Main St",
                "city": "New York",
                "country": "USA",
                "pincode": "10001",
                "profilePhoto": "https://example.com/photo.jpg",
                "company": "Tech Corp",
                "website": "https://johndoe.com"
            }
            """;

        User existingUser = new User();
        existingUser.setId(1L);
        existingUser.setUsername("testuser");
        existingUser.setEmail("test@example.com");
        existingUser.setName("Old Name");

        User updatedUser = new User();
        updatedUser.setId(1L);
        updatedUser.setUsername("testuser");
        updatedUser.setEmail("test@example.com");
        updatedUser.setName("John Doe");
        updatedUser.setPhone("1234567890");
        updatedUser.setAddress("123 Main St");
        updatedUser.setCity("New York");
        updatedUser.setCountry("USA");
        updatedUser.setPincode("10001");
        updatedUser.setProfilePhoto("https://example.com/photo.jpg");
        updatedUser.setCompany("Tech Corp");
        updatedUser.setWebsite("https://johndoe.com");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(existingUser));
        when(userRepository.save(any(User.class))).thenReturn(updatedUser);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.username").value("testuser"))
                .andExpect(jsonPath("$.email").value("test@example.com"))
                .andExpect(jsonPath("$.name").value("John Doe"))
                .andExpect(jsonPath("$.phone").value("1234567890"))
                .andExpect(jsonPath("$.address").value("123 Main St"))
                .andExpect(jsonPath("$.city").value("New York"))
                .andExpect(jsonPath("$.country").value("USA"))
                .andExpect(jsonPath("$.pincode").value("10001"))
                .andExpect(jsonPath("$.profilePhoto").value("https://example.com/photo.jpg"))
                .andExpect(jsonPath("$.company").value("Tech Corp"))
                .andExpect(jsonPath("$.website").value("https://johndoe.com"));
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_PartialUpdate_OnlyPhone() throws Exception {
        // Arrange - Only update phone
        String requestBody = """
            {
                "phone": "9876543210"
            }
            """;

        User existingUser = new User();
        existingUser.setId(1L);
        existingUser.setUsername("testuser");
        existingUser.setEmail("test@example.com");
        existingUser.setName("Test User");
        existingUser.setPhone("1234567890");

        User updatedUser = new User();
        updatedUser.setId(1L);
        updatedUser.setUsername("testuser");
        updatedUser.setEmail("test@example.com");
        updatedUser.setName("Test User");
        updatedUser.setPhone("9876543210");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(existingUser));
        when(userRepository.save(any(User.class))).thenReturn(updatedUser);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.phone").value("9876543210"));
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_NameUpdate_FirstNameOnly() throws Exception {
        // Arrange - Test firstName branch
        String requestBody = """
            {
                "firstName": "Alice"
            }
            """;

        User existingUser = new User();
        existingUser.setId(1L);
        existingUser.setUsername("testuser");
        existingUser.setEmail("test@example.com");
        existingUser.setName("Old Name");

        User updatedUser = new User();
        updatedUser.setId(1L);
        updatedUser.setUsername("testuser");
        updatedUser.setEmail("test@example.com");
        updatedUser.setName("Alice");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(existingUser));
        when(userRepository.save(any(User.class))).thenReturn(updatedUser);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Alice"));
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_NameUpdate_LastNameOnly() throws Exception {
        // Arrange - Test lastName branch
        String requestBody = """
            {
                "lastName": "Smith"
            }
            """;

        User existingUser = new User();
        existingUser.setId(1L);
        existingUser.setUsername("testuser");
        existingUser.setEmail("test@example.com");
        existingUser.setName("Old Name");

        User updatedUser = new User();
        updatedUser.setId(1L);
        updatedUser.setUsername("testuser");
        updatedUser.setEmail("test@example.com");
        updatedUser.setName("Smith");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(existingUser));
        when(userRepository.save(any(User.class))).thenReturn(updatedUser);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Smith"));
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_NameUpdate_BothNames() throws Exception {
        // Arrange - Test firstName + lastName branches
        String requestBody = """
            {
                "firstName": "Bob",
                "lastName": "Johnson"
            }
            """;

        User existingUser = new User();
        existingUser.setId(1L);
        existingUser.setUsername("testuser");
        existingUser.setEmail("test@example.com");
        existingUser.setName("Old Name");

        User updatedUser = new User();
        updatedUser.setId(1L);
        updatedUser.setUsername("testuser");
        updatedUser.setEmail("test@example.com");
        updatedUser.setName("Bob Johnson");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(existingUser));
        when(userRepository.save(any(User.class))).thenReturn(updatedUser);

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Bob Johnson"));
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_UserNotFound() throws Exception {
        // Arrange - User doesn't exist
        String requestBody = """
            {
                "phone": "1234567890"
            }
            """;

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.empty());

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_ExceptionThrown() throws Exception {
        // Arrange - Exception during update
        String requestBody = """
            {
                "phone": "1234567890"
            }
            """;

        when(userRepository.findByUsername("testuser")).thenThrow(new RuntimeException("Database error"));

        // Act & Assert
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isInternalServerError());
    }

    @Test
    @WithMockUser(username = "testuser", roles = {"USER"})
    void testUpdateMe_EmptyBody() throws Exception {
        // Arrange - Empty update (no fields)
        String requestBody = "{}";

        User existingUser = new User();
        existingUser.setId(1L);
        existingUser.setUsername("testuser");
        existingUser.setEmail("test@example.com");
        existingUser.setName("Test User");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(existingUser));
        when(userRepository.save(any(User.class))).thenReturn(existingUser);

        // Act & Assert - Should still return 200 with unchanged data
        mockMvc.perform(put("/api/users/me")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Test User"));
    }
}
