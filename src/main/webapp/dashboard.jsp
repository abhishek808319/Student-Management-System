
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Dashboard - Student Management System</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            color: #1e293b;
        }

        header {
            background: #1e3a8a;
            color: white;
            padding: 24px;
            text-align: center;
        }

        header h1 {
            margin: 0 0 8px;
        }

        header p {
            margin: 0;
        }

        main {
            max-width: 1000px;
            margin: 40px auto;
            padding: 20px;
        }

        .card {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 15px #0001;
        }

        .stat {
            margin: 20px 0 28px;
            padding: 25px;
            background: #eff6ff;
            border-radius: 10px;
            text-align: center;
        }

        .number {
            font-size: 42px;
            font-weight: bold;
            color: #2563eb;
        }

        .button-container {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-top: 20px;
        }

        .button {
            display: inline-block;
            padding: 12px 22px;
            background: #2563eb;
            color: white;
            text-decoration: none;
            text-align: center;
            border-radius: 6px;
            transition: background 0.2s ease;
        }

        .button:hover {
            background: #1d4ed8;
        }

        .archive-button {
            background: #b45309;
        }

        .archive-button:hover {
            background: #92400e;
        }

        .activity-button {
            background: #047857;
        }

        .activity-button:hover {
            background: #065f46;
        }

        .section-title {
            margin-top: 30px;
            margin-bottom: 12px;
            font-size: 18px;
        }

        @media (max-width: 600px) {
            main {
                margin: 20px auto;
                padding: 12px;
            }

            .card {
                padding: 20px;
            }

            .button-container {
                flex-direction: column;
            }

            .button {
                width: 100%;
            }
        }
    </style>
</head>

<body>

    <header>
        <h1>Student Management System</h1>
        <p>Dashboard</p>
    </header>

    <main>
        <div class="card">

            <h2>Overview</h2>

            <div class="stat">
                <p>Total Students</p>
                <div class="number">${totalStudents}</div>
            </div>

            <h3 class="section-title">Student Management</h3>

            <div class="button-container">

                <a class="button"
                   href="${pageContext.request.contextPath}/students">
                    Manage Students
                </a>

                <a class="button"
                   href="${pageContext.request.contextPath}/students/add">
                    Add Student
                </a>

                <a class="button"
                   href="${pageContext.request.contextPath}/courses">
                    Course Management
                </a>
                
<a href="<%= request.getContextPath() %>/teacher-attendance.jsp"
   class="button">
    <span>📋</span> Attendance
</a>
                
<div class="feature-card">
    <h3>Marks Management</h3>
    <p>
        Enter and update student marks, view results,
        calculate percentages, and analyze performance.
    </p>
    <a class="button"
       href="${pageContext.request.contextPath}/teacher-marks.jsp">
        Teacher Marks
    </a>
</div>
                

            </div>

            <h3 class="section-title">History and Recovery</h3>

            <div class="button-container">

                <a class="button archive-button"
                   href="${pageContext.request.contextPath}/students/archive">
                    Archived Students
                </a>

                <a class="button activity-button"
                   href="${pageContext.request.contextPath}/activity-logs">
                    Activity Log
                </a>

            </div>

            <div class="button-container">

                <a class="button"
                   href="${pageContext.request.contextPath}/">
                    Home
                </a>

            </div>

        </div>
    </main>

</body>
</html>
