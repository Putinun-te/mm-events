package com.concert.dto;

public class EventPhotoResponse {
    private String photoUrl;
    private String photoId;
    private String message;
    private String uploadUrl;

    public EventPhotoResponse() {
    }

    public EventPhotoResponse(String photoUrl, String photoId, String message) {
        this.photoUrl = photoUrl;
        this.photoId = photoId;
        this.message = message;
    }

    public EventPhotoResponse(String photoUrl, String photoId, String message, String uploadUrl) {
        this.photoUrl = photoUrl;
        this.photoId = photoId;
        this.message = message;
        this.uploadUrl = uploadUrl;
    }

    // Getters and Setters
    public String getPhotoUrl() {
        return photoUrl;
    }

    public void setPhotoUrl(String photoUrl) {
        this.photoUrl = photoUrl;
    }

    public String getPhotoId() {
        return photoId;
    }

    public void setPhotoId(String photoId) {
        this.photoId = photoId;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getUploadUrl() {
        return uploadUrl;
    }

    public void setUploadUrl(String uploadUrl) {
        this.uploadUrl = uploadUrl;
    }
}
