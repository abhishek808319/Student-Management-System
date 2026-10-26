
package com.sms.servlet;

import com.sms.dao.CourseDAO;
import com.sms.model.Course;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

@WebServlet("/courses")
public class CourseListServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final CourseDAO courseDAO = new CourseDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        try {
            List<Course> courses = courseDAO.findAll();

            request.setAttribute("courses", courses);

            request.getRequestDispatcher("/courses.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            throw new ServletException(
                "Unable to load courses.", e
            );
        }
    }
}
