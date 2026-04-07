package sushi.web;

import jakarta.servlet.ServletContext;
import sushi.SushiService;

import java.io.File;
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
        String realPath = context.getRealPath("/WEB-INF/data/store.xml");
        if (realPath != null) {
            return Paths.get(realPath);
        }

        File tempDir = (File) context.getAttribute(ServletContext.TEMPDIR);
        return tempDir.toPath().resolve("sushi-store.xml");
    }
}
