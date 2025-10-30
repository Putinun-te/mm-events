package com.concert.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Notification preference model for user notification settings
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "notification_preferences")
public class NotificationPreference {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;
    
    @Column(name = "email_notifications")
    private boolean emailNotifications = true;
    
    @Column(name = "push_notifications")
    private boolean pushNotifications = true;
    
    @Column(name = "sms_notifications")
    private boolean smsNotifications = false;
    
    @Column(name = "event_reminders")
    private boolean eventReminders = true;
    
    @Column(name = "marketing_emails")
    private boolean marketingEmails = true;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();
    
    public NotificationPreference(Long userId) {
        this.userId = userId;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
}
