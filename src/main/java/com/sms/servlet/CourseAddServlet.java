
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

@WebServlet("/courses/add")
public class CourseAddServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final CourseDAO courseDAO = new CourseDAO();

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String courseName = request.getParameter("courseName");
        String semesterValue = request.getParameter("semester");

        if (courseName == null || courseName.trim().isEmpty()
                || courseName.trim().length() > 150
                || semesterValue == null
                || !semesterValue.matches("[1-9][0-9]?")) {

            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Enter a valid course name and semester."
            );
            return;
        }

        int semester = Integer.parseInt(semesterValue);

        Course course = new Course();
        course.setCourseName(courseName.trim());
        course.setSemester(semester);

        try {
            courseDAO.addCourse(course);

            request.getSession().setAttribute(
                "successMessage",
                "Course added successfully!"
            );

            response.sendRedirect(
                request.getContextPath() + "/courses"
            );

        } catch (SQLException e) {
            throw new ServletException(
                "Unable to add course.", e
            );
        }
    }
}
