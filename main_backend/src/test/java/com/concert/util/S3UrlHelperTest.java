package com.concert.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

class S3UrlHelperTest {

    private S3UrlHelper helper;

    @BeforeEach
    void setUp() {
        helper = new S3UrlHelper();
        ReflectionTestUtils.setField(helper, "bucketName", "photos-bucket");
        ReflectionTestUtils.setField(helper, "region", "ap-southeast-1");
    }

    @Test
    void getS3Url_buildsRegionalUrlAndStripsLeadingSlash() {
        assertThat(helper.getS3Url("events/1.png"))
                .isEqualTo("https://photos-bucket.s3.ap-southeast-1.amazonaws.com/events/1.png");
        assertThat(helper.getS3Url("/events/1.png"))
                .isEqualTo("https://photos-bucket.s3.ap-southeast-1.amazonaws.com/events/1.png");
    }

    @Test
    void getS3Url_keepsAbsoluteUrlsAndRejectsEmptyKeys() {
        assertThat(helper.getS3Url("https://cdn.example/a.png")).isEqualTo("https://cdn.example/a.png");
        assertThat(helper.getS3Url(null)).isNull();
        assertThat(helper.getS3Url("")).isNull();
    }

    @Test
    void eventAndAvatarUrls_useTheSameRules() {
        assertThat(helper.getEventPhotoUrl("events/1.png")).isEqualTo(helper.getS3Url("events/1.png"));
        assertThat(helper.getAvatarUrl("avatars/2.png")).isEqualTo(helper.getS3Url("avatars/2.png"));
    }
}
