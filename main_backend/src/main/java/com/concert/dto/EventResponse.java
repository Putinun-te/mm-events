package com.concert.dto;

import java.time.LocalDateTime;
import java.util.List;

public class EventResponse {

    private Long id;
    private String title;
    private String description;
    private String category;
    private String location;
    private String address;
    private String city;
    private String country;
    private Integer personLimit;
    private String phone;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Double ticketPrice;
    private String photoId;
    private String photoUrl;
    private EventPhotoSummary photo;
    private EventOrganizerSummary organizer;
    private Long organizerId;
    private String organizerUsername;
    private String organizerName;
    private boolean ownedByCurrentUser;
    private boolean ownedByRequester;
    private Integer participantsCount;
    private List<EventParticipantSummary> participants;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }

    public Integer getPersonLimit() {
        return personLimit;
    }

    public void setPersonLimit(Integer personLimit) {
        this.personLimit = personLimit;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public LocalDateTime getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDateTime startDate) {
        this.startDate = startDate;
    }

    public LocalDateTime getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDateTime endDate) {
        this.endDate = endDate;
    }

    public Double getTicketPrice() {
        return ticketPrice;
    }

    public void setTicketPrice(Double ticketPrice) {
        this.ticketPrice = ticketPrice;
    }

    public String getPhotoId() {
        return photoId;
    }

    public void setPhotoId(String photoId) {
        this.photoId = photoId;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    public void setPhotoUrl(String photoUrl) {
        this.photoUrl = photoUrl;
    }

    public EventPhotoSummary getPhoto() {
        return photo;
    }

    public void setPhoto(EventPhotoSummary photo) {
        this.photo = photo;
    }

    public EventOrganizerSummary getOrganizer() {
        return organizer;
    }

    public void setOrganizer(EventOrganizerSummary organizer) {
        this.organizer = organizer;
    }

    public Long getOrganizerId() {
        return organizerId;
    }

    public void setOrganizerId(Long organizerId) {
        this.organizerId = organizerId;
    }

    public String getOrganizerUsername() {
        return organizerUsername;
    }

    public void setOrganizerUsername(String organizerUsername) {
        this.organizerUsername = organizerUsername;
    }

    public String getOrganizerName() {
        return organizerName;
    }

    public void setOrganizerName(String organizerName) {
        this.organizerName = organizerName;
    }

    public boolean isOwnedByCurrentUser() {
        return ownedByCurrentUser;
    }

    public void setOwnedByCurrentUser(boolean ownedByCurrentUser) {
        this.ownedByCurrentUser = ownedByCurrentUser;
    }

    public boolean isOwnedByRequester() {
        return ownedByRequester;
    }

    public void setOwnedByRequester(boolean ownedByRequester) {
        this.ownedByRequester = ownedByRequester;
    }

    public Integer getParticipantsCount() {
        return participantsCount;
    }

    public void setParticipantsCount(Integer participantsCount) {
        this.participantsCount = participantsCount;
    }

    public List<EventParticipantSummary> getParticipants() {
        return participants;
    }

    public void setParticipants(List<EventParticipantSummary> participants) {
        this.participants = participants;
    }
}
