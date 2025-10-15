package com.concert.dto;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class UpdateProfileRequestTest {

    @Test
    void testNoArgsConstructor() {
        UpdateProfileRequest request = new UpdateProfileRequest();
        assertNotNull(request);
        assertNull(request.getFirstName());
        assertNull(request.getLastName());
    }

    @Test
    void testSettersAndGetters() {
        UpdateProfileRequest request = new UpdateProfileRequest();

        request.setFirstName("John");
        request.setLastName("Doe");
        request.setPhone("1234567890");
        request.setAddress("123 Main St");
        request.setCity("New York");
        request.setCountry("USA");
        request.setPincode("10001");
        request.setProfilePhoto("profile.jpg");
        request.setCompany("Tech Corp");
        request.setWebsite("https://example.com");

        assertEquals("John", request.getFirstName());
        assertEquals("Doe", request.getLastName());
        assertEquals("1234567890", request.getPhone());
        assertEquals("123 Main St", request.getAddress());
        assertEquals("New York", request.getCity());
        assertEquals("USA", request.getCountry());
        assertEquals("10001", request.getPincode());
        assertEquals("profile.jpg", request.getProfilePhoto());
        assertEquals("Tech Corp", request.getCompany());
        assertEquals("https://example.com", request.getWebsite());
    }

    @Test
    void testWithNullValues() {
        UpdateProfileRequest request = new UpdateProfileRequest();

        assertNull(request.getFirstName());
        assertNull(request.getLastName());
        assertNull(request.getPhone());
        assertNull(request.getAddress());
        assertNull(request.getCity());
        assertNull(request.getCountry());
        assertNull(request.getPincode());
        assertNull(request.getProfilePhoto());
        assertNull(request.getCompany());
        assertNull(request.getWebsite());
    }

    @Test
    void testPartialUpdate() {
        UpdateProfileRequest request = new UpdateProfileRequest();
        
        request.setFirstName("Jane");
        request.setCity("Los Angeles");
        
        assertEquals("Jane", request.getFirstName());
        assertEquals("Los Angeles", request.getCity());
        assertNull(request.getLastName());
        assertNull(request.getPhone());
    }
}
