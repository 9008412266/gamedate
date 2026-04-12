package com.playraze.notification.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Push notification service using Firebase Cloud Messaging (FCM).
 * Supports individual notifications and batch (multicast) delivery.
 */
@Slf4j
@Service
public class NotificationService {

    @Value("${firebase.config-path:firebase-service-account.json}")
    private String firebaseConfigPath;

    @PostConstruct
    public void initialize() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                GoogleCredentials credentials = GoogleCredentials.fromStream(
                        new ClassPathResource(firebaseConfigPath).getInputStream());
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(credentials)
                        .build();
                FirebaseApp.initializeApp(options);
                log.info("Firebase initialized successfully");
            }
        } catch (IOException e) {
            log.warn("Firebase config not found — push notifications disabled: {}", e.getMessage());
        }
    }

    /**
     * Send push notification to a single device.
     */
    public void sendToDevice(String fcmToken, String title, String body,
                              Map<String, String> data) {
        try {
            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data != null ? data : Map.of())
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder()
                                    .setSound("default")
                                    .setBadge(1)
                                    .build())
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.debug("FCM notification sent: {}", response);
        } catch (FirebaseMessagingException e) {
            log.error("Failed to send FCM notification: {}", e.getMessage());
        }
    }

    /**
     * Send to multiple devices (batch).
     */
    public void sendToMultipleDevices(List<String> fcmTokens, String title,
                                       String body, Map<String, String> data) {
        if (fcmTokens.isEmpty()) return;

        try {
            MulticastMessage message = MulticastMessage.builder()
                    .addAllTokens(fcmTokens)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putAllData(data != null ? data : Map.of())
                    .build();

            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            log.info("Multicast: {}/{} sent successfully",
                    response.getSuccessCount(), fcmTokens.size());
        } catch (FirebaseMessagingException e) {
            log.error("Failed to send multicast notification: {}", e.getMessage());
        }
    }

    // ── Notification type helpers ────────────────────────────

    public void sendMatchNotification(String fcmToken, String matchedUserName) {
        sendToDevice(fcmToken,
                "It's a Match! 🎉",
                "You matched with " + matchedUserName + "! Start chatting!",
                Map.of("type", "MATCH", "action", "open_matches"));
    }

    public void sendNewMessageNotification(String fcmToken, String senderName, String preview) {
        sendToDevice(fcmToken,
                "New message from " + senderName,
                preview,
                Map.of("type", "MESSAGE", "action", "open_chat"));
    }

    public void sendGameInviteNotification(String fcmToken, String inviterName, String gameType) {
        sendToDevice(fcmToken,
                gameType + " Challenge! 🎮",
                inviterName + " challenged you to a game of " + gameType + "!",
                Map.of("type", "GAME_INVITE", "gameType", gameType));
    }

    public void sendDailyRewardNotification(String fcmToken, int streak, long coins) {
        sendToDevice(fcmToken,
                "Daily Reward Available! 🎁",
                "Day " + streak + " streak! Claim your " + coins + " coins now!",
                Map.of("type", "DAILY_REWARD", "action", "open_wallet"));
    }
}
