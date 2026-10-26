package com.sms.dao;

import com.sms.model.ActivityLog;
import com.sms.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;

public class ActivityLogDAO {

    public void addLog(ActivityLog log) throws SQLException {

        String sql = """
            INSERT INTO activity_logs
            (entity_type, entity_id, action_type, description,
             old_data, new_data, expires_at, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """;

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setString(1, log.getEntityType());
            statement.setInt(2, log.getEntityId());
            statement.setString(3, log.getActionType());
            statement.setString(4, log.getDescription());

            statement.setString(5, log.getOldData());
            statement.setString(6, log.getNewData());

            LocalDateTime expiry = LocalDateTime.now().plusDays(7);
            statement.setTimestamp(
                7, Timestamp.valueOf(expiry)
            );

            String status = log.getStatus() != null
                    ? log.getStatus()
                    : "ACTIVE";

            statement.setString(8, status);

            statement.executeUpdate();
        }
    }

public java.util.List<com.sms.model.ActivityLog> findAllLogs()
        throws java.sql.SQLException {

    String sql = """
        SELECT log_id, entity_type, entity_id, action_type,
               description, old_data, new_data, action_time,
               expires_at, status
        FROM activity_logs
        ORDER BY action_time DESC, log_id DESC
        """;

    java.util.List<com.sms.model.ActivityLog> logs =
            new java.util.ArrayList<>();

    try (java.sql.Connection con =
                com.sms.util.DBConnection.getConnection();
         java.sql.PreparedStatement ps = con.prepareStatement(sql);
         java.sql.ResultSet rs = ps.executeQuery()) {

        while (rs.next()) {
            com.sms.model.ActivityLog log =
                    new com.sms.model.ActivityLog();

            log.setLogId(rs.getInt("log_id"));
            log.setEntityType(rs.getString("entity_type"));
            log.setEntityId(rs.getInt("entity_id"));
            log.setActionType(rs.getString("action_type"));
            log.setDescription(rs.getString("description"));
            log.setOldData(rs.getString("old_data"));
            log.setNewData(rs.getString("new_data"));

            java.sql.Timestamp actionTime =
                    rs.getTimestamp("action_time");

            if (actionTime != null) {
                log.setActionTime(actionTime);
            }

            java.sql.Timestamp expiresAt =
                    rs.getTimestamp("expires_at");

            if (expiresAt != null) {
                log.setExpiresAt(expiresAt);
            }

            log.setStatus(rs.getString("status"));

            logs.add(log);
        }
    }

    return logs;
}

}