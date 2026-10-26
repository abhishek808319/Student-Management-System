
package com.sms.servlet;

import com.sms.dao.StudentArchiveDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/students/archive")
public class StudentArchiveServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final StudentArchiveDAO archiveDAO =
            new StudentArchiveDAO();

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        try {
            request.setAttribute(
                    "archivedStudents",
                    archiveDAO.findRestorableStudents()
            );

            request.getRequestDispatcher("/student-archive.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Unable to load archived students.", e
            );
        }
    }
}
