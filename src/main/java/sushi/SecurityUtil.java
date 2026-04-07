package sushi;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public final class SecurityUtil {
    private SecurityUtil() {}

    public static String hashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder builder = new StringBuilder();
            for (byte current : bytes) {
                builder.append(String.format("%02x", current));
            }
            return builder.toString();
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 indisponible", exception);
        }
    }

    public static boolean matches(String rawPassword, String storedHash) {
        return hashPassword(rawPassword).equals(storedHash);
    }
}
