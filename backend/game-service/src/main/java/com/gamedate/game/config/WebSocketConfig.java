package com.gamedate.game.config;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * STOMP WebSocket configuration.
 *
 * Clients connect to /ws endpoint, then:
 * - Subscribe to /topic/game/{roomId} for game state broadcasts
 * - Send actions to /app/game/{roomId}/action
 * - Receive personal errors on /user/queue/game-error
 */
@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Value("${app.cors.allowed-origins:*}")
    private String allowedOrigins;

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns(allowedOrigins)
                .withSockJS(); // SockJS fallback for environments that don't support WebSocket

        // Native WebSocket endpoint (for Flutter which uses native WebSocket)
        registry.addEndpoint("/ws-native")
                .setAllowedOriginPatterns(allowedOrigins);
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Prefix for messages routed to @MessageMapping methods
        config.setApplicationDestinationPrefixes("/app");

        // Enable in-memory broker for /topic (broadcast) and /user (personal)
        // In production, replace with Redis message broker for horizontal scaling:
        // config.enableStompBrokerRelay("/topic", "/queue")
        //       .setRelayHost(redisHost).setRelayPort(61613);
        config.enableSimpleBroker("/topic", "/queue");

        // Prefix for personal messages
        config.setUserDestinationPrefix("/user");
    }
}
