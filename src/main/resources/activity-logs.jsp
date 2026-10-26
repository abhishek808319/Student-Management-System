
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="com.sms.model.ActivityLog" %>
<%@ page import="java.sql.Timestamp" %>

<%!
    // Escape HTML characters to prevent stored data from being
    // interpreted as HTML or JavaScript.
    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }

        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>

<%
    List<ActivityLog> activityLogs =
        (List<ActivityLog>) request.getAttribute("activityLogs");

    if (activityLogs == null) {
        activityLogs = java.util.Collections.emptyList();
    }

    String contextPath = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Activity Logs | Student Management System</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            padding: 25px;
            font-family: Arial, sans-serif;
            background: #f4f6fb;
            color: #263238;
        }

        .container {
            max-width: 1400px;
            margin: auto;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 25px;
        }

        h1 {
            margin: 0 0 8px;
            color: #172554;
        }

        .subtitle {
            margin: 0;
            color: #64748b;
        }

        .btn {
            display: inline-block;
            padding: 11px 16px;
            background: #1d4ed8;
            color: white;
            text-decoration: none;
            border-radius: 7px;
            font-weight: bold;
        }

        .btn:hover {
            background: #1e40af;
        }

        .summary {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px #0000000a;
        }

        .summary strong {
            font-size: 25px;
            color: #1d4ed8;
        }

        .table-container {
            overflow-x: auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 8px #0000000a;
        }

        table {
            width: 100%;
            min-width: 1100px;
            border-collapse: collapse;
        }

        th, td {
            padding: 13px;
            text-align: left;
            border-bottom: 1px solid #e5e7eb;
            vertical-align: top;
        }

        th {
            background: #172554;
            color: white;
            white-space: nowrap;
        }

        tr:hover td {
            background: #f8fafc;
        }

        .action {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 5px;
            font-size: 12px;
            font-weight: bold;
        }

        .add {
            background: #dcfce7;
            color: #166534;
        }

        .update {
            background: #dbeafe;
            color: #1d4ed8;
        }

        .delete {
            background: #fee2e2;
            color: #991b1b;
        }

        .restore {
            background: #f3e8ff;
            color: #6b21a8;
        }

        .other {
            background: #e5e7eb;
            color: #374151;
        }

        .status {
            font-weight: bold;
        }

        .json-data {
            max-width: 280px;
            min-width: 180px;
            max-height: 150px;
            overflow: auto;
            white-space: pre-wrap;
            overflow-wrap: anywhere;
            font-family: Consolas, monospace;
            font-size: 12px;
        }

        .empty {
            padding: 35px;
            text-align: center;
            color: #64748b;
        }

        @media (max-width: 600px) {
            body {
                padding: 12px;
            }

            .header {
                align-items: flex-start;
            }
        }
    </style>
</head>

<body>
<div class="container">

    <div class="header">
        <div>
            <h1>Activity Logs</h1>
            <p class="subtitle">
                Track student additions, updates, deletions and restorations.
            </p>
        </div>

        <a class="btn"
           href="<%= contextPath %>/dashboard">
            Back to Dashboard
        </a>
    </div>

    <div class="summary">
        <strong><%= activityLogs.size() %></strong>
        <div>Total recorded activities</div>
    </div>

    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>Log ID</th>
                    <th>Student ID</th>
                    <th>Action</th>
                    <th>Description</th>
                    <th>Action Time</th>
                    <th>Old Data</th>
                    <th>New Data</th>
                    <th>Expires At</th>
                    <th>Status</th>
                </tr>
            </thead>

            <tbody>
            <% if (activityLogs.isEmpty()) { %>
                <tr>
                    <td colspan="9" class="empty">
                        No activity logs found.
                    </td>
                </tr>
            <% } else {
                for (ActivityLog log : activityLogs) {
                    String action = log.getActionType();
                    String actionClass = "other";

                    if ("ADD".equalsIgnoreCase(action)) {
                        actionClass = "add";
                    } else if ("UPDATE".equalsIgnoreCase(action)) {
                        actionClass = "update";
                    } else if ("DELETE".equalsIgnoreCase(action)) {
                        actionClass = "delete";
                    } else if ("RESTORE".equalsIgnoreCase(action)) {
                        actionClass = "restore";
                    }
            %>
                <tr>
                    <td><%= log.getLogId() %></td>

                    <td><%= log.getEntityId() %></td>

                    <td>
                        <span class="action <%= actionClass %>">
                            <%= escapeHtml(action) %>
                        </span>
                    </td>

                    <td>
                        <%= escapeHtml(log.getDescription()) %>
                    </td>

                    <td>
                        <%= log.getActionTime() == null
                            ? "—"
                            : escapeHtml(log.getActionTime().toString()) %>
                    </td>

                    <td>
                        <div class="json-data"><%= escapeHtml(log.getOldData()) %></div>
                    </td>

                    <td>
                        <div class="json-data"><%= escapeHtml(log.getNewData()) %></div>
                    </td>

                    <td>
                        <%= log.getExpiresAt() == null
                            ? "—"
                            : escapeHtml(log.getExpiresAt().toString()) %>
                    </td>

                    <td class="status">
                        <%= escapeHtml(log.getStatus()) %>
                    </td>
                </tr>
            <%  }
               } %>
            </tbody>
        </table>
    </div>

</div>
</body>
</html>
