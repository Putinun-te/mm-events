package com.concert.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for requesting a pre-signed URL for file upload
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PresignedUrlRequest {
    private String eventId;      // For event pictures
    private String userId;       // For user avatars
    private String fileName;     // Name of the file to upload
}
