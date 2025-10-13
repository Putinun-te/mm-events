package com.concert.dto;

public class UserProfileResponse {
    private Long id;
    private String username;
    private String email;
    private String name;
    private String phone;
    private String address;
    private String city;
    private String country;
    private String pincode;
    private String profilePhoto;
    private String company;
    private String website;

    public UserProfileResponse() {}

    public UserProfileResponse(Long id, String username, String email, String name, 
                               String phone, String address, String city, String country, 
                               String pincode, String profilePhoto, String company, String website) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.name = name;
        this.phone = phone;
        this.address = address;
        this.city = city;
        this.country = country;
        this.pincode = pincode;
        this.profilePhoto = profilePhoto;
        this.company = company;
        this.website = website;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }

    public String getPincode() { return pincode; }
    public void setPincode(String pincode) { this.pincode = pincode; }

    public String getProfilePhoto() { return profilePhoto; }
    public void setProfilePhoto(String profilePhoto) { this.profilePhoto = profilePhoto; }

    public String getCompany() { return company; }
    public void setCompany(String company) { this.company = company; }

    public String getWebsite() { return website; }
    public void setWebsite(String website) { this.website = website; }
}
