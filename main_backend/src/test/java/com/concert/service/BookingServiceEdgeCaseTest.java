package com.concert.service;

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

    @Test
    void cancelAllBookingsForEvent_cancelsEveryBookingOfTheEvent() {
        Booking first = new Booking();
        first.setStatus("CONFIRMED");
        Booking second = new Booking();
        second.setStatus("PENDING");
        List<Booking> bookings = List.of(first, second);
        when(bookingRepository.findByEventId("7")).thenReturn(bookings);

        bookingService.cancelAllBookingsForEvent("7");

        assertThat(bookings).extracting(Booking::getStatus).containsOnly("CANCELLED");
        verify(bookingRepository).saveAll(bookings);
    }

    @Test
    void cancelAllBookingsForEvent_withNoBookings_savesNothing() {
        when(bookingRepository.findByEventId("8")).thenReturn(List.of());

        bookingService.cancelAllBookingsForEvent("8");

        verify(bookingRepository).saveAll(List.of());
    }
}
