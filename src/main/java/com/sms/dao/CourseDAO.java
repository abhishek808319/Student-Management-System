
package com.sms.dao;

import com.sms.model.Course;
import com.sms.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class CourseDAO {

    public List<Course> findAll() throws SQLException {
        List<Course> courses = new ArrayList<>();

        String sql =
            "SELECT course_id, course_name, semester " +
            "FROM courses ORDER BY course_id";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement =
                 connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {

            while (resultSet.next()) {
                Course course = new Course();

                course.setCourseId(
                    resultSet.getInt("course_id")
                );

                course.setCourseName(
                    resultSet.getString("course_name")
                );

                course.setSemester(
                    resultSet.getInt("semester")
                );

                courses.add(course);
            }
        }

        return courses;
    }

public void addCourse(Course course) throws SQLException {
    String sql =
        "INSERT INTO courses (course_name, semester) VALUES (?, ?)";

    try (Connection connection = DBConnection.getConnection();
         PreparedStatement statement =
             connection.prepareStatement(sql)) {

        statement.setString(1, course.getCourseName());
        statement.setInt(2, course.getSemester());

        statement.executeUpdate();
    }
}

}
