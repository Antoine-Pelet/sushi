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
        response.sendRedirect(buildRedirectTarget(
                request.getContextPath(),
                request.getParameter("returnPage"),
                request.getParameter("returnRecipeId"),
                request.getParameter("returnEditRecipeId"),
                request.getParameter("returnMode"),
                request.getParameter("returnSection")
        ));
    }

    protected String buildRedirectTarget(String contextPath, String returnPage, String returnRecipeId, String returnEditRecipeId, String returnMode, String returnSection) {
        String page = normalizeReturnPage(returnPage);
        StringBuilder target = new StringBuilder(contextPath);
        switch (page) {
            case "recipe" -> target.append("/recipe");
            case "workspace" -> target.append("/workspace");
            case "cook" -> target.append("/cook");
            case "cook-steps" -> target.append("/cook-steps");
            case "auth" -> target.append("/auth");
            default -> target.append("/app");
        }

        List<String> query = new ArrayList<>();
        if ("recipe".equals(page) || "cook".equals(page) || "cook-steps".equals(page)) {
            appendQuery(query, "id", returnRecipeId);
        } else if ("workspace".equals(page)) {
            String workspaceMode = sanitizeMode(returnMode);
            if (workspaceMode.isBlank()) {
                workspaceMode = mapWorkspaceModeFromSection(returnSection);
            }
            appendQuery(query, "mode", workspaceMode);
            appendQuery(query, "editRecipeId", returnEditRecipeId);
        } else if (!"auth".equals(page)) {
            appendQuery(query, "recipeId", returnRecipeId);
            appendQuery(query, "editRecipeId", returnEditRecipeId);
        }

        if (!query.isEmpty()) {
            target.append('?').append(String.join("&", query));
        }

        String cleanSection = sanitizeSection(returnSection);
        if (!cleanSection.isBlank() && !"workspace".equals(page)) {
            target.append('#').append(cleanSection);
        }

        return target.toString();
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

    protected String sanitizeSection(String section) {
        if (section == null || section.isBlank()) {
            return "";
        }
        return section.trim().replaceAll("[^A-Za-z0-9_-]", "");
    }

    protected String sanitizeMode(String mode) {
        if (mode == null || mode.isBlank()) {
            return "";
        }
        return mode.trim().replaceAll("[^A-Za-z0-9_-]", "");
    }

    protected String mapWorkspaceModeFromSection(String section) {
        String cleanSection = sanitizeSection(section);
        return switch (cleanSection) {
            case "auth-panel" -> "account";
            case "cart-panel" -> "cart";
            case "admin-board" -> "admin";
            case "recipe-maker" -> "recipes";
            case "stock-board" -> "stock";
            case "order-board" -> "orders";
            default -> "";
        };
    }

    protected record Flash(String type, String message) {
    }

    protected void appendQuery(List<String> query, String key, String value) {
        if (value == null || value.isBlank()) {
            return;
        }

        query.add(URLEncoder.encode(key, StandardCharsets.UTF_8) + "="
                + URLEncoder.encode(value.trim(), StandardCharsets.UTF_8));
    }

    private String normalizeReturnPage(String returnPage) {
        if (returnPage == null || returnPage.isBlank()) {
            return "app";
        }

        String normalized = returnPage.trim();
        return switch (normalized) {
            case "recipe", "workspace", "cook", "cook-steps", "auth", "app" -> normalized;
            default -> "app";
        };
    }
}