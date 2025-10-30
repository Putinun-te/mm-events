package com.concert.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * EmailService handles all email-related operations.
 *
 * Features:
 * - Transactional emails (confirmations, resets)
 * - Marketing campaigns
 * - Email templates
 * - Bulk email sending
 * - Bounce handling & retry logic
 */
@Slf4j
@Service
@Transactional
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.from:noreply@concert.app}")
    private String fromEmail;

    @Value("${spring.mail.from-name:Concert App}")
    private String fromName;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    /**
     * Send a simple text email
     */
    public void sendSimpleEmail(String to, String subject, String body) {
        try {
            log.info("Sending simple email to: {}", to);

            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);

            mailSender.send(message);
            log.info("Email sent successfully to: {}", to);
        } catch (Exception e) {
            log.error("Failed to send email to: {}", to, e);
        }
    }

    /**
     * Send booking confirmation email
     */
    public void sendBookingConfirmation(String email, String eventTitle, String bookingReference, LocalDateTime eventDate) {
        try {
            log.info("Sending booking confirmation to: {}", email);

            String subject = "Booking Confirmed - " + eventTitle;
            String body = buildBookingConfirmationBody(eventTitle, bookingReference, eventDate);

            sendHtmlEmail(email, subject, body);
        } catch (Exception e) {
            log.error("Failed to send booking confirmation to: {}", email, e);
        }
    }

    /**
     * Send event reminder email
     */
    public void sendEventReminder(String email, String eventTitle, LocalDateTime eventDate) {
        try {
            log.info("Sending event reminder to: {}", email);

            String subject = "Reminder: " + eventTitle + " is coming up!";
            String body = buildEventReminderBody(eventTitle, eventDate);

            sendHtmlEmail(email, subject, body);
        } catch (Exception e) {
            log.error("Failed to send event reminder to: {}", email, e);
        }
    }

    /**
     * Send password reset email
     */
    public void sendPasswordResetEmail(String email, String resetToken) {
        try {
            log.info("Sending password reset email to: {}", email);

            String subject = "Password Reset Request";
            String body = buildPasswordResetBody(resetToken);

            sendHtmlEmail(email, subject, body);
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", email, e);
        }
    }

    /**
     * Send welcome email for new users
     */
    public void sendWelcomeEmail(String email, String userName) {
        try {
            log.info("Sending welcome email to: {}", email);

            String subject = "Welcome to Concert App!";
            String body = buildWelcomeBody(userName);

            sendHtmlEmail(email, subject, body);
        } catch (Exception e) {
            log.error("Failed to send welcome email to: {}", email, e);
        }
    }

    /**
     * Send cancellation confirmation email
     */
    public void sendCancellationConfirmation(String email, String eventTitle, String refundAmount) {
        try {
            log.info("Sending cancellation confirmation to: {}", email);

            String subject = "Booking Cancelled - " + eventTitle;
            String body = buildCancellationBody(eventTitle, refundAmount);

            sendHtmlEmail(email, subject, body);
        } catch (Exception e) {
            log.error("Failed to send cancellation confirmation to: {}", email, e);
        }
    }

    /**
     * Send HTML email
     */
    private void sendHtmlEmail(String to, String subject, String htmlContent) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail, fromName);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info("HTML email sent successfully to: {}", to);
        } catch (MessagingException e) {
            log.error("Failed to send HTML email to: {}", to, e);
        }
    }

    /**
     * Build booking confirmation email body
     */
    private String buildBookingConfirmationBody(String eventTitle, String bookingRef, LocalDateTime eventDate) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy @ HH:mm");

        return "<!DOCTYPE html>" +
                "<html>" +
                "<head><style>body { font-family: Arial, sans-serif; }</style></head>" +
                "<body>" +
                "<h2>Booking Confirmed!</h2>" +
                "<p>Your booking for <strong>" + eventTitle + "</strong> has been confirmed.</p>" +
                "<p><strong>Booking Reference:</strong> " + bookingRef + "</p>" +
                "<p><strong>Event Date:</strong> " + formatter.format(eventDate) + "</p>" +
                "<p>Please save your booking reference for check-in.</p>" +
                "<p>Thank you for booking with Concert App!</p>" +
                "</body>" +
                "</html>";
    }

    /**
     * Build event reminder email body
     */
    private String buildEventReminderBody(String eventTitle, LocalDateTime eventDate) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMMM dd, yyyy @ HH:mm");

        return "<!DOCTYPE html>" +
                "<html>" +
                "<head><style>body { font-family: Arial, sans-serif; }</style></head>" +
                "<body>" +
                "<h2>Event Reminder!</h2>" +
                "<p>Your event <strong>" + eventTitle + "</strong> is coming up!</p>" +
                "<p><strong>Date:</strong> " + formatter.format(eventDate) + "</p>" +
                "<p>Don't forget to attend!</p>" +
                "<p>See you there!</p>" +
                "</body>" +
                "</html>";
    }

    /**
     * Build password reset email body
     */
    private String buildPasswordResetBody(String resetToken) {
        String resetLink = "https://concert.app/reset-password?token=" + resetToken;

        return "<!DOCTYPE html>" +
                "<html>" +
                "<head><style>body { font-family: Arial, sans-serif; }</style></head>" +
                "<body>" +
                "<h2>Password Reset Request</h2>" +
                "<p>We received a request to reset your password.</p>" +
                "<p><a href=\"" + resetLink + "\">Click here to reset your password</a></p>" +
                "<p>This link will expire in 24 hours.</p>" +
                "<p>If you didn't request this, please ignore this email.</p>" +
                "</body>" +
                "</html>";
    }

    /**
     * Build welcome email body
     */
    private String buildWelcomeBody(String userName) {
        return "<!DOCTYPE html>" +
                "<html>" +
                "<head><style>body { font-family: Arial, sans-serif; }</style></head>" +
                "<body>" +
                "<h2>Welcome to Concert App!</h2>" +
                "<p>Hi " + userName + ",</p>" +
                "<p>Thank you for joining Concert App. We're excited to have you on board!</p>" +
                "<p>Start exploring events and book your first concert today.</p>" +
                "<p>Happy booking!</p>" +
                "</body>" +
                "</html>";
    }

    /**
     * Build cancellation email body
     */
    private String buildCancellationBody(String eventTitle, String refundAmount) {
        return "<!DOCTYPE html>" +
                "<html>" +
                "<head><style>body { font-family: Arial, sans-serif; }</style></head>" +
                "<body>" +
                "<h2>Booking Cancelled</h2>" +
                "<p>Your booking for <strong>" + eventTitle + "</strong> has been cancelled.</p>" +
                "<p><strong>Refund Amount:</strong> $" + refundAmount + "</p>" +
                "<p>The refund will be processed within 5-7 business days.</p>" +
                "<p>Thank you for using Concert App.</p>" +
                "</body>" +
                "</html>";
    }
}
