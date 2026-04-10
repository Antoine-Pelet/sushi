package sushi.web;

import jakarta.servlet.ServletContext;
import sushi.SushiService;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public final class AppServices {
    private static final String SERVICE_KEY = AppServices.class.getName() + ".service";

    private AppServices() {
    }

    public static SushiService getService(ServletContext context) {
        synchronized (context) {
            Object existing = context.getAttribute(SERVICE_KEY);
            if (existing instanceof SushiService service) {
                return service;
            }

            Path path = resolveStorePath(context);
            SushiService service = new SushiService(path);
            context.setAttribute(SERVICE_KEY, service);
            return service;
        }
    }

    private static Path resolveStorePath(ServletContext context) {
    String configuredPath = firstPresent(
            context.getInitParameter("sushi.store.path"),
            System.getProperty("sushef.store.path"),
            System.getenv("SUSHEF_STORE_PATH")
    );
    if (configuredPath != null) {
        return initializePersistentStore(Paths.get(configuredPath), context);
    }

    // Toujours utiliser le store.xml du projet
    String seedPath = context.getRealPath("/WEB-INF/data/store.xml");
    return Paths.get(seedPath);
}

    private static Path initializePersistentStore(Path persistentPath, ServletContext context) {
        try {
            if (!Files.exists(persistentPath)) {
                Path parent = persistentPath.getParent();
                if (parent != null) {
                    Files.createDirectories(parent);
                }

                String seedPath = context.getRealPath("/WEB-INF/data/store.xml");
                if (seedPath != null && Files.exists(Paths.get(seedPath))) {
                    Files.copy(Paths.get(seedPath), persistentPath);
                }
            }
        } catch (Exception exception) {
            throw new IllegalStateException("Impossible de preparer le stockage persistant Sushef", exception);
        }
        return persistentPath;
    }

    private static String firstPresent(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }
        return null;
    }
}
