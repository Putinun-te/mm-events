package com.concert.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Disabled;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class EventServiceTest {

    private final String URL = "jdbc:mysql://localhost:3306/concert_db";
    private final String USER = "username";
    private final String PASSWORD = "password";

    @Test
    @Disabled("Requires manual database setup - use Docker tests instead")
    void testInsertEvent() throws Exception {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             Statement stmt = conn.createStatement()) {

            int result = stmt.executeUpdate(
                    "INSERT INTO events (title, category, description, location, start_date, end_date, user_id) " +
                    "VALUES ('Test Event', 'Music', 'Test Desc', 'Test Location', NOW(), NOW(), 1)"
            );
            assertTrue(result > 0, "Event should be inserted successfully");
        }
    }

    @Test
    @Disabled("Requires manual database setup - use Docker tests instead")
    void testEventsTableNotEmpty() throws Exception {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             Statement stmt = conn.createStatement()) {

            ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS total FROM events");
            rs.next();
            int count = rs.getInt("total");
            assertTrue(count > 0, "Events table should not be empty");
        }
    }
}
