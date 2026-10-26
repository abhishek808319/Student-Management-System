
package com.sms.dao;

import com.sms.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

public class StudentArchiveDAO {

    public boolean restoreStudent(int archiveId) throws SQLException {

        String selectSql = """
            SELECT original_student_id, roll_no, full_name, email,
                   phone, course_id, address, profile_picture,
                   original_created_at
            FROM student_archive
            WHERE archive_id = ?
              AND archive_status = 'DELETED'
              AND expires_at > CURRENT_TIMESTAMP
            FOR UPDATE
            """;

        String insertSql = """
            INSERT INTO students
            (student_id, roll_no, full_name, email, phone,
             course_id, address, profile_picture, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """;

        String updateArchiveSql = """
            UPDATE student_archive
            SET archive_status = 'RESTORED',
                restored_at = CURRENT_TIMESTAMP
            WHERE archive_id = ?
            """;

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                int originalStudentId;
                String rollNo;
                String fullName;
                String email;
                String phone;
                int courseId;
                String address;
                String profilePicture;
                Timestamp originalCreatedAt;

                try (PreparedStatement ps =
                        con.prepareStatement(selectSql)) {

                    ps.setInt(1, archiveId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            con.rollback();
                            return false;
                        }

                        originalStudentId =
                            rs.getInt("original_student_id");
                        rollNo = rs.getString("roll_no");
                        fullName = rs.getString("full_name");
                        email = rs.getString("email");
                        phone = rs.getString("phone");
                        courseId = rs.getInt("course_id");
                        address = rs.getString("address");
                        profilePicture =
                            rs.getString("profile_picture");
                        originalCreatedAt =
                            rs.getTimestamp("original_created_at");
                    }
                }

                try (PreparedStatement ps =
                        con.prepareStatement(insertSql)) {

                    ps.setInt(1, originalStudentId);
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
                        ps.setTimestamp(
                            9,
                            new Timestamp(System.currentTimeMillis())
                        );
                    }

                    ps.executeUpdate();
                }

                try (PreparedStatement ps =
                        con.prepareStatement(updateArchiveSql)) {

                    ps.setInt(1, archiveId);

                    if (ps.executeUpdate() != 1) {
                        throw new SQLException(
                            "Could not mark archive as restored."
                        );
                    }
                }

                con.commit();
                return true;

            } catch (SQLException e) {
                con.rollback();
                throw e;

            } finally {
                con.setAutoCommit(true);
            }
        }
    }

public java.util.List<java.util.Map<String, Object>> findRestorableStudents()
        throws java.sql.SQLException {

    String sql = """
        SELECT archive_id, original_student_id, roll_no,
               full_name, email, phone, course_id,
               address, profile_picture, deleted_at, expires_at
        FROM student_archive
        WHERE archive_status = 'DELETED'
          AND expires_at > CURRENT_TIMESTAMP
        ORDER BY deleted_at DESC
        """;

    java.util.List<java.util.Map<String, Object>> students =
            new java.util.ArrayList<>();

    try (java.sql.Connection con =
                com.sms.util.DBConnection.getConnection();
         java.sql.PreparedStatement ps = con.prepareStatement(sql);
         java.sql.ResultSet rs = ps.executeQuery()) {

        while (rs.next()) {
            java.util.Map<String, Object> student =
                    new java.util.LinkedHashMap<>();

            student.put("archiveId", rs.getInt("archive_id"));
            student.put("studentId", rs.getInt("original_student_id"));
            student.put("rollNo", rs.getString("roll_no"));
            student.put("fullName", rs.getString("full_name"));
            student.put("email", rs.getString("email"));
            student.put("phone", rs.getString("phone"));
            student.put("courseId", rs.getInt("course_id"));
            student.put("address", rs.getString("address"));
            student.put("profilePicture", rs.getString("profile_picture"));
            student.put("deletedAt", rs.getTimestamp("deleted_at"));
            student.put("expiresAt", rs.getTimestamp("expires_at"));

            students.add(student);
        }
    }

    return students;
}

}
