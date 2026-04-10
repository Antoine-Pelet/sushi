package sushi.web;

import jakarta.servlet.ServletContext;
import sushi.SushiService;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public final class AppServices {
    private static final String SERVICE_KEY = AppServices.class.getName() + ".service";
    private static final String SOURCE_STORE_PATH = "src/main/webapp/WEB-INF/data/store.xml";

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

        // In local development, keep reads and writes on the single XML file committed with the project.
        Path sourceStorePath = Paths.get(System.getProperty("user.dir"), SOURCE_STORE_PATH);
        if (Files.exists(sourceStorePath)) {
            return sourceStorePath;
        }

        String deployedStorePath = context.getRealPath("/WEB-INF/data/store.xml");
        if (deployedStorePath == null) {
            throw new IllegalStateException("Impossible de trouver le fichier de stockage Sushef");
        }
        return Paths.get(deployedStorePath);
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
