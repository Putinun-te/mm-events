package com.concert;

import org.junit.platform.suite.api.SelectPackages;
import org.junit.platform.suite.api.Suite;
import org.junit.platform.suite.api.SuiteDisplayName;

@Suite
@SuiteDisplayName("Concert Backend Test Suite")
@SelectPackages({
    "com.concert.model",
    "com.concert.dto", 
    "com.concert.service",
    "com.concert.controller",
    "com.concert.repository",
    "com.concert.integration"
})
public class ConcertBackendTestSuite {
    // Test suite configuration class
}
