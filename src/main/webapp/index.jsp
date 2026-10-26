
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Management System</title>
    <style>
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
        main {
            max-width: 900px;
            margin: 40px auto;
            padding: 20px;
        }
        .card {
            background: white;
            padding: 30px;
            border-radius: 12px;
            text-align: center;
            box-shadow: 0 4px 15px #0001;
        }
        .button {
            display: inline-block;
            margin-top: 15px;
            padding: 12px 22px;
            background: #2563eb;
            color: white;
            text-decoration: none;
            border-radius: 6px;
        }
    </style>
</head>
<body>
    <header>
        <h1>Student Management System</h1>

    </header>

    <main>
        <div class="card">
            <h2>Welcome!</h2>
            <p>Manage student records from one place.</p>


<a class="button"
   href="${pageContext.request.contextPath}/dashboard">
    Open Dashboard
</a>

<a class="button"
   href="${pageContext.request.contextPath}/students">
    View Students
</a>

        </div>
    </main>
</body>
</html>
