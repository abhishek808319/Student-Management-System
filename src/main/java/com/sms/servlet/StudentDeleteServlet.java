
package com.sms.servlet;

import com.sms.dao.StudentDAO;
import com.sms.dao.ActivityLogger;
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
import java.sql.Statement;
import java.sql.Timestamp;

@WebServlet("/students/delete")
public class StudentDeleteServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final StudentDAO studentDAO = new StudentDAO();
    private final ActivityLogger activityLogger = new ActivityLogger();

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        int studentId;

        try {
            studentId = Integer.parseInt(
                request.getParameter("id")
            );

            if (studentId <= 0) {
                throw new NumberFormatException("Invalid ID");
            }

        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid student ID"
            );
            return;
        }

        int archiveId = -1;
        boolean archiveCreated = false;

        String oldData;
        String fullName;

        try {
            /*
             * Step 1: Read the original student details and
             * preserve them in the archive before deletion.
             */
            String selectSql = """
                SELECT student_id, roll_no, full_name, email,
                       phone, course_id, address, profile_picture,
                       created_at
                FROM students
                WHERE student_id = ?
                """;

            String archiveSql = """
                INSERT INTO student_archive
                (original_student_id, roll_no, full_name, email,
                 phone, course_id, address, profile_picture,
                 original_created_at, expires_at, archive_status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'DELETED')
                """;

            String rollNo;
            String email;
            String phone;
            String address;
            String profilePicture;
            int courseId;
            Timestamp originalCreatedAt;

            try (Connection con = DBConnection.getConnection()) {

                try (PreparedStatement ps =
                        con.prepareStatement(selectSql)) {

                    ps.setInt(1, studentId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            response.sendError(
                                HttpServletResponse.SC_NOT_FOUND,
                                "Student not found."
                            );
                            return;
                        }

                        rollNo = rs.getString("roll_no");
                        fullName = rs.getString("full_name");
                        email = rs.getString("email");
                        phone = rs.getString("phone");
                        courseId = rs.getInt("course_id");
                        address = rs.getString("address");
                        profilePicture =
                            rs.getString("profile_picture");
                        originalCreatedAt =
                            rs.getTimestamp("created_at");

                        oldData =
                            "{\"studentId\":" + studentId
                          + ",\"rollNo\":\"" + jsonEscape(rollNo) + "\""
                          + ",\"fullName\":\"" + jsonEscape(fullName) + "\""
                          + ",\"email\":\"" + jsonEscape(email) + "\""
                          + ",\"phone\":\"" + jsonEscape(phone) + "\""
                          + ",\"courseId\":" + courseId
                          + ",\"address\":\"" + jsonEscape(address) + "\""
                          + ",\"profilePicture\":\""
                          + jsonEscape(profilePicture) + "\"}";
                    }
                }

                /*
                 * Step 2: Insert the archive with a seven-day expiry.
                 */
                try (PreparedStatement ps = con.prepareStatement(
                        archiveSql,
                        Statement.RETURN_GENERATED_KEYS)) {

                    ps.setInt(1, studentId);
                    ps.setString(2, rollNo);
                    ps.setString(3, fullName);
                    ps.setString(4, email);
                    ps.setString(5, phone);
                    ps.setInt(6, courseId);
                    ps.setString(7, address);
                    ps.setString(8, profilePicture);

                    if (originalCreatedAt != null) {
                        ps.setTimestamp(9, originalCreatedAt);
                    } else {
                        ps.setNull(
                            9,
                            java.sql.Types.TIMESTAMP
                        );
                    }

                    ps.setTimestamp(
                        10,
                        Timestamp.valueOf(
                            java.time.LocalDateTime.now().plusDays(7)
                        )
                    );

                    ps.executeUpdate();

                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (keys.next()) {
                            archiveId = keys.getInt(1);
                            archiveCreated = true;
                        }
                    }
                }
            }

            if (!archiveCreated) {
                throw new ServletException(
                    "The student archive could not be created."
                );
            }

            /*
             * Step 3: Delete using the existing DAO.
             * If deletion fails, remove the archive record
             * created by this request.
             */
            try {
                studentDAO.delete(studentId);

            } catch (Exception deleteException) {

                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(
                         "DELETE FROM student_archive WHERE archive_id = ?")) {

                    ps.setInt(1, archiveId);
                    ps.executeUpdate();

                } catch (Exception cleanupException) {
                    deleteException.addSuppressed(cleanupException);
                }

                throw deleteException;
            }

            /*
             * Step 4: Log the successful deletion.
             */
            activityLogger.logStudentActivity(
                studentId,
                "DELETE",
                "Deleted student: " + fullName,
                oldData,
                null
            );

            request.getSession().setAttribute(
                "successMessage",
                "Student deleted successfully! "
                + "The record can be restored within 7 days."
            );

            response.sendRedirect(
                request.getContextPath() + "/students"
            );

        } catch (ServletException e) {
            throw e;

        } catch (Exception e) {
            throw new ServletException(
                "Unable to delete student.", e
            );
        }
    }

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
