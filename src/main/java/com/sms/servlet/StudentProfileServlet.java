
package com.sms.servlet;

import com.sms.dao.StudentDAO;
import com.sms.model.Student;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/students/profile")
public class StudentProfileServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final StudentDAO studentDAO = new StudentDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String idParameter = request.getParameter("id");

        if (idParameter == null || idParameter.isBlank()) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Student ID is required."
            );
            return;
        }

        final int studentId;

        try {
            studentId = Integer.parseInt(idParameter);
        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid student ID."
            );
            return;
        }

        if (studentId <= 0) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid student ID."
            );
            return;
        }

        try {
            Student student = studentDAO.findById(studentId);

            if (student == null) {
                response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Student not found."
                );
                return;
            }

            request.setAttribute("student", student);

            request.getRequestDispatcher("/student-profile.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                "Unable to load student profile.", e
            );
        }
    }
}
