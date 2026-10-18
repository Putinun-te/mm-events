package com.concert.controller;

import com.concert.config.SecurityConfig;
import com.concert.dto.CreateEventRequest;
import com.concert.dto.EventPhotoResponse;
import com.concert.dto.EventResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import com.concert.service.EventService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * /api/events/** through the real security chain: public reads, authenticated writes,
 * request validation and how service errors surface.
 */
@WebMvcTest(EventController.class)
@Import(SecurityConfig.class)
class EventControllerApiTest extends SecuredApiTestSupport {

    private static final String VALID_EVENT = """
            {"title":"Jazz Night","description":"Live jazz","location":"Main Hall",
             "startDate":"2030-05-01T19:00:00","endDate":"2030-05-01T22:00:00","ticketPrice":25.0}""";

    @MockitoBean
    private EventService eventService;

    @MockitoBean
    private UserRepository userRepository;

    private User alice;

    @BeforeEach
    void setUp() {
        alice = user(1L, "alice");
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(alice));
    }

    private static EventResponse event(long id, String title) {
        EventResponse response = new EventResponse();
        response.setId(id);
        response.setTitle(title);
        response.setStartDate(LocalDateTime.of(2030, 5, 1, 19, 0));
        response.setEndDate(LocalDateTime.of(2030, 5, 1, 22, 0));
        return response;
    }

    // --- public reads -------------------------------------------------------

    @Test
    void listEvents_isPublic_andPassesNoCurrentUser() throws Exception {
        when(eventService.getUpcomingEvents(any(Pageable.class), isNull()))
                .thenReturn(new PageImpl<>(List.of(event(1, "Jazz Night")), PageRequest.of(0, 12), 1));

        mockMvc.perform(get("/api/events"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Jazz Night")));

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(eventService).getUpcomingEvents(pageable.capture(), isNull());
        assertThat(pageable.getValue().getPageNumber()).isZero();
        assertThat(pageable.getValue().getPageSize()).isEqualTo(12);
    }

    @Test
    void listEventsJson_withTokenAndPaging_passesCurrentUserAndPage() throws Exception {
        when(eventService.getUpcomingEvents(any(Pageable.class), eq(alice)))
                .thenReturn(new PageImpl<>(List.of(), PageRequest.of(2, 5), 0));

        mockMvc.perform(get("/api/events/json").param("page", "2").param("size", "5")
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk());

        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        verify(eventService).getUpcomingEvents(pageable.capture(), eq(alice));
        assertThat(pageable.getValue().getPageNumber()).isEqualTo(2);
        assertThat(pageable.getValue().getPageSize()).isEqualTo(5);
    }

    @Test
    void getEvent_isPublic() throws Exception {
        when(eventService.getEvent(7L, null)).thenReturn(event(7, "Jazz Night"));

        mockMvc.perform(get("/api/events/7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(7))
                .andExpect(jsonPath("$.title").value("Jazz Night"));

        mockMvc.perform(get("/api/events/json/7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(7));
    }

    @Test
    void getEvent_whenMissing_surfacesEventNotFound() {
        // There is no @ControllerAdvice yet, so this becomes a 500 in a running server.
        when(eventService.getEvent(99L, null)).thenThrow(new IllegalArgumentException("Event not found"));

        assertThatThrownBy(() -> mockMvc.perform(get("/api/events/99")))
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("Event not found");
    }

    @Test
    void testEndpoints_respond() throws Exception {
        mockMvc.perform(get("/api/events/json/test")).andExpect(status().isOk());
        mockMvc.perform(post("/api/events/json/test").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk());
    }

    @Test
    void getEventPhoto_isPublic() throws Exception {
        when(eventService.getEventPhoto(7L))
                .thenReturn(new EventPhotoResponse("https://cdn.example/p.jpg", "events/7/p.jpg", "Photo retrieved successfully"));

        mockMvc.perform(get("/api/events/7/photo"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.photoUrl").value("https://cdn.example/p.jpg"));
    }

    // --- authentication required --------------------------------------------

    @Test
    void createEvent_withoutToken_returns403() throws Exception {
        mockMvc.perform(post("/api/events").contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT))
                .andExpect(status().isForbidden());

        verifyNoInteractions(eventService);
    }

    @Test
    void createEvent_withForgedToken_returns403() throws Exception {
        mockMvc.perform(post("/api/events").header("Authorization", bearer("forged-token"))
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT))
                .andExpect(status().isForbidden());

        verifyNoInteractions(eventService);
    }

    @Test
    void updateAndDelete_withoutToken_return403() throws Exception {
        mockMvc.perform(put("/api/events/7").contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/events/7"))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/events/7/photo/upload-url").param("filename", "a.jpg"))
                .andExpect(status().isForbidden());

        verifyNoInteractions(eventService);
    }

    @Test
    void myEvents_withoutToken_failsWithAuthenticationRequired() {
        // GET /api/events/** is public, so the controller itself rejects the anonymous call
        // (500 in a running server because there is no exception handler).
        assertThatThrownBy(() -> mockMvc.perform(get("/api/events/me")))
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("Authentication required");
    }

    // --- authenticated writes ------------------------------------------------

    @Test
    void createEvent_withToken_passesOrganizerAndBody() throws Exception {
        when(eventService.createEvent(eq(alice), any(CreateEventRequest.class))).thenReturn(event(10, "Jazz Night"));

        mockMvc.perform(post("/api/events").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(10));

        ArgumentCaptor<CreateEventRequest> body = ArgumentCaptor.forClass(CreateEventRequest.class);
        verify(eventService).createEvent(eq(alice), body.capture());
        assertThat(body.getValue().getTitle()).isEqualTo("Jazz Night");
        assertThat(body.getValue().getStartDate()).isEqualTo(LocalDateTime.of(2030, 5, 1, 19, 0));
        assertThat(body.getValue().getTicketPrice()).isEqualTo(25.0);
    }

    @Test
    void createEventJson_withToken_usesSameHandler() throws Exception {
        when(eventService.createEvent(eq(alice), any(CreateEventRequest.class))).thenReturn(event(11, "Jazz Night"));

        mockMvc.perform(post("/api/events/json").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(11));
    }

    @Test
    void createEvent_withoutTitleOrDates_returns400() throws Exception {
        mockMvc.perform(post("/api/events").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"  \",\"startDate\":\"2030-05-01T19:00:00\",\"endDate\":\"2030-05-01T22:00:00\"}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/events").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Jazz Night\"}"))
                .andExpect(status().isBadRequest());

        verify(eventService, never()).createEvent(any(), any());
    }

    @Test
    void createEvent_withTokenOfUnknownUser_failsWithUserNotFound() {
        when(userRepository.findByUsername("bob")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> mockMvc.perform(post("/api/events").header("Authorization", bearer(OTHER_TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT)))
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("User not found");
        verifyNoInteractions(eventService);
    }

    @Test
    void myEvents_withToken_returnsOrganizerEvents() throws Exception {
        when(eventService.getEventsForOrganizer(alice)).thenReturn(List.of(event(1, "A"), event(2, "B")));

        mockMvc.perform(get("/api/events/me").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
        mockMvc.perform(get("/api/events/json/me").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[1].title").value("B"));
    }

    @Test
    void updateEvent_withToken_passesIdOrganizerAndBody() throws Exception {
        when(eventService.updateEvent(eq(7L), eq(alice), any(CreateEventRequest.class))).thenReturn(event(7, "Jazz Night"));

        mockMvc.perform(put("/api/events/7").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT))
                .andExpect(status().isOk());
        mockMvc.perform(put("/api/events/json/7").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Jazz Night"));
    }

    @Test
    void updateEvent_byNonOrganizer_surfacesServiceRejection() {
        when(eventService.updateEvent(eq(7L), eq(alice), any(CreateEventRequest.class)))
                .thenThrow(new IllegalArgumentException("Only event organizer can update this event"));

        assertThatThrownBy(() -> mockMvc.perform(put("/api/events/7").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content(VALID_EVENT)))
                .hasRootCauseInstanceOf(IllegalArgumentException.class)
                .hasRootCauseMessage("Only event organizer can update this event");
    }

    @Test
    void deleteEvent_withToken_returns204() throws Exception {
        mockMvc.perform(delete("/api/events/7").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isNoContent());
        mockMvc.perform(delete("/api/events/json/8").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isNoContent());

        verify(eventService).deleteEvent(7L, alice);
        verify(eventService).deleteEvent(8L, alice);
    }

    @Test
    void photoUploadFlow_withToken_returnsUploadUrlThenConfirms() throws Exception {
        when(eventService.generateUploadUrl(7L, alice, "poster.jpg"))
                .thenReturn(new EventPhotoResponse(null, "events/7/poster.jpg", "Upload URL generated", "https://s3.example/put"));
        when(eventService.setEventPhotoByFilename(7L, alice, "poster.jpg"))
                .thenReturn(new EventPhotoResponse("https://s3.example/events/7/poster.jpg", "events/7/poster.jpg", "Photo set successfully"));

        mockMvc.perform(post("/api/events/7/photo/upload-url").param("filename", "poster.jpg")
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.uploadUrl").value("https://s3.example/put"));
        mockMvc.perform(post("/api/events/7/photo").param("filename", "poster.jpg")
                        .header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.photoId").value("events/7/poster.jpg"));
    }
}
