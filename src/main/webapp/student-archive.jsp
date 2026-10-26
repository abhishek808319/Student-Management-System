
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.sql.Timestamp" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Archived Students</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 24px;
            background: #f4f6f9;
            color: #222;
        }

        .container {
            max-width: 1200px;
            margin: auto;
            background: white;
            padding: 24px;
            border-radius: 10px;
            box-shadow: 0 2px 12px rgba(0,0,0,.08);
        }

        h1 {
            margin-top: 0;
        }

        .notice {
            padding: 12px;
            background: #fff4d6;
            border-radius: 6px;
            margin-bottom: 18px;
        }

        .message {
            padding: 12px;
            margin-bottom: 16px;
            background: #e6f7e9;
            border-radius: 6px;
        }

        .error {
            background: #ffe6e6;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }

        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }

        th {
            background: #edf1f5;
        }

        .restore-btn {
            background: #167d42;
            color: white;
            border: 0;
            border-radius: 5px;
            padding: 9px 13px;
            cursor: pointer;
        }

        .restore-btn:hover {
            background: #105e31;
        }

        .back-link {
            display: inline-block;
            margin-bottom: 18px;
            color: #1459a6;
            text-decoration: none;
        }

        .empty {
            padding: 24px;
            text-align: center;
            color: #666;
        }
    </style>
</head>

<body>
<div class="container">

    <a class="back-link"
       href="<%= request.getContextPath() %>/students">
        &larr; Back to Students
    </a>

    <h1>Archived Students</h1>

    <div class="notice">
        Deleted student records are available for restoration for
        seven days. After expiry, they will no longer appear here.
    </div>

    <%
        String successMessage =
            (String) session.getAttribute("successMessage");
        String errorMessage =
            (String) session.getAttribute("errorMessage");

        session.removeAttribute("successMessage");
        session.removeAttribute("errorMessage");

        if (successMessage != null) {
    %>
        <div class="message">
            <%= successMessage %>
        </div>
    <%
        }

        if (errorMessage != null) {
    %>
        <div class="message error">
            <%= errorMessage %>
        </div>
    <%
        }

        List<Map<String, Object>> archivedStudents =
            (List<Map<String, Object>>) request.getAttribute(
                "archivedStudents"
            );
    %>

    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Original ID</th>
                    <th>Roll No.</th>
                    <th>Full Name</th>
                    <th>Email</th>
                    <th>Deleted At</th>
                    <th>Expires At</th>
                    <th>Action</th>
                </tr>
            </thead>

            <tbody>
            <%
                if (archivedStudents != null
                        && !archivedStudents.isEmpty()) {

                    for (Map<String, Object> student : archivedStudents) {
            %>
                <tr>
                    <td><%= student.get("studentId") %></td>
                    <td><%= student.get("rollNo") %></td>
                    <td><%= student.get("fullName") %></td>
                    <td><%= student.get("email") %></td>
                    <td><%= student.get("deletedAt") %></td>
                    <td><%= student.get("expiresAt") %></td>
                    <td>
                        <form method="post"
                              action="<%= request.getContextPath() %>/students/restore"
                              onsubmit="return confirm('Restore this student?');">

                            <input type="hidden"
                                   name="archiveId"
                                   value="<%= student.get("archiveId") %>">

                            <button type="submit" class="restore-btn">
                                Restore
                            </button>
                        </form>
                    </td>
                </tr>
            <%
                    }
                } else {
            %>
                <tr>
                    <td colspan="7" class="empty">
                        No students are currently available for restoration.
                    </td>
                </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>

</div>
</body>
</html>
