package com.playraze.auth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

/**
 * Async email service for verification and password reset emails.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.from:noreply@playraze.app}")
    private String fromEmail;

    @Value("${app.frontend-url:https://playraze.app}")
    private String frontendUrl;

    @Async
    public void sendVerificationEmail(String to, String username, String code) {
        String subject = "Verify your Playraze account";
        String html = """
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h1 style="color: #FF6B9D;">Welcome to Playraze! 🎮❤️</h1>
                  <p>Hi <strong>%s</strong>,</p>
                  <p>Your verification code is:</p>
                  <div style="background: #1a1a2e; color: #FF6B9D; font-size: 32px;
                              font-weight: bold; text-align: center; padding: 20px;
                              border-radius: 8px; letter-spacing: 8px;">%s</div>
                  <p>This code expires in <strong>15 minutes</strong>.</p>
                  <p>If you didn't create an account, please ignore this email.</p>
                  <hr/>
                  <p style="color: #888; font-size: 12px;">Playraze — Play Together, Connect Together</p>
                </div>
                """.formatted(username, code);

        sendEmail(to, subject, html);
    }

    @Async
    public void sendPasswordResetEmail(String to, String username, String token) {
        String resetLink = frontendUrl + "/reset-password?token=" + token;
        String subject = "Reset your Playraze password";
        String html = """
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h1 style="color: #FF6B9D;">Password Reset</h1>
                  <p>Hi <strong>%s</strong>,</p>
                  <p>Click the button below to reset your password. This link expires in 1 hour.</p>
                  <a href="%s" style="display: inline-block; background: #FF6B9D; color: white;
                     padding: 12px 24px; border-radius: 6px; text-decoration: none;
                     font-weight: bold;">Reset Password</a>
                  <p>If you didn't request a password reset, please ignore this email.</p>
                </div>
                """.formatted(username, resetLink);

        sendEmail(to, subject, html);
    }

    private void sendEmail(String to, String subject, String htmlBody) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromEmail);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlBody, true);
            mailSender.send(message);
            log.debug("Email sent to: {}", to);
        } catch (MessagingException e) {
            log.error("Failed to send email to {}: {}", to, e.getMessage());
        }
    }
}
