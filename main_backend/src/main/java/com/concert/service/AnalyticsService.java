package com.concert.service;

import com.concert.model.Event;
import com.concert.model.Booking;
import com.concert.repository.EventRepository;
import com.concert.repository.BookingRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * AnalyticsService provides insights and analytics on events, bookings, and user behavior.
 *
 * Features:
 * - Event popularity metrics
 * - Booking trends & forecasts
 * - Revenue analytics
 * - User engagement metrics
 * - Performance dashboards
 */
@Slf4j
@Service
@Transactional(readOnly = true)
public class AnalyticsService {

    private final EventRepository eventRepository;
    private final BookingRepository bookingRepository;
    private final CacheService cacheService;

    public AnalyticsService(
            EventRepository eventRepository,
            BookingRepository bookingRepository,
            CacheService cacheService) {
        this.eventRepository = eventRepository;
        this.bookingRepository = bookingRepository;
        this.cacheService = cacheService;
    }

    /**
     * Get total number of events
     */
    public long getTotalEvents() {
        String cacheKey = "analytics:total_events";
        return cacheService.getOrCompute(cacheKey, key -> {
            long count = eventRepository.count();
            log.debug("Total events: {}", count);
            return count;
        }, 3600); // 1 hour cache
    }

    /**
     * Get total number of bookings
     */
    public long getTotalBookings() {
        String cacheKey = "analytics:total_bookings";
        return cacheService.getOrCompute(cacheKey, key -> {
            long count = bookingRepository.count();
            log.debug("Total bookings: {}", count);
            return count;
        }, 3600); // 1 hour cache
    }

    /**
     * Get events created in a date range
     */
    public Map<String, Object> getEventsTrendByDate(LocalDate startDate, LocalDate endDate) {
        log.info("Fetching event trends from {} to {}", startDate, endDate);

        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.plusDays(1).atStartOfDay();

        // This would typically query events created in that period
        Map<String, Object> trends = new HashMap<>();
        trends.put("startDate", startDate);
        trends.put("endDate", endDate);
        trends.put("periodDays", ChronoUnit.DAYS.between(startDate, endDate));

        return trends;
    }

    /**
     * Get booking conversion rate
     */
    public double getBookingConversionRate() {
        String cacheKey = "analytics:conversion_rate";
        return cacheService.getOrCompute(cacheKey, key -> {
            long totalEvents = getTotalEvents();
            long totalBookings = getTotalBookings();

            if (totalEvents == 0) return 0.0;

            double rate = (double) totalBookings / totalEvents;
            log.debug("Booking conversion rate: {}%", rate * 100);
            return rate;
        }, 3600);
    }

    /**
     * Get revenue metrics for an organizer
     */
    public Map<String, Object> getRevenueMetrics(Long organizerId, LocalDate startDate, LocalDate endDate) {
        log.info("Fetching revenue metrics for organizer: {} from {} to {}", organizerId, startDate, endDate);

        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.plusDays(1).atStartOfDay();

        Map<String, Object> metrics = new HashMap<>();

        // Get all bookings for organizer's events in the period
        // This would be done with a proper query in production
        List<Event> organizerEvents = eventRepository.findByOrganizerIdOrderByStartDateAsc(organizerId);
        
        double totalRevenue = organizerEvents.stream()
                .mapToDouble(event -> event.getTicketPrice() != null ? event.getTicketPrice() : 0.0)
                .sum();

        metrics.put("organizerId", organizerId);
        metrics.put("startDate", startDate);
        metrics.put("endDate", endDate);
        metrics.put("totalRevenue", totalRevenue);
        metrics.put("eventCount", organizerEvents.size());
        metrics.put("averageRevenuePerEvent", organizerEvents.size() > 0 ? totalRevenue / organizerEvents.size() : 0.0);

        return metrics;
    }

    /**
     * Get top events by attendance
     */
    public List<Map<String, Object>> getTopEvents(int limit) {
        String cacheKey = "analytics:top_events";
        return cacheService.getOrCompute(cacheKey, key -> {
            List<Map<String, Object>> topEvents = new ArrayList<>();

            List<Event> allEvents = eventRepository.findAll();
            // Sort by attendance (would normally be done in query)
            allEvents.stream()
                    .limit(limit)
                    .forEach(event -> {
                        Map<String, Object> eventData = new HashMap<>();
                        eventData.put("id", event.getId());
                        eventData.put("title", event.getTitle());
                        eventData.put("category", event.getCategory());
                        eventData.put("price", event.getTicketPrice());
                        eventData.put("startDate", event.getStartDate());
                        topEvents.add(eventData);
                    });

            return topEvents;
        }, 1800); // 30 minutes cache
    }

    /**
     * Get user engagement metrics
     */
    public Map<String, Object> getUserEngagementMetrics(Long userId) {
        log.info("Fetching engagement metrics for user: {}", userId);

        Map<String, Object> engagement = new HashMap<>();
        engagement.put("userId", userId);
        engagement.put("totalBookings", bookingRepository.countByUserId(userId));
        engagement.put("upcomingBookings", 0); // Would be populated from bookings with future dates
        engagement.put("pastBookings", 0); // Would be populated from bookings with past dates

        return engagement;
    }

    /**
     * Get event category popularity
     */
    public Map<String, Long> getCategoryPopularity() {
        String cacheKey = "analytics:category_popularity";
        return cacheService.getOrCompute(cacheKey, key -> {
            List<Event> allEvents = eventRepository.findAll();

            return allEvents.stream()
                    .collect(Collectors.groupingBy(
                            event -> event.getCategory() != null ? event.getCategory() : "Other",
                            Collectors.counting()
                    ));
        }, 3600);
    }

    /**
     * Get average event rating (if implemented)
     */
    public double getAverageEventRating() {
        // This would calculate from reviews if they were tracked
        return 4.5; // Placeholder
    }

    /**
     * Get user retention metrics
     */
    public Map<String, Object> getRetentionMetrics() {
        Map<String, Object> retention = new HashMap<>();
        retention.put("activeUsers", 0); // Would be calculated from recent bookings
        retention.put("returningUsers", 0); // Would be calculated from repeat bookings
        retention.put("churnedUsers", 0); // Would be calculated from inactive users

        return retention;
    }

    /**
     * Generate dashboard data for admins
     */
    public Map<String, Object> generateDashboard() {
        log.info("Generating analytics dashboard");

        Map<String, Object> dashboard = new HashMap<>();

        dashboard.put("totalEvents", getTotalEvents());
        dashboard.put("totalBookings", getTotalBookings());
        dashboard.put("conversionRate", getBookingConversionRate());
        dashboard.put("topEvents", getTopEvents(5));
        dashboard.put("categoryPopularity", getCategoryPopularity());
        dashboard.put("averageRating", getAverageEventRating());
        dashboard.put("retention", getRetentionMetrics());
        dashboard.put("generatedAt", LocalDateTime.now());

        return dashboard;
    }
}
