
package com.sms.util;

import java.sql.Connection;

public class ConnectionTest {

    public static void main(String[] args) {
        try (Connection connection =
                     DBConnection.getConnection()) {

            System.out.println(
                    "MySQL connection successful!");

            System.out.println(
                    "Database: " + connection.getCatalog());

        } catch (Exception e) {
            System.out.println(
                    "Connection failed: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
