package sushi.web;

import jakarta.servlet.annotation.WebServlet;

@WebServlet("/cook-steps")
public class CookStepsServlet extends CookServlet {
    @Override
    protected int defaultStartIndex() {
        return 0;
    }

    @Override
    protected String viewPath() {
        return "/WEB-INF/views/cook-steps.jsp";
    }
}
