package com.concert.controller;

import com.concert.config.SecurityConfig;
import com.concert.dto.BookingResponse;
import com.concert.dto.CreateBookingRequest;
import com.concert.service.BookingService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * /api/bookings/** through the real security chain: every endpoint needs a token,
 * the booking owner comes from the token, and the request body is validated.
 */
@WebMvcTest(BookingController.class)
@Import(SecurityConfig.class)
class BookingControllerApiTest extends SecuredApiTestSupport {

    @MockitoBean
    private BookingService bookingService;

    private static BookingResponse booking(long id, String status) {
        BookingResponse response = new BookingResponse();
        response.setId(id);
        response.setEventId("7");
        response.setEventTitle("Jazz Night");
        response.setQuantity(2);
        response.setTotalPrice(50.0);
        response.setStatus(status);
        return response;
    }

    @Test
    void everyEndpoint_withoutToken_returns403() throws Exception {
        mockMvc.perform(post("/api/bookings").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"eventId\":\"7\",\"quantity\":1}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/bookings/me")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/bookings/my-bookings")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/bookings/5")).andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/bookings/5")).andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/bookings/event/7")).andExpect(status().isForbidden());

        verifyNoInteractions(bookingService);
    }

    @Test
    void createBooking_withToken_booksForTokenUser() throws Exception {
        when(bookingService.createBooking(eq("alice"), any(CreateBookingRequest.class)))
                .thenReturn(booking(5, "CONFIRMED"));

        mockMvc.perform(post("/api/bookings").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"eventId\":\"7\",\"quantity\":2,\"ticketPrice\":25.0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(5))
                .andExpect(jsonPath("$.status").value("CONFIRMED"));

        ArgumentCaptor<CreateBookingRequest> body = ArgumentCaptor.forClass(CreateBookingRequest.class);
        verify(bookingService).createBooking(eq("alice"), body.capture());
        assertThat(body.getValue().getEventId()).isEqualTo("7");
        assertThat(body.getValue().getQuantity()).isEqualTo(2);
    }

    @Test
    void createBooking_withInvalidBody_returns400() throws Exception {
        String[] invalidBodies = {
                "{\"quantity\":1}",                    // eventId missing
                "{\"eventId\":\"7\"}",                 // quantity missing
                "{\"eventId\":\"7\",\"quantity\":0}",  // quantity below 1
                "{\"eventId\":\"7\",\"quantity\":-3}"
        };
        for (String body : invalidBodies) {
            mockMvc.perform(post("/api/bookings").header("Authorization", bearer(TOKEN))
                            .contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isBadRequest());
        }

        verify(bookingService, never()).createBooking(any(), any());
    }

    @Test
    void myBookings_bothPaths_returnTokenUsersBookings() throws Exception {
        when(bookingService.getUserBookings("alice"))
                .thenReturn(List.of(booking(5, "CONFIRMED"), booking(6, "CANCELLED")));

        mockMvc.perform(get("/api/bookings/me").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
        mockMvc.perform(get("/api/bookings/my-bookings").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[1].status").value("CANCELLED"));
    }

    @Test
    void getBooking_withToken_checksOwnershipInService() throws Exception {
        when(bookingService.getBookingById(5L, "alice")).thenReturn(booking(5, "CONFIRMED"));

        mockMvc.perform(get("/api/bookings/5").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.eventTitle").value("Jazz Night"));
    }

    @Test
    void getBooking_ofAnotherUser_surfacesUnauthorizedAccess() {
        // No exception handler yet: a running server answers 500, not 403.
        when(bookingService.getBookingById(5L, "bob"))
                .thenThrow(new RuntimeException("Unauthorized access to booking"));

        assertThatThrownBy(() -> mockMvc.perform(get("/api/bookings/5").header("Authorization", bearer(OTHER_TOKEN))))
                .hasRootCauseMessage("Unauthorized access to booking");
    }

    @Test
    void cancelBooking_withToken_returns204() throws Exception {
        mockMvc.perform(delete("/api/bookings/5").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isNoContent());

        verify(bookingService).cancelBooking(5L, "alice");
    }

    @Test
    void cancelBooking_ofAnotherUser_surfacesUnauthorizedAccess() {
        doThrow(new RuntimeException("Unauthorized access to booking"))
                .when(bookingService).cancelBooking(5L, "bob");

        assertThatThrownBy(() -> mockMvc.perform(delete("/api/bookings/5").header("Authorization", bearer(OTHER_TOKEN))))
                .hasRootCauseMessage("Unauthorized access to booking");
    }

    @Test
    void cancelAllBookingsForEvent_withToken_returns204() throws Exception {
        // Note: the endpoint only requires a valid token; it does not check that the
        // caller organises the event.
        mockMvc.perform(delete("/api/bookings/event/7").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isNoContent());

        verify(bookingService).cancelAllBookingsForEvent("7");
    }
}
