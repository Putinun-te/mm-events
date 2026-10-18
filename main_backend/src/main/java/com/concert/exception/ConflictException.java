package com.concert.exception;

/**
 * Maps to HTTP 409 Conflict: the request is valid but clashes with the current state,
 * e.g. not enough seats left.
 * Extends IllegalArgumentException so existing callers that catch it keep working.
 */
public class ConflictException extends IllegalArgumentException {

    public ConflictException(String message) {
        super(message);
    }
}
