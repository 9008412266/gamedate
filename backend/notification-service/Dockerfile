# ── Stage 1: Build ────────────────────────────────────────────
# Context must be: backend/  (not the service subdirectory)
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /workspace

# 1) Install common-lib (local dependency shared by all services)
COPY common-lib/pom.xml common-lib/pom.xml
COPY common-lib/src     common-lib/src
RUN mvn install -DskipTests -B -q -f common-lib/pom.xml

# 2) Pre-fetch service dependencies for layer caching
COPY notification-service/pom.xml service/pom.xml
RUN mvn dependency:go-offline -B -q -f service/pom.xml

# 3) Build the service JAR
COPY notification-service/src service/src
RUN mvn package -DskipTests -B -q -f service/pom.xml

# ── Stage 2: Runtime ──────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine AS runtime

RUN addgroup -S playraze && adduser -S playraze -G playraze
USER playraze

WORKDIR /app

COPY --from=builder --chown=playraze:playraze /workspace/service/target/*.jar app.jar

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+UseStringDeduplication -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8086

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3   CMD wget -q --spider http://localhost:8086/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
