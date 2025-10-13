package com.concert.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Disabled;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class BookingServiceTest {

    private final String URL = "jdbc:mysql://localhost:3306/concert_db";
    private final String USER = "username";
    private final String PASSWORD = "password";

    @Test
    @Disabled("Requires manual database setup - use Docker tests instead")
    void testInsertBooking() throws Exception {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             Statement stmt = conn.createStatement()) {

            int result = stmt.executeUpdate(
                    "INSERT INTO bookings (user_id, event_id, quantity, total_price, booking_date) " +
                    "VALUES (1, 1, 2, 150.00, NOW())"
            );
            assertTrue(result > 0, "Booking should be inserted successfully");
        }
    }

    @Test
    @Disabled("Requires manual database setup - use Docker tests instead")
    void testBookingTableNotEmpty() throws Exception {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             Statement stmt = conn.createStatement()) {

            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS total FROM bookings");
            rs.next();
            int count = rs.getInt("total");
            assertTrue(count > 0, "Bookings table should not be empty");
        }
    }
}
