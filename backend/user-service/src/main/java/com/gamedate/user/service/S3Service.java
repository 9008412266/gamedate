package com.gamedate.user.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.util.Set;
import java.util.UUID;

/**
 * AWS S3 integration for user media (profile photos, game screenshots).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    @Value("${aws.cloudfront.domain}")
    private String cloudfrontDomain;

    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
    private static final Set<String> ALLOWED_TYPES = Set.of(
            "image/jpeg", "image/png", "image/webp");

    /**
     * Upload a user's profile photo.
     * Returns the CloudFront CDN URL.
     */
    public String uploadProfilePhoto(UUID userId, MultipartFile file) throws IOException {
        validateFile(file);

        String key = "profiles/" + userId + "/" + UUID.randomUUID() + getExtension(file);

        PutObjectRequest request = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(file.getContentType())
                .contentLength(file.getSize())
                .build();

        s3Client.putObject(request, RequestBody.fromBytes(file.getBytes()));
        log.info("Uploaded profile photo for user {}: {}", userId, key);

        return "https://" + cloudfrontDomain + "/" + key;
    }

    /**
     * Delete a photo by its CDN URL.
     */
    public void deletePhoto(String photoUrl) {
        String key = photoUrl.replace("https://" + cloudfrontDomain + "/", "");
        s3Client.deleteObject(DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build());
        log.info("Deleted photo: {}", key);
    }

    private void validateFile(MultipartFile file) {
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new RuntimeException("File size exceeds 5MB limit");
        }
        if (!ALLOWED_TYPES.contains(file.getContentType())) {
            throw new RuntimeException("File type not allowed. Use JPEG, PNG, or WebP");
        }
    }

    private String getExtension(MultipartFile file) {
        String contentType = file.getContentType();
        return switch (contentType) {
            case "image/jpeg" -> ".jpg";
            case "image/png"  -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }
}
