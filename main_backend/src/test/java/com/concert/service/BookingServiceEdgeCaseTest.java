package com.concert.service;

import com.concert.repository.EventRepository;
import com.concert.model.Event;
import com.concert.exception.NotFoundException;
import com.concert.exception.ForbiddenException;
import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.model.Booking;
import com.concert.model.User;
import com.concert.repository.BookingRepository;
import com.concert.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * BookingService input rules and defaults not covered by BookingServiceTest.
 */
@ExtendWith(MockitoExtension.class)
class BookingServiceEdgeCaseTest {

    @Mock
    private BookingRepository bookingRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private EventRepository eventRepository;
    @InjectMocks
    private BookingService bookingService;

    private static CreateBookingRequest request(String eventId, Integer quantity) {
        CreateBookingRequest request = new CreateBookingRequest();
        request.setEventId(eventId);
        request.setQuantity(quantity);
        return request;
    }

    @Test
    void createBooking_withoutEventIdOrValidQuantity_isRejectedBeforeAnyLookup() {
        for (CreateBookingRequest invalid : List.of(request(null, 1), request("7", null), request("7", 0), request("7", -1))) {
            assertThatThrownBy(() -> bookingService.createBooking("alice", invalid))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessage("Event ID and valid quantity are required");
        }
        verifyNoInteractions(userRepository, bookingRepository);
    }

    @Test
    void createBooking_withMinimalRequest_fillsDefaults() {
        User alice = new User();
        alice.setId(1L);
        alice.setUsername("alice");
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(alice));
        when(bookingRepository.save(any(Booking.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BookingResponse response = bookingService.createBooking("alice", request("7", 3));

        ArgumentCaptor<Booking> saved = ArgumentCaptor.forClass(Booking.class);
        verify(bookingRepository).save(saved.capture());
        assertThat(saved.getValue().getUser()).isSameAs(alice);
        assertThat(saved.getValue().getEventTitle()).isEqualTo("Event");
        assertThat(saved.getValue().getEventLocation()).isEqualTo("TBA");
        assertThat(saved.getValue().getTotalPrice()).isZero();
        assertThat(saved.getValue().getStatus()).isEqualTo("CONFIRMED");
        assertThat(saved.getValue().getBookingDate()).isNotNull();
        assertThat(response.getQuantity()).isEqualTo(3);
        assertThat(response.getEventLocation()).isEqualTo("TBA");
    }

    private Event eventOrganizedBy(String username) {
        User organizer = new User();
        organizer.setId(9L);
        organizer.setUsername(username);
        Event event = new Event();
        event.setId(7L);
        event.setOrganizer(organizer);
        return event;
    }

    @Test
    void cancelAllBookingsForEvent_byOrganizer_cancelsEveryBookingOfTheEvent() {
        when(eventRepository.findById(7L)).thenReturn(Optional.of(eventOrganizedBy("alice")));
        Booking first = new Booking();
        first.setStatus("CONFIRMED");
        Booking second = new Booking();
        second.setStatus("PENDING");
        List<Booking> bookings = List.of(first, second);
        when(bookingRepository.findByEventId("7")).thenReturn(bookings);

        bookingService.cancelAllBookingsForEvent("7", "alice");

        assertThat(bookings).extracting(Booking::getStatus).containsOnly("CANCELLED");
        verify(bookingRepository).saveAll(bookings);
    }

    @Test
    void cancelAllBookingsForEvent_byAnotherUser_isForbiddenAndChangesNothing() {
        when(eventRepository.findById(7L)).thenReturn(Optional.of(eventOrganizedBy("alice")));

        assertThatThrownBy(() -> bookingService.cancelAllBookingsForEvent("7", "mallory"))
                .isInstanceOf(ForbiddenException.class)
                .hasMessage("Only the event organizer can cancel all bookings");
        verifyNoInteractions(bookingRepository);
    }

    @Test
    void cancelAllBookingsForEvent_forUnknownOrInvalidEventId_isNotFound() {
        when(eventRepository.findById(8L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.cancelAllBookingsForEvent("8", "alice"))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Event not found");
        assertThatThrownBy(() -> bookingService.cancelAllBookingsForEvent("not-a-number", "alice"))
                .isInstanceOf(NotFoundException.class);
        verifyNoInteractions(bookingRepository);
    }
}
