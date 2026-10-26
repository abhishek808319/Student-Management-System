
package com.sms.servlet;

import com.sms.dao.ActivityLogger;
import com.sms.dao.StudentArchiveDAO;
import com.sms.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLIntegrityConstraintViolationException;

@WebServlet("/students/restore")
public class StudentRestoreServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final StudentArchiveDAO archiveDAO =
            new StudentArchiveDAO();

    private final ActivityLogger activityLogger =
            new ActivityLogger();

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        int archiveId;

        // Validate the archive ID.
        try {
            archiveId = Integer.parseInt(
                    request.getParameter("archiveId")
            );

            if (archiveId <= 0) {
                throw new NumberFormatException("Invalid archive ID");
            }

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid archive ID."
            );
            return;
        }

        try {
            /*
             * Read the archived student's details before restoration.
             * Only unexpired, deleted records can be restored.
             */
            String selectSql = """
                SELECT original_student_id, roll_no, full_name,
                       email, phone, address, course_id,
                       profile_picture
                FROM student_archive
                WHERE archive_id = ?
                  AND archive_status = 'DELETED'
                  AND expires_at > CURRENT_TIMESTAMP
                """;

            int studentId;
            String rollNo;
            String fullName;
            String email;
            String phone;
            String address;
            int courseId;
            String profilePicture;

            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(selectSql)) {

                ps.setInt(1, archiveId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        request.getSession().setAttribute(
                                "errorMessage",
                                "This archive was not found, was already "
                                + "restored, or its seven-day retention "
                                + "period has expired."
                        );

                        response.sendRedirect(
                                request.getContextPath()
                                + "/students/archive"
                        );
                        return;
                    }

                    studentId = rs.getInt("original_student_id");
                    rollNo = rs.getString("roll_no");
                    fullName = rs.getString("full_name");
                    email = rs.getString("email");
                    phone = rs.getString("phone");
                    address = rs.getString("address");
                    courseId = rs.getInt("course_id");
                    profilePicture = rs.getString("profile_picture");
                }
            }

            // Restore the student using your existing DAO.
            boolean restored = archiveDAO.restoreStudent(archiveId);

            if (!restored) {
                request.getSession().setAttribute(
                        "errorMessage",
                        "The student could not be restored. "
                        + "The archive may have expired or already "
                        + "been restored."
                );

                response.sendRedirect(
                        request.getContextPath() + "/students/archive"
                );
                return;
            }

            /*
             * Record the successful restoration in activity_logs.
             */
            String newData =
                    "{\"studentId\":" + studentId
                  + ",\"rollNo\":\"" + jsonEscape(rollNo) + "\""
                  + ",\"fullName\":\"" + jsonEscape(fullName) + "\""
                  + ",\"email\":\"" + jsonEscape(email) + "\""
                  + ",\"phone\":\"" + jsonEscape(phone) + "\""
                  + ",\"courseId\":" + courseId
                  + ",\"address\":\"" + jsonEscape(address) + "\""
                  + ",\"profilePicture\":\""
                  + jsonEscape(profilePicture) + "\"}";

            activityLogger.logStudentActivity(
                    studentId,
                    "RESTORE",
                    "Restored student: " + fullName,
                    null,
                    newData
            );

            request.getSession().setAttribute(
                    "successMessage",
                    "Student restored successfully!"
            );

            response.sendRedirect(
                    request.getContextPath() + "/students/archive"
            );

        } catch (SQLIntegrityConstraintViolationException e) {

            request.getSession().setAttribute(
                    "errorMessage",
                    "Unable to restore this student because the original "
                    + "student ID, roll number, or email may already exist."
            );

            response.sendRedirect(
                    request.getContextPath() + "/students/archive"
            );

        } catch (Exception e) {
            throw new ServletException(
                "Unable to restore student.", e
            );
        }
    }

    // Escape special characters before building the JSON activity data.
    private String jsonEscape(String value) {
        if (value == null) {
            return "";
        }

        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
