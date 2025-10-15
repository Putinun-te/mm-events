package com.concert.dto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class UserProfileResponseTest {

    @Test
    void testNoArgsConstructor() {
        UserProfileResponse response = new UserProfileResponse();
        assertNotNull(response);
        assertNull(response.getId());
        assertNull(response.getUsername());
        assertNull(response.getEmail());
    }

    @Test
    void testAllArgsConstructor() {
        UserProfileResponse response = new UserProfileResponse(
            1L, "testuser", "test@example.com", "Test User",
            "1234567890", "123 Test St", "Test City", "Test Country",
            "12345", "photo.jpg", "Test Company", "http://test.com"
        );

        assertEquals(1L, response.getId());
        assertEquals("testuser", response.getUsername());
        assertEquals("test@example.com", response.getEmail());
        assertEquals("Test User", response.getName());
        assertEquals("1234567890", response.getPhone());
        assertEquals("123 Test St", response.getAddress());
        assertEquals("Test City", response.getCity());
        assertEquals("Test Country", response.getCountry());
        assertEquals("12345", response.getPincode());
        assertEquals("photo.jpg", response.getProfilePhoto());
        assertEquals("Test Company", response.getCompany());
        assertEquals("http://test.com", response.getWebsite());
    }

    @Test
    void testSettersAndGetters() {
        UserProfileResponse response = new UserProfileResponse();

        response.setId(2L);
        response.setUsername("newuser");
        response.setEmail("new@example.com");
        response.setName("New User");
        response.setPhone("9876543210");
        response.setAddress("456 New St");
        response.setCity("New City");
        response.setCountry("New Country");
        response.setPincode("54321");
        response.setProfilePhoto("newphoto.jpg");
        response.setCompany("New Company");
        response.setWebsite("http://newsite.com");

        assertEquals(2L, response.getId());
        assertEquals("newuser", response.getUsername());
        assertEquals("new@example.com", response.getEmail());
        assertEquals("New User", response.getName());
        assertEquals("9876543210", response.getPhone());
        assertEquals("456 New St", response.getAddress());
        assertEquals("New City", response.getCity());
        assertEquals("New Country", response.getCountry());
        assertEquals("54321", response.getPincode());
        assertEquals("newphoto.jpg", response.getProfilePhoto());
        assertEquals("New Company", response.getCompany());
        assertEquals("http://newsite.com", response.getWebsite());
    }

    @Test
    void testWithNullValues() {
        UserProfileResponse response = new UserProfileResponse(
            null, null, null, null, null, null, null, null, null, null, null, null
        );

        assertNull(response.getId());
        assertNull(response.getUsername());
        assertNull(response.getEmail());
        assertNull(response.getName());
        assertNull(response.getPhone());
        assertNull(response.getAddress());
        assertNull(response.getCity());
        assertNull(response.getCountry());
        assertNull(response.getPincode());
        assertNull(response.getProfilePhoto());
        assertNull(response.getCompany());
        assertNull(response.getWebsite());
    }
}
