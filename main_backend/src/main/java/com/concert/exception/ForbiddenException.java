package com.concert.exception;

/**
 * Maps to HTTP 403 Forbidden: the caller is authenticated but may not act on this resource.
 * Extends IllegalArgumentException so existing callers that catch it keep working.
 */
public class ForbiddenException extends IllegalArgumentException {

    public ForbiddenException(String message) {
        super(message);
    }
}
