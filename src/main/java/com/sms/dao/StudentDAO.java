
package com.sms.dao;

import com.sms.model.Student;
import com.sms.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class StudentDAO {

    // Convert a course name into its database course_id.
    private int getCourseId(Connection con, String courseName)
            throws Exception {

        if (courseName == null || courseName.trim().isEmpty()) {
            throw new IllegalArgumentException(
                "Please select a course."
            );
        }

        String sql =
            "SELECT course_id FROM courses WHERE course_name = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, courseName.trim());

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("course_id");
                }
            }
        }

        throw new IllegalArgumentException(
            "Course not found: " + courseName
        );
    }

    // ADD STUDENT

public void add(Student student) throws Exception {

    String sql = """
        INSERT INTO students
        (roll_no, full_name, email, phone, course_id,
         address, profile_picture)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """;

    try (Connection con = DBConnection.getConnection()) {

        int courseId = getCourseId(con, student.getCourse());

        try (PreparedStatement ps = con.prepareStatement(
                sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, student.getRollNo());
            ps.setString(2, student.getFullName());
            ps.setString(3, student.getEmail());
            ps.setString(4, student.getPhone());
            ps.setInt(5, courseId);
            ps.setString(6, student.getAddress());
            ps.setString(7, student.getProfilePicture());

            int rowsInserted = ps.executeUpdate();

            if (rowsInserted > 0) {
                try (java.sql.ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        student.setStudentId(rs.getInt(1));
                    }
                }
            }
        }
    }
}


    // VIEW ALL STUDENTS
    public List<Student> findAll() throws Exception {

    	String sql = """
    		    SELECT s.student_id, s.roll_no, s.full_name,
    		           s.email, s.phone, c.course_name AS course,
    		           s.address, s.profile_picture
    		    FROM students s
    		    LEFT JOIN courses c ON s.course_id = c.course_id
    		    ORDER BY s.student_id DESC
    		                """;

        List<Student> students = new ArrayList<>();

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                students.add(mapStudent(rs));
            }
        }

        return students;
    }

    // FIND ONE STUDENT
    public Student findById(int studentId) throws Exception {

    	String sql = """
    		    SELECT s.student_id, s.roll_no, s.full_name,
    		           s.email, s.phone, c.course_name AS course,
    		           s.address, s.profile_picture
    		    FROM students s
    		    LEFT JOIN courses c ON s.course_id = c.course_id
    		    WHERE s.student_id = ?
    		    """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, studentId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapStudent(rs);
                }
            }
        }

        return null;
    }

    // UPDATE STUDENT
    public void update(Student student) throws Exception {


String sql = """
    UPDATE students
    SET roll_no = ?, full_name = ?, email = ?,
        phone = ?, course_id = ?, address = ?,
        profile_picture = ?
    WHERE student_id = ?
    """;


        try (Connection con = DBConnection.getConnection()) {

            int courseId = getCourseId(con, student.getCourse());

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, student.getRollNo());
                ps.setString(2, student.getFullName());
                ps.setString(3, student.getEmail());
                ps.setString(4, student.getPhone());
                ps.setInt(5, courseId);
                ps.setString(6, student.getAddress());
                ps.setString(7, student.getProfilePicture());
                ps.setInt(8, student.getStudentId());

                ps.executeUpdate();
            }
        }
    }

    // DELETE STUDENT
    public void delete(int studentId) throws Exception {

        String sql =
            "DELETE FROM students WHERE student_id = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, studentId);
            ps.executeUpdate();
        }
    }

    // SEARCH BY ROLL NUMBER OR NAME
    public List<Student> search(String keyword) throws Exception {

        List<Student> students = new ArrayList<>();

        String sql = """
        	    SELECT s.student_id, s.roll_no, s.full_name,
        	           s.email, s.phone, c.course_name AS course,
        	           s.address, s.profile_picture
        	    FROM students s
        	    LEFT JOIN courses c ON s.course_id = c.course_id
        	    WHERE s.roll_no LIKE ? OR s.full_name LIKE ?
        	    ORDER BY s.student_id DESC
        	    """;

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            String pattern = "%" + keyword.trim() + "%";
            ps.setString(1, pattern);
            ps.setString(2, pattern);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    students.add(mapStudent(rs));
                }
            }
        }

        return students;
    }

    // MAP DATABASE ROW TO STUDENT OBJECT
    private Student mapStudent(ResultSet rs) throws Exception {

        Student student = new Student();

        student.setStudentId(rs.getInt("student_id"));
        student.setRollNo(rs.getString("roll_no"));
        student.setFullName(rs.getString("full_name"));
        student.setEmail(rs.getString("email"));
        student.setPhone(rs.getString("phone"));
        student.setCourse(rs.getString("course"));
        student.setAddress(rs.getString("address"));
        student.setProfilePicture(rs.getString("profile_picture"));

        return student;
    }

    // COUNT STUDENTS FOR DASHBOARD
    public int countAll() throws Exception {

        String sql = "SELECT COUNT(*) FROM students";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }
        }

        return 0;
    }
}
