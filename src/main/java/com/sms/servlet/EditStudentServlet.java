package com.sms.servlet;

import com.sms.dao.CourseDAO;
import com.sms.dao.StudentDAO;
import com.sms.model.Course;
import com.sms.model.Student;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

@WebServlet("/students/edit")
public class EditStudentServlet extends HttpServlet {

    private final StudentDAO studentDAO = new StudentDAO();
    private final CourseDAO courseDAO = new CourseDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String studentId = request.getParameter("id");

        try {
            int id = Integer.parseInt(studentId);

            Student student = studentDAO.findById(id);

            if (student == null) {
                response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Student not found"
                );
                return;
            }

            List<Course> courses = courseDAO.findAll();

            request.setAttribute("student", student);
            request.setAttribute("courses", courses);

            request.getRequestDispatcher("/edit-student.jsp")
                   .forward(request, response);

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid student ID"
            );

        } catch (Exception e) {
            throw new ServletException(
                "Unable to load student and courses.", e
            );
        }
    }
}
