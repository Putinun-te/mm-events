package com.concert.repository;

import com.concert.model.Booking;
import com.concert.model.Event;
import com.concert.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Event, booking and user queries on a real MySQL 8.0 (same major version as
 * docker-compose.yml). Every test runs in a transaction that is rolled back, and all
 * timestamps are fixed values, so results do not depend on the current date.
 */
@DataJpaTest(properties = {
        "spring.jpa.hibernate.ddl-auto=validate", // schema from the Flyway migrations
        "spring.jpa.show-sql=false"
})
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class EventBookingRepositoryIT {

    @Container
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.0");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MYSQL::getJdbcUrl);
        registry.add("spring.datasource.username", MYSQL::getUsername);
        registry.add("spring.datasource.password", MYSQL::getPassword);
    }

    private static final LocalDateTime NOW = LocalDateTime.of(2030, 6, 1, 0, 0);

    @Autowired
    private TestEntityManager entityManager;
    @Autowired
    private EventRepository eventRepository;
    @Autowired
    private BookingRepository bookingRepository;
    @Autowired
    private UserRepository userRepository;

    private User alice;
    private User bob;
    private Event finished;
    private Event ongoing;
    private Event upcoming;
    private Event bobsEvent;

    @BeforeEach
    void setUp() {
        alice = entityManager.persist(user("alice"));
        bob = entityManager.persist(user("bob"));
        finished = entityManager.persist(event("Rock Classics", alice, NOW.minusDays(31), NOW.minusDays(31).plusHours(3)));
        ongoing = entityManager.persist(event("Jazz Festival", alice, NOW.minusDays(1), NOW.plusDays(1)));
        upcoming = entityManager.persist(event("Jazz Night", alice, NOW.plusDays(30), NOW.plusDays(30).plusHours(3)));
        bobsEvent = entityManager.persist(event("Indie Live", bob, NOW.plusDays(10), NOW.plusDays(10).plusHours(2)));
        entityManager.flush();
    }

    private static User user(String username) {
        User user = new User();
        user.setUsername(username);
        user.setName(username);
        user.setEmail(username + "@example.com");
        user.setPassword("$2a$10$hash-not-used");
        return user;
    }

    private static Event event(String title, User organizer, LocalDateTime start, LocalDateTime end) {
        Event event = new Event();
        event.setTitle(title);
        event.setStartDate(start);
        event.setEndDate(end);
        event.setOrganizer(organizer);
        return event;
    }

    private Booking booking(User user, Event event, String status, LocalDateTime bookedAt) {
        Booking booking = new Booking();
        booking.setUser(user);
        booking.setEventId(String.valueOf(event.getId()));
        booking.setEventTitle(event.getTitle());
        booking.setQuantity(2);
        booking.setTotalPrice(50.0);
        booking.setStatus(status);
        booking.setBookingDate(bookedAt);
        return entityManager.persist(booking);
    }

    @Test
    void upcomingEvents_excludeFinishedOnes_andAreOrderedByStartDate() {
        Page<Event> page = eventRepository.findByEndDateAfterOrderByStartDateAsc(NOW, PageRequest.of(0, 10));

        assertThat(page.getContent()).extracting(Event::getTitle)
                .containsExactly("Jazz Festival", "Indie Live", "Jazz Night");
        assertThat(page.getTotalElements()).isEqualTo(3);
    }

    @Test
    void upcomingEvents_arePaged() {
        Page<Event> second = eventRepository.findByEndDateAfterOrderByStartDateAsc(NOW, PageRequest.of(1, 2));

        assertThat(second.getContent()).extracting(Event::getTitle).containsExactly("Jazz Night");
        assertThat(second.getTotalPages()).isEqualTo(2);
    }

    @Test
    void eventsStartingAfter_excludeEventsAlreadyRunning() {
        Page<Event> page = eventRepository.findByStartDateAfterOrderByStartDateAsc(NOW, PageRequest.of(0, 10));

        assertThat(page.getContent()).extracting(Event::getTitle).containsExactly("Indie Live", "Jazz Night");
    }

    @Test
    void organizerEvents_onlyContainThatOrganizer_inStartOrder() {
        assertThat(eventRepository.findByOrganizerOrderByStartDateAsc(alice))
                .extracting(Event::getTitle)
                .containsExactly("Rock Classics", "Jazz Festival", "Jazz Night");
        assertThat(eventRepository.findByOrganizerOrderByStartDateAsc(bob))
                .containsExactly(bobsEvent);
    }

    @Test
    void titleSearch_matchesSubstring() {
        assertThat(eventRepository.findByTitleContaining("Jazz"))
                .extracting(Event::getTitle)
                .containsExactlyInAnyOrder("Jazz Festival", "Jazz Night");
    }

    @Test
    void persistedEvent_getsLegacyNameAndOrganizerId() {
        Event reloaded = entityManager.find(Event.class, upcoming.getId());

        assertThat(reloaded.getLegacyName()).isEqualTo("Jazz Night");
        assertThat(reloaded.getOrganizerId()).isEqualTo(alice.getId());
    }

    @Test
    void userBookings_newestFirst() {
        booking(alice, upcoming, "CONFIRMED", NOW.minusDays(3));
        booking(alice, ongoing, "CANCELLED", NOW.minusDays(1));
        booking(alice, bobsEvent, "CONFIRMED", NOW.minusDays(2));
        booking(bob, upcoming, "CONFIRMED", NOW);
        entityManager.flush();

        List<Booking> bookings = bookingRepository.findByUserIdOrderByBookingDateDesc(alice.getId());

        assertThat(bookings).extracting(Booking::getBookingDate)
                .containsExactly(NOW.minusDays(1), NOW.minusDays(2), NOW.minusDays(3));
    }

    @Test
    void eventBookings_canBeFilteredByStatus() {
        booking(alice, upcoming, "CONFIRMED", NOW.minusDays(3));
        booking(bob, upcoming, "CANCELLED", NOW.minusDays(2));
        booking(bob, upcoming, "CONFIRMED", NOW.minusDays(1));
        booking(alice, ongoing, "CONFIRMED", NOW.minusDays(1));
        entityManager.flush();
        String eventId = String.valueOf(upcoming.getId());

        assertThat(bookingRepository.findByEventId(eventId)).hasSize(3);
        assertThat(bookingRepository.findByEventIdAndStatus(eventId, "CONFIRMED"))
                .extracting(b -> b.getUser().getUsername())
                .containsExactlyInAnyOrder("alice", "bob");
        assertThat(bookingRepository.findByEventIdAndStatus(eventId, "PENDING")).isEmpty();
    }

    @Test
    void newBooking_withoutStatusOrDate_defaultsToPendingNow() {
        Booking booking = new Booking();
        booking.setUser(alice);
        booking.setEventId(String.valueOf(upcoming.getId()));
        booking.setQuantity(1);
        booking.setTotalPrice(25.0);

        Booking saved = bookingRepository.saveAndFlush(booking);

        assertThat(saved.getStatus()).isEqualTo("PENDING");
        assertThat(saved.getBookingDate()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
    }

    @Test
    void usersCanBeFoundByUsernameOrEmail() {
        assertThat(userRepository.findByUsernameOrEmail("alice", "alice")).contains(alice);
        assertThat(userRepository.findByUsernameOrEmail("bob@example.com", "bob@example.com")).contains(bob);
        assertThat(userRepository.existsByEmail("alice@example.com")).isTrue();
        assertThat(userRepository.existsByUsername("carol")).isFalse();
    }

    @Test
    void duplicateUsernameOrEmail_isRejectedByTheDatabase() {
        User sameUsername = user("alice");
        sameUsername.setEmail("other@example.com");
        assertThatThrownBy(() -> userRepository.saveAndFlush(sameUsername))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void duplicateEmail_isRejectedByTheDatabase() {
        User sameEmail = user("carol");
        sameEmail.setEmail("bob@example.com");
        assertThatThrownBy(() -> userRepository.saveAndFlush(sameEmail))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
