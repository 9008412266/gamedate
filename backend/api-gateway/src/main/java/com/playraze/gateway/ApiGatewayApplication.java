package com.playraze.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@SpringBootApplication
public class ApiGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }

    /**
     * Rate limit by user ID (from JWT) or IP for unauthenticated requests.
     */
    @Bean
    public KeyResolver userKeyResolver() {
        return exchange -> {
            String userId = exchange.getRequest().getHeaders().getFirst("X-User-Id");
            if (userId != null) return Mono.just(userId);
            String ip = exchange.getRequest().getRemoteAddress() != null
                    ? exchange.getRequest().getRemoteAddress().getAddress().getHostAddress()
                    : "unknown";
            return Mono.just("ip:" + ip);
        };
    }
}

/**
 * Fallback controller for circuit breaker responses.
 */
@RestController
class FallbackController {

    @GetMapping("/fallback/auth")
    public Mono<String> authFallback() {
        return Mono.just("{\"success\":false,\"error\":{\"code\":\"SERVICE_UNAVAILABLE\"," +
                "\"message\":\"Auth service is temporarily unavailable. Please try again.\"}}");
    }

    @GetMapping("/fallback/user")
    public Mono<String> userFallback() {
        return Mono.just("{\"success\":false,\"error\":{\"code\":\"SERVICE_UNAVAILABLE\"," +
                "\"message\":\"User service is temporarily unavailable.\"}}");
    }

    @GetMapping("/fallback/game")
    public Mono<String> gameFallback() {
        return Mono.just("{\"success\":false,\"error\":{\"code\":\"SERVICE_UNAVAILABLE\"," +
                "\"message\":\"Game service is temporarily unavailable.\"}}");
    }
}
