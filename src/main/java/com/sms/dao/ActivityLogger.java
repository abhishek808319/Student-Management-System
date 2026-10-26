package com.sms.dao;

import com.sms.model.ActivityLog;

public class ActivityLogger {

    private final ActivityLogDAO activityLogDAO =
            new ActivityLogDAO();

    public void logStudentActivity(
            int studentId,
            String action,
            String description,
            String oldData,
            String newData) {

        try {
            ActivityLog log = new ActivityLog();

            log.setEntityType("STUDENT");
            log.setEntityId(studentId);
            log.setActionType(action);
            log.setDescription(description);
            log.setOldData(oldData);
            log.setNewData(newData);
            log.setStatus("ACTIVE");

            activityLogDAO.addLog(log);

        } catch (Exception e) {
            throw new RuntimeException(
                "Failed to record student activity.", e
            );
        }
    }
}
