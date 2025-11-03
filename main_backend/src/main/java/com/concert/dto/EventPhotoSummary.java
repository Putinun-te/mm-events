package com.concert.dto;

/**
 * Compact photo descriptor returned with event payloads to simplify client wiring.
 */
public class EventPhotoSummary {

    private String id;
    private String url;

    public EventPhotoSummary() {
    }

    public EventPhotoSummary(String id, String url) {
        this.id = id;
        this.url = url;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }
}
