package com.concert.integration;

import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class EventRepositoryIntegrationTest {

    private final String URL = "jdbc:mysql://localhost:3306/concert_db";
    private final String USER = "username";
    private final String PASSWORD = "password";

    @Test
    void testRepositoryConnection() throws Exception {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
             Statement stmt = conn.createStatement()) {

            ResultSet rs = stmt.executeQuery("SELECT 1");
            rs.next();
            int result = rs.getInt(1);
            assertTrue(result == 1, "Database connection should be successful");
        }
    }
}
