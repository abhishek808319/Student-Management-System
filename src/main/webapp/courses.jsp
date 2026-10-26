
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" import="java.util.List,com.sms.model.Course" %>

<%
    List<Course> courses =
        (List<Course>) request.getAttribute("courses");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Course Management</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f3f4f6;
            margin: 0;
            padding: 30px;
        }

        .container {
            max-width: 1000px;
            margin: auto;
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
        }

        h1 {
            color: #1f2937;
            margin-top: 0;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        th, td {
            padding: 14px;
            text-align: left;
            border-bottom: 1px solid #e5e7eb;
        }

        th {
            background: #2563eb;
            color: white;
        }

        tr:hover {
            background: #f9fafb;
        }

        .back-link {
            display: inline-block;
            margin-top: 22px;
            color: #2563eb;
            text-decoration: none;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        .empty {
            padding: 20px;
            color: #6b7280;
        }
    </style>
</head>

<body>
    <div class="container">
        <h1>Course Management</h1>
        <p>View all courses registered in the system.</p>
        
<%
    String successMessage =
        (String) session.getAttribute("successMessage");

    if (successMessage != null) {
        session.removeAttribute("successMessage");
    }
%>

<% if (successMessage != null) { %>
    <p style="color:green; font-weight:bold;">
        <%= successMessage %>
    </p>
<% } %>

<h2>Add New Course</h2>

<form action="<%= request.getContextPath() %>/courses/add"
      method="post"
      style="display:flex; flex-wrap:wrap; gap:12px; align-items:end;">

    <div>
        <label for="courseName">Course Name</label><br>
        <input
            type="text"
            id="courseName"
            name="courseName"
            maxlength="150"
            required
            style="padding:10px; width:280px; margin-top:6px;">
    </div>

    <div>
        <label for="semester">Semester</label><br>
        <input
            type="number"
            id="semester"
            name="semester"
            min="1"
            max="99"
            required
            style="padding:10px; width:100px; margin-top:6px;">
    </div>

    <button type="submit"
            style="padding:11px 20px; background:#2563eb; color:white; border:0; border-radius:6px; cursor:pointer;">
        Add Course
    </button>
</form>
        

        <table>
            <thead>
                <tr>
                    <th>Course ID</th>
                    <th>Course Name</th>
                    <th>Semester</th>
                </tr>
            </thead>

            <tbody>
                <% if (courses != null && !courses.isEmpty()) {
                    for (Course course : courses) { %>

                    <tr>
                        <td><%= course.getCourseId() %></td>
                        <td><%= course.getCourseName() %></td>
                        <td><%= course.getSemester() %></td>
                    </tr>

                <%  }
                   } else { %>

                    <tr>
                        <td colspan="3" class="empty">
                            No courses found.
                        </td>
                    </tr>

                <% } %>
            </tbody>
        </table>

        <a class="back-link"
           href="<%= request.getContextPath() %>/students">
            &larr; Back to Student List
        </a>
    </div>
</body>
</html>
