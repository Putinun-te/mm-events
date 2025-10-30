package com.concert.service;

import com.concert.model.AuditLog;
import com.concert.repository.AuditLogRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AuditService tracks and logs all significant application activities.
 *
 * Features:
 * - Activity logging (CRUD operations)
 * - User action tracking
 * - Change history
 * - Compliance reporting
 * - Anomaly detection
 */
@Service
@Transactional
public class AuditService {

    private final AuditLogRepository auditLogRepository;
    private final ObjectMapper objectMapper;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Log an activity
     */
    public void logActivity(Long userId, String entityType, Long entityId, String action, String details) {
        try {
            AuditLog log = new AuditLog(userId, entityType, entityId, action, details);
            auditLogRepository.save(log);
        } catch (Exception e) {
            // Log but don't fail the main operation if audit logging fails
        }
    }

    /**
     * Log activity with object details
     */
    public void logActivityWithObject(Long userId, String entityType, Long entityId, String action, Object details) {
        try {
            String detailsJson = objectMapper.writeValueAsString(details);
            logActivity(userId, entityType, entityId, action, detailsJson);
        } catch (Exception e) {
            logActivity(userId, entityType, entityId, action, "{}");
        }
    }

    /**
     * Get activity history for an entity
     */
    @Transactional(readOnly = true)
    public List<AuditLog> getActivityHistory(String entityType, Long entityId) {
        return auditLogRepository.findByEntityTypeAndEntityId(entityType, entityId);
    }

    /**
     * Get user activity
     */
    @Transactional(readOnly = true)
    public List<AuditLog> getUserActivity(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        return auditLogRepository.findByUserIdAndCreatedAtBetween(userId, startDate, endDate);
    }

    /**
     * Get activity in date range
     */
    @Transactional(readOnly = true)
    public List<AuditLog> getActivityByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return auditLogRepository.findByCreatedAtBetween(startDate, endDate);
    }

    /**
     * Log user login
     */
    public void logUserLogin(Long userId, String email) {
        Map<String, Object> details = new HashMap<>();
        details.put("email", email);
        details.put("timestamp", LocalDateTime.now());
        logActivityWithObject(userId, "User", userId, "LOGIN", details);
    }

    /**
     * Log user logout
     */
    public void logUserLogout(Long userId) {
        Map<String, Object> details = new HashMap<>();
        details.put("timestamp", LocalDateTime.now());
        logActivityWithObject(userId, "User", userId, "LOGOUT", details);
    }

    /**
     * Log event creation
     */
    public void logEventCreated(Long userId, Long eventId, String eventTitle) {
        Map<String, Object> details = new HashMap<>();
        details.put("title", eventTitle);
        details.put("createdBy", userId);
        logActivityWithObject(userId, "Event", eventId, "CREATE", details);
    }

    /**
     * Log event update
     */
    public void logEventUpdated(Long userId, Long eventId, String eventTitle, Map<String, Object> changes) {
        Map<String, Object> details = new HashMap<>();
        details.put("title", eventTitle);
        details.put("changes", changes);
        logActivityWithObject(userId, "Event", eventId, "UPDATE", details);
    }

    /**
     * Log event deletion
     */
    public void logEventDeleted(Long userId, Long eventId, String eventTitle) {
        Map<String, Object> details = new HashMap<>();
        details.put("title", eventTitle);
        details.put("deletedBy", userId);
        logActivityWithObject(userId, "Event", eventId, "DELETE", details);
    }

    /**
     * Log booking creation
     */
    public void logBookingCreated(Long userId, Long bookingId, Long eventId, String eventTitle) {
        Map<String, Object> details = new HashMap<>();
        details.put("eventId", eventId);
        details.put("eventTitle", eventTitle);
        details.put("bookedBy", userId);
        logActivityWithObject(userId, "Booking", bookingId, "CREATE", details);
    }

    /**
     * Log booking cancellation
     */
    public void logBookingCancelled(Long userId, Long bookingId, Long eventId) {
        Map<String, Object> details = new HashMap<>();
        details.put("eventId", eventId);
        details.put("cancelledBy", userId);
        logActivityWithObject(userId, "Booking", bookingId, "CANCEL", details);
    }

    /**
     * Log file upload
     */
    public void logFileUpload(Long userId, String fileName, String fileType, long fileSize) {
        Map<String, Object> details = new HashMap<>();
        details.put("fileName", fileName);
        details.put("fileType", fileType);
        details.put("fileSize", fileSize);
        logActivityWithObject(userId, "File", null, "UPLOAD", details);
    }

    /**
     * Log file deletion
     */
    public void logFileDeletion(Long userId, String fileName) {
        Map<String, Object> details = new HashMap<>();
        details.put("fileName", fileName);
        logActivityWithObject(userId, "File", null, "DELETE", details);
    }

    /**
     * Generate compliance report
     */
    public Map<String, Object> generateComplianceReport(LocalDateTime startDate, LocalDateTime endDate) {
        List<AuditLog> logs = getActivityByDateRange(startDate, endDate);

        Map<String, Object> report = new HashMap<>();
        report.put("startDate", startDate);
        report.put("endDate", endDate);
        report.put("totalEvents", logs.size());
        report.put("creations", logs.stream().filter(l -> "CREATE".equals(l.getAction())).count());
        report.put("updates", logs.stream().filter(l -> "UPDATE".equals(l.getAction())).count());
        report.put("deletions", logs.stream().filter(l -> "DELETE".equals(l.getAction())).count());
        report.put("logins", logs.stream().filter(l -> "LOGIN".equals(l.getAction())).count());

        return report;
    }

    /**
     * Detect anomalies (simple implementation)
     */
    public List<String> detectAnomalies() {
        // This would implement more sophisticated anomaly detection
        // For now, just return an empty list
        return List.of();
    }
}
