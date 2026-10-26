
package com.sms.servlet;

import com.sms.dao.ActivityLogDAO;
import com.sms.model.ActivityLog;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/activity-logs")
public class ActivityLogServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final ActivityLogDAO activityLogDAO = new ActivityLogDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        try {
            List<ActivityLog> activityLogs =
                    activityLogDAO.findAllLogs();

            request.setAttribute("activityLogs", activityLogs);

            request.getRequestDispatcher("/activity-logs.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                    "Unable to load activity logs.", e);
        }
    }
}
