package sushi.web;

import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import sushi.SushiService;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

public abstract class BaseServlet extends HttpServlet {
    protected SushiService service(HttpServletRequest request) {
        return AppServices.getService(getServletContext());
    }

    protected Integer currentUserId(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        Object raw = session.getAttribute("userId");
        if (raw instanceof Integer integer) {
            return integer;
        }
        if (raw instanceof String text) {
            try {
                return Integer.parseInt(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    protected void setFlash(HttpServletRequest request, String type, String message) {
        HttpSession session = request.getSession(true);
        session.setAttribute("flashType", type);
        session.setAttribute("flashMessage", message);
    }

    protected Flash consumeFlash(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }

        Object message = session.getAttribute("flashMessage");
        if (!(message instanceof String text) || text.isBlank()) {
            return null;
        }

        Object type = session.getAttribute("flashType");
        session.removeAttribute("flashMessage");
        session.removeAttribute("flashType");
        return new Flash(type instanceof String value ? value : "info", text);
    }

    protected void redirectToApp(HttpServletRequest request, HttpServletResponse response) throws IOException {
        StringBuilder target = new StringBuilder(request.getContextPath()).append("/app");
        List<String> query = new ArrayList<>();
        appendQuery(query, "recipeId", request.getParameter("returnRecipeId"));
        appendQuery(query, "editRecipeId", request.getParameter("returnEditRecipeId"));

        if (!query.isEmpty()) {
            target.append('?').append(String.join("&", query));
        }

        String section = request.getParameter("returnSection");
        if (section != null && !section.isBlank()) {
            String cleanSection = section.trim().replaceAll("[^A-Za-z0-9_-]", "");
            if (!cleanSection.isBlank()) {
                target.append('#').append(cleanSection);
            }
        }

        response.sendRedirect(target.toString());
    }

    protected int requiredInt(HttpServletRequest request, String parameterName) {
        String raw = request.getParameter(parameterName);
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Parametre manquant: " + parameterName);
        }
        return Integer.parseInt(raw.trim());
    }

    protected Integer optionalInt(HttpServletRequest request, String parameterName) {
        String raw = request.getParameter(parameterName);
        if (raw == null || raw.isBlank()) {
            return null;
        }
        return Integer.parseInt(raw.trim());
    }

    protected int optionalInt(HttpServletRequest request, String parameterName, int defaultValue) {
        String raw = request.getParameter(parameterName);
        if (raw == null || raw.isBlank()) {
            return defaultValue;
        }
        return Integer.parseInt(raw.trim());
    }

    protected double requiredDouble(HttpServletRequest request, String parameterName) {
        String raw = request.getParameter(parameterName);
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Parametre manquant: " + parameterName);
        }
        return Double.parseDouble(raw.trim().replace(',', '.'));
    }

    protected String normalizePath(String pathInfo) {
        if (pathInfo == null || pathInfo.isBlank()) {
            return "/";
        }
        return pathInfo.startsWith("/") ? pathInfo : "/" + pathInfo;
    }

    protected record Flash(String type, String message) {
    }

    private void appendQuery(List<String> query, String key, String value) {
        if (value == null || value.isBlank()) {
            return;
        }

        query.add(URLEncoder.encode(key, StandardCharsets.UTF_8) + "="
                + URLEncoder.encode(value.trim(), StandardCharsets.UTF_8));
    }
}
