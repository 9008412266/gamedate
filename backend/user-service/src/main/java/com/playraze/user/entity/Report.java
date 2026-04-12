package com.playraze.user.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "reports", schema = "users")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "reporter_id", nullable = false)
    private UUID reporterId;

    @Column(name = "reported_id", nullable = false)
    private UUID reportedId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReportReason reason;

    @Column(length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private ReportStatus status = ReportStatus.PENDING;

    @CreationTimestamp
    private Instant createdAt;

    public enum ReportReason {
        SPAM, FAKE_PROFILE, HARASSMENT, INAPPROPRIATE_CONTENT,
        UNDERAGE, SCAM, OTHER
    }

    public enum ReportStatus {
        PENDING, REVIEWED, ACTIONED, DISMISSED
    }
}
