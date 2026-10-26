
package com.sms.servlet;

import com.sms.dao.StudentDAO;
import com.sms.model.Student;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

@WebServlet("/students")
public class StudentListServlet extends HttpServlet {

    private final StudentDAO studentDAO = new StudentDAO();

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        String keyword = request.getParameter("search");

        try {
            List<Student> students;

            if (keyword != null && !keyword.trim().isEmpty()) {
                students = studentDAO.search(keyword.trim());
            } else {
                students = studentDAO.findAll();
            }

            request.setAttribute("students", students);
            request.setAttribute("searchKeyword", keyword);

            request.getRequestDispatcher("/students.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                "Unable to load student records.", e
            );
        }
    }
}
