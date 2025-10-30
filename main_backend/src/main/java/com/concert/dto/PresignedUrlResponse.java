package com.concert.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for responding with a pre-signed URL for file upload
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PresignedUrlResponse {
    private String uploadUrl;           // Pre-signed URL for S3 upload
    private int expirationSeconds;      // Seconds until URL expires
}
