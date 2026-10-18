package com.concert.exception;

/**
 * Maps to HTTP 401 Unauthorized: the request has no usable authentication.
 * Extends IllegalArgumentException so existing callers that catch it keep working.
 */
public class UnauthorizedException extends IllegalArgumentException {

    public UnauthorizedException(String message) {
        super(message);
    }
}
