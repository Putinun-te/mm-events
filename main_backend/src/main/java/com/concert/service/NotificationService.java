package com.concert.service;

import com.concert.dto.NotificationRequest;
import com.concert.dto.NotificationResponse;
import com.concert.model.Notification;
import com.concert.model.NotificationPreference;
import com.concert.model.User;
import com.concert.repository.NotificationRepository;
import com.concert.repository.NotificationPreferenceRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * NotificationService handles all notification-related operations.
 * Manages in-app notifications, preferences, and delivery.
 *
 * Features:
 * - Send notifications to users
 * - Manage notification preferences
 * - Retrieve notification history
 * - Mark notifications as read
 * - Bulk notification sending
 */
@Slf4j
@Service
@Transactional
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final NotificationPreferenceRepository preferenceRepository;
    private final EmailService emailService;

    public NotificationService(
            NotificationRepository notificationRepository,
            NotificationPreferenceRepository preferenceRepository,
            EmailService emailService) {
        this.notificationRepository = notificationRepository;
        this.preferenceRepository = preferenceRepository;
        this.emailService = emailService;
    }

    /**
     * Send a notification to a single user
     */
    public NotificationResponse notifyUser(Long userId, NotificationRequest request) {
        log.info("Creating notification for user: {}", userId);

        Notification notification = new Notification();
        notification.setUserId(userId);
        notification.setTitle(request.getTitle());
        notification.setMessage(request.getMessage());
        notification.setType(request.getType());
        notification.setRead(false);
        notification.setCreatedAt(LocalDateTime.now());
        notification.setUpdatedAt(LocalDateTime.now());

        Notification saved = notificationRepository.save(notification);
        
        // Send email if user has email notifications enabled
        sendEmailIfEnabled(userId, request);
        
        log.info("Notification created with id: {}", saved.getId());
        return toResponse(saved);
    }

    /**
     * Send bulk notifications to multiple users
     */
    public void notifyMultipleUsers(List<Long> userIds, NotificationRequest request) {
        log.info("Sending bulk notification to {} users", userIds.size());

        userIds.forEach(userId -> {
            try {
                notifyUser(userId, request);
            } catch (Exception e) {
                log.error("Failed to notify user: {}", userId, e);
            }
        });
    }

    /**
     * Get all notifications for a user
     */
    @Transactional(readOnly = true)
    public List<NotificationResponse> getUserNotifications(Long userId) {
        log.debug("Fetching notifications for user: {}", userId);

        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get unread notifications for a user
     */
    @Transactional(readOnly = true)
    public List<NotificationResponse> getUnreadNotifications(Long userId) {
        log.debug("Fetching unread notifications for user: {}", userId);

        return notificationRepository.findByUserIdAndReadFalseOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Mark a notification as read
     */
    public NotificationResponse markAsRead(Long notificationId) {
        log.info("Marking notification as read: {}", notificationId);

        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new IllegalArgumentException("Notification not found"));

        notification.setRead(true);
        notification.setUpdatedAt(LocalDateTime.now());
        Notification updated = notificationRepository.save(notification);

        return toResponse(updated);
    }

    /**
     * Mark all notifications as read for a user
     */
    public void markAllAsRead(Long userId) {
        log.info("Marking all notifications as read for user: {}", userId);

        List<Notification> notifications = notificationRepository
                .findByUserIdAndReadFalse(userId);

        notifications.forEach(notification -> {
            notification.setRead(true);
            notification.setUpdatedAt(LocalDateTime.now());
        });

        notificationRepository.saveAll(notifications);
    }

    /**
     * Delete a notification
     */
    public void deleteNotification(Long notificationId) {
        log.info("Deleting notification: {}", notificationId);
        notificationRepository.deleteById(notificationId);
    }

    /**
     * Delete all old notifications (older than 30 days)
     */
    public void deleteOldNotifications() {
        log.info("Deleting notifications older than 30 days");

        LocalDateTime thirtyDaysAgo = LocalDateTime.now().minusDays(30);
        List<Notification> oldNotifications = notificationRepository
                .findByCreatedAtBefore(thirtyDaysAgo);

        notificationRepository.deleteAll(oldNotifications);
        log.info("Deleted {} old notifications", oldNotifications.size());
    }

    /**
     * Update notification preferences for a user
     */
    public NotificationPreference updatePreferences(Long userId, NotificationPreference preference) {
        log.info("Updating notification preferences for user: {}", userId);

        NotificationPreference existing = preferenceRepository.findByUserId(userId)
                .orElse(new NotificationPreference());

        existing.setUserId(userId);
        existing.setEmailNotifications(preference.isEmailNotifications());
        existing.setPushNotifications(preference.isPushNotifications());
        existing.setSmsNotifications(preference.isSmsNotifications());
        existing.setEventReminders(preference.isEventReminders());
        existing.setMarketingEmails(preference.isMarketingEmails());
        existing.setUpdatedAt(LocalDateTime.now());

        return preferenceRepository.save(existing);
    }

    /**
     * Get notification preferences for a user
     */
    @Transactional(readOnly = true)
    public NotificationPreference getPreferences(Long userId) {
        return preferenceRepository.findByUserId(userId)
                .orElseGet(() -> new NotificationPreference(userId));
    }

    /**
     * Send event reminder notification
     */
    public void sendEventReminder(Long userId, String eventTitle, LocalDateTime eventStart) {
        NotificationRequest request = new NotificationRequest();
        request.setTitle("Event Reminder");
        request.setMessage("Your event '" + eventTitle + "' starts in 1 hour");
        request.setType("EVENT_REMINDER");

        notifyUser(userId, request);
        log.info("Event reminder sent to user: {}", userId);
    }

    /**
     * Send booking confirmation notification
     */
    public void sendBookingConfirmation(Long userId, String eventTitle, String bookingRef) {
        NotificationRequest request = new NotificationRequest();
        request.setTitle("Booking Confirmed");
        request.setMessage("Your booking for '" + eventTitle + "' is confirmed. Reference: " + bookingRef);
        request.setType("BOOKING_CONFIRMATION");

        notifyUser(userId, request);
        log.info("Booking confirmation sent to user: {}", userId);
    }

    /**
     * Send cancellation notification
     */
    public void sendCancellationNotification(Long userId, String eventTitle) {
        NotificationRequest request = new NotificationRequest();
        request.setTitle("Event Cancelled");
        request.setMessage("The event '" + eventTitle + "' has been cancelled");
        request.setType("EVENT_CANCELLATION");

        notifyUser(userId, request);
        log.info("Cancellation notification sent to user: {}", userId);
    }

    /**
     * Send email notification if user preferences allow
     */
    private void sendEmailIfEnabled(Long userId, NotificationRequest request) {
        try {
            NotificationPreference pref = getPreferences(userId);
            if (pref.isEmailNotifications()) {
                // Email would be sent here via EmailService
                log.debug("Email notification would be sent to user: {}", userId);
            }
        } catch (Exception e) {
            log.error("Failed to send email notification to user: {}", userId, e);
        }
    }

    /**
     * Convert Notification entity to response DTO
     */
    private NotificationResponse toResponse(Notification notification) {
        NotificationResponse response = new NotificationResponse();
        response.setId(notification.getId());
        response.setUserId(notification.getUserId());
        response.setTitle(notification.getTitle());
        response.setMessage(notification.getMessage());
        response.setType(notification.getType());
        response.setRead(notification.isRead());
        response.setCreatedAt(notification.getCreatedAt());
        response.setUpdatedAt(notification.getUpdatedAt());
        return response;
    }

    /**
     * Get notification statistics
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getNotificationStats(Long userId) {
        Map<String, Object> stats = new HashMap<>();
        
        List<Notification> all = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<Notification> unread = notificationRepository
                .findByUserIdAndReadFalseOrderByCreatedAtDesc(userId);

        stats.put("total", all.size());
        stats.put("unread", unread.size());
        stats.put("read", all.size() - unread.size());

        return stats;
    }
}
