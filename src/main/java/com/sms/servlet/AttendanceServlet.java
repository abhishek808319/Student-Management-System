
package com.sms.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/students/attendance")
public class AttendanceServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String studentIdParameter = request.getParameter("id");

        if (studentIdParameter == null ||
                studentIdParameter.trim().isEmpty()) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Student ID is required."
            );
            return;
        }

        int studentId;

        try {
            studentId = Integer.parseInt(studentIdParameter);

            if (studentId <= 0) {
                throw new NumberFormatException();
            }

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid student ID."
            );
            return;
        }

        request.setAttribute("studentId", studentId);

        request.getRequestDispatcher("/attendance.jsp")
               .forward(request, response);
    }
}
