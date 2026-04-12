FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY mvnw . 
COPY .mvn .mvn
COPY pom.xml .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine AS runtime
RUN addgroup -S gamedate && adduser -S gamedate -G gamedate
USER gamedate
WORKDIR /app
COPY --from=builder --chown=gamedate:gamedate /app/target/*.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 CMD wget -q --spider http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
