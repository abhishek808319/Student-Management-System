
package com.sms.servlet;

import com.sms.dao.StudentDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final StudentDAO studentDAO = new StudentDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        try {
            int totalStudents = studentDAO.countAll();

            request.setAttribute("totalStudents", totalStudents);

            request.getRequestDispatcher("/dashboard.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                "Unable to load dashboard.", e
            );
        }
    }
}
