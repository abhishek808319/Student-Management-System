
package com.sms.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL =
            "jdbc:mysql://localhost:3306/student_management?serverTimezone=UTC";

    private static final String USER =
            System.getenv().getOrDefault("SMS_DB_USER", "root");

    public static Connection getConnection() throws SQLException {
        String password = System.getenv("SMS_DB_PASSWORD");

        if (password == null) {
            throw new SQLException(
                    "SMS_DB_PASSWORD environment variable is not configured."
            );
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                    "MySQL JDBC driver is not available to the application.", e
            );
        }

        return DriverManager.getConnection(URL, USER, password);
    }
}
