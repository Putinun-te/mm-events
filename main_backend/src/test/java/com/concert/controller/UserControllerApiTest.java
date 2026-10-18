package com.concert.controller;

import com.concert.config.SecurityConfig;
import com.concert.dto.UserProfileResponse;
import com.concert.model.User;
import com.concert.repository.UserRepository;
import com.concert.service.UserProfileService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * /api/users/** through the real security chain: token required, profile reads/updates
 * for the token user, and profile photo upload error mapping.
 */
@WebMvcTest(UserController.class)
@Import(SecurityConfig.class)
class UserControllerApiTest extends SecuredApiTestSupport {

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private UserProfileService userProfileService;

    private User alice;

    @BeforeEach
    void setUp() {
        alice = user(1L, "alice");
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(alice));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userProfileService.buildResponse(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            UserProfileResponse response = new UserProfileResponse();
            response.setId(user.getId());
            response.setUsername(user.getUsername());
            response.setName(user.getName());
            response.setPhone(user.getPhone());
            response.setCity(user.getCity());
            return response;
        });
    }

    @Test
    void everyEndpoint_withoutToken_returns403() throws Exception {
        mockMvc.perform(get("/api/users")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/users/me")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/users/profile")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/users/1")).andExpect(status().isForbidden());
        mockMvc.perform(put("/api/users/profile").contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(multipart("/api/users/me/photo")
                        .file(new MockMultipartFile("file", "a.png", "image/png", new byte[]{1})))
                .andExpect(status().isForbidden());

        verifyNoInteractions(userProfileService);
    }

    @Test
    void me_andProfile_returnTokenUsersProfile() throws Exception {
        mockMvc.perform(get("/api/users/me").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("alice"));
        mockMvc.perform(get("/api/users/profile").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1));
    }

    @Test
    void me_whenTokenUserNoLongerExists_returns500WithMessage() throws Exception {
        when(userRepository.findByUsername("bob")).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/users/me").header("Authorization", bearer(OTHER_TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(content().string("User not found"));
    }

    @Test
    void getUserById_whenMissing_returns404() throws Exception {
        when(userRepository.findById(42L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/users/42").header("Authorization", bearer(TOKEN)))
                .andExpect(status().isNotFound());
    }

    @Test
    void updateProfile_trimsValues_joinsNames_andIgnoresBlankFields() throws Exception {
        alice.setCity("Bangkok");

        mockMvc.perform(put("/api/users/profile").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\" Alice \",\"lastName\":\" Smith \",\"phone\":\" 0812345678 \",\"city\":\"   \"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Alice Smith"))
                .andExpect(jsonPath("$.phone").value("0812345678"))
                .andExpect(jsonPath("$.city").value("Bangkok"));

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(saved.capture());
        assertThat(saved.getValue().getName()).isEqualTo("Alice Smith");
        assertThat(saved.getValue().getPhone()).isEqualTo("0812345678");
        assertThat(saved.getValue().getCity()).isEqualTo("Bangkok");
    }

    @Test
    void updateProfile_withOnlyFirstName_setsNameWithoutTrailingSpace() throws Exception {
        mockMvc.perform(put("/api/users/profile").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"firstName\":\"Alice\",\"company\":\"MM Events\",\"website\":\"https://mm.example\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Alice"));

        assertThat(alice.getCompany()).isEqualTo("MM Events");
        assertThat(alice.getWebsite()).isEqualTo("https://mm.example");
    }

    @Test
    void updateProfile_whenTokenUserMissing_returns404() throws Exception {
        when(userRepository.findByUsername("bob")).thenReturn(Optional.empty());

        mockMvc.perform(put("/api/users/profile").header("Authorization", bearer(OTHER_TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"phone\":\"1\"}"))
                .andExpect(status().isNotFound());

        verify(userRepository, never()).save(any());
    }

    @Test
    void updateProfile_whenSaveFails_returns500WithMessage() throws Exception {
        when(userRepository.save(any(User.class))).thenThrow(new RuntimeException("db down"));

        mockMvc.perform(put("/api/users/profile").header("Authorization", bearer(TOKEN))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"phone\":\"1\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(content().string("Error updating profile: db down"));
    }

    @Test
    void uploadProfilePhoto_withToken_returnsUpdatedProfile() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "me.png", "image/png", new byte[]{1, 2, 3});
        UserProfileResponse response = new UserProfileResponse();
        response.setUsername("alice");
        response.setProfilePhoto("https://cdn.example/users/1/avatar.png");
        when(userProfileService.uploadProfilePhoto(eq(alice), any())).thenReturn(response);

        mockMvc.perform(multipart("/api/users/me/photo").file(file).header("Authorization", bearer(TOKEN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profilePhoto").value("https://cdn.example/users/1/avatar.png"));
    }

    @Test
    void uploadProfilePhoto_withInvalidFile_returns400() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "me.png", "image/png", new byte[0]);
        when(userProfileService.uploadProfilePhoto(eq(alice), any()))
                .thenThrow(new IllegalArgumentException("Profile photo file is required"));

        mockMvc.perform(multipart("/api/users/me/photo").file(file).header("Authorization", bearer(TOKEN)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string("Profile photo file is required"));
    }

    @Test
    void uploadProfilePhoto_whenStorageFails_returns500() throws Exception {
        MockMultipartFile file = new MockMultipartFile("file", "me.png", "image/png", new byte[]{1});
        when(userProfileService.uploadProfilePhoto(eq(alice), any()))
                .thenThrow(new IllegalStateException("User avatars bucket is not configured"));

        mockMvc.perform(multipart("/api/users/me/photo").file(file).header("Authorization", bearer(TOKEN)))
                .andExpect(status().isInternalServerError())
                .andExpect(content().string("User avatars bucket is not configured"));
    }
}
