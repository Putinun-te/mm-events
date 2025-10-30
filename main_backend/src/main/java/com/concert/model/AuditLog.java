package com.concert.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Audit log model for tracking all significant application activities
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "audit_logs", indexes = {
    @Index(name = "idx_entity", columnList = "entity_type,entity_id"),
    @Index(name = "idx_user", columnList = "user_id"),
    @Index(name = "idx_created", columnList = "created_at")
})
public class AuditLog {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id")
    private Long userId;
    
    @Column(name = "entity_type", length = 100)
    private String entityType; // User, Event, Booking, etc.
    
    @Column(name = "entity_id")
    private Long entityId;
    
    @Column(name = "action", length = 50)
    private String action; // CREATE, UPDATE, DELETE, LOGIN, etc.
    
    @Column(name = "details", columnDefinition = "JSON")
    private String details; // JSON serialized details
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    public AuditLog(Long userId, String entityType, Long entityId, String action, String details) {
        this.userId = userId;
        this.entityType = entityType;
        this.entityId = entityId;
        this.action = action;
        this.details = details;
        this.createdAt = LocalDateTime.now();
    }
}
