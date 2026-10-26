<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Student Records</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            color: #1e293b;
            margin: 0;
            padding: 30px;
        }

        .container {
            max-width: 1100px;
            margin: auto;
        }

        .panel {
            background: white;
            padding: 24px;
            border-radius: 12px;
            margin-top: 20px;
            box-shadow: 0 4px 14px rgba(0, 0, 0, .06);
        }

        h1 {
            color: #1d4ed8;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }

        th {
            background: #eaf1ff;
        }

        .button {
            display: inline-block;
            padding: 10px 16px;
            background: #1d4ed8;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            margin-top: 10px;
        }
.edit-link {
            background: #dc2626;
            color: white;
            border: 0;
                padding: 5px 15px;
            border-radius: 4px;
            cursor: pointer;
            margin: 2px;
            text-decoration: none;
     }
        .table-wrap {
            overflow-x: auto;
        }

        .search-form {
            margin: 20px 0;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }

        .search-form input {
            padding: 10px;
            width: 280px;
            max-width: 100%;
            box-sizing: border-box;
        }

        .search-form button {
            padding: 10px 18px;
            background: #2563eb;
            color: white;
            border: 0;
            border-radius: 5px;
            cursor: pointer;
        }



        .delete-button {
            background: #dc2626;
            color: white;
            border: 0;
            padding: 6px 10px;
                margin-top: 7px;
            border-radius: 4px;
            cursor: pointer;
        }

        .message {
            padding: 12px;
            margin: 12px 0;
            border-radius: 6px;
        }

        @media (max-width: 600px) {
            body {
                padding: 15px;
            }

            .panel {
                padding: 15px;
            }
        }
    </style>
</head>

<body>
<div class="container">

    <h1>Student Management System</h1>
    <p>View all registered student records.</p>

    <a class="button"
       href="${pageContext.request.contextPath}/">
        Home
    </a>

    <div class="panel">
        <h2>Student Records</h2>

        <c:if test="${not empty sessionScope.successMessage}">
            <div class="message"
                 style="background:#dcfce7; color:#166534;">
                <c:out value="${sessionScope.successMessage}"/>
            </div>
            <c:remove var="successMessage" scope="session"/>
        </c:if>

        <c:if test="${not empty requestScope.errorMessage}">
            <div class="message"
                 style="background:#fee2e2; color:#991b1b;">
                <c:out value="${requestScope.errorMessage}"/>
            </div>
        </c:if>

        <a class="button"
           href="${pageContext.request.contextPath}/students/add">
            + Add Student
        </a>

        <form class="search-form"
              method="get"
              action="${pageContext.request.contextPath}/students">

            <input type="text"
                   name="search"
                   value="<c:out value='${param.search}'/>"
                   placeholder="Search by roll number or name...">

            <button type="submit">Search</button>

            <a href="${pageContext.request.contextPath}/students"
               style="padding:10px; text-decoration:none;">
                Clear
            </a>
        </form>

        <div class="table-wrap">
            <table>
                <thead>
                <tr>
                    <th>ID</th>
                    <th>Roll Number</th>
                    <th>Full Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Course</th>
                    <th>Action</th>
                </tr>
                </thead>

                <tbody>
                <c:forEach var="student" items="${students}">
                    <tr>
                        <td>
                            <c:out value="${student.studentId}"/>
                        </td>

                        <td>
                            <c:out value="${student.rollNo}"/>
                        </td>

                        <td>
                            <a href="${pageContext.request.contextPath}/students/profile?id=${student.studentId}"
                               style="color:#2563eb; text-decoration:none; font-weight:600;">
                                <c:out value="${student.fullName}"/>
                            </a>
                        </td>

                        <td>
                            <c:out value="${student.email}"/>
                        </td>

                        <td>
                            <c:out value="${student.phone}"/>
                        </td>

                        <td>
                            <c:out value="${student.course}"/>
                        </td>

                        <td>

                            <a class="edit-link"
                               href="${pageContext.request.contextPath}/students/edit?id=${student.studentId}">
                                Edit
                            </a>

                            <form method="post"
                                  action="${pageContext.request.contextPath}/students/delete"
                                  style="display:inline;"
                                  onsubmit="return confirm('Are you sure you want to delete this student?');">

                                <input type="hidden"
                                       name="id"
                                       value="<c:out value='${student.studentId}'/>">

                                <button class="delete-button" type="submit">
                                    Delete
                                </button>
                            </form>
                        </td>
                    </tr>
                </c:forEach>

                <c:if test="${empty students}">
                    <tr>
                        <td colspan="7">No student records found.</td>
                    </tr>
                </c:if>
                </tbody>
            </table>
        </div>
    </div>

    <a class="button"
       href="${pageContext.request.contextPath}/students">
        Refresh Student Records
    </a>

</div>
</body>
</html>
