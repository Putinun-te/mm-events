package com.concert.exception;

/**
 * Maps to HTTP 404 Not Found: the requested resource does not exist.
 * Extends IllegalArgumentException so existing callers that catch it keep working.
 */
public class NotFoundException extends IllegalArgumentException {

    public NotFoundException(String message) {
        super(message);
    }
}
