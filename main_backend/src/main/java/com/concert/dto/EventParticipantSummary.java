package com.concert.dto;

import java.time.LocalDateTime;

public class EventParticipantSummary {
    private String userName;
    private Integer ticketCount;
    private LocalDateTime joinedAt;

    public EventParticipantSummary() {}

    public EventParticipantSummary(String userName, Integer ticketCount, LocalDateTime joinedAt) {
        this.userName = userName;
        this.ticketCount = ticketCount;
        this.joinedAt = joinedAt;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public Integer getTicketCount() {
        return ticketCount;
    }

    public void setTicketCount(Integer ticketCount) {
        this.ticketCount = ticketCount;
    }

    public LocalDateTime getJoinedAt() {
        return joinedAt;
    }

    public void setJoinedAt(LocalDateTime joinedAt) {
        this.joinedAt = joinedAt;
    }
}