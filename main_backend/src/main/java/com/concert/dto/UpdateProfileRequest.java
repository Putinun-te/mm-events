package com.concert.dto;

public class UpdateProfileRequest {
    private String firstName;
    private String lastName;
    private String phone;
    private String address;
    private String city;
    private String country;
    private String pincode;
    private String profilePhoto;
    private String company;
    private String website;

    public UpdateProfileRequest() {}

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

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
