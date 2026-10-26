
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="com.sms.model.Student" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.util.Objects" %>

<%
    Student student = (Student) request.getAttribute("student");

    if (student == null) {
        response.sendError(
            jakarta.servlet.http.HttpServletResponse.SC_NOT_FOUND,
            "Student not found."
        );
        return;
    }

    String contextPath = request.getContextPath();
    int studentId = student.getStudentId();

    String photo = student.getProfilePicture();
    boolean hasPhoto = photo != null && !photo.trim().isEmpty();

    String studentName = Objects.toString(student.getFullName(), "");
    String rollNo = Objects.toString(student.getRollNo(), "");
    String courseName = Objects.toString(
        student.getCourse(), "Course not assigned"
    );

    String encodedPhoto = hasPhoto
        ? URLEncoder.encode(photo, StandardCharsets.UTF_8)
        : "";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Student Profile | Student Management System</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            margin: 0;
            padding: 30px 15px;
            color: #1e293b;
        }

        .container {
            max-width: 1050px;
            margin: auto;
        }

        .profile-card,
        .section-card {
            background: #fff;
            border-radius: 14px;
            padding: 25px;
            margin-bottom: 22px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.06);
        }

        .profile-header {
            display: flex;
            align-items: center;
            gap: 22px;
            flex-wrap: wrap;
            margin-bottom: 30px;
        }

        .profile-picture {
            width: 125px;
            height: 125px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid #dbeafe;
            flex-shrink: 0;
        }

        .avatar-placeholder {
            display: flex;
            align-items: center;
            justify-content: center;
            background: #dbeafe;
            color: #1d4ed8;
            font-size: 48px;
            font-weight: bold;
        }

        h1, h2, h3 {
            color: #172554;
        }

        .subtitle {
            color: #64748b;
            margin-top: 8px;
            overflow-wrap: anywhere;
        }

        .details {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
        }

        .detail {
            padding: 15px;
            background: #f8fafc;
            border-radius: 8px;
            overflow-wrap: anywhere;
        }

        .label {
            display: block;
            color: #64748b;
            font-size: 13px;
            margin-bottom: 8px;
        }

        .value {
            font-weight: 600;
            overflow-wrap: anywhere;
        }

        .actions {
            margin-top: 25px;
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }

        .button {
            display: inline-block;
            padding: 11px 16px;
            background: #2563eb;
            color: white;
            border: none;
            border-radius: 7px;
            text-decoration: none;
            font-size: 14px;
            cursor: pointer;
        }

        .button:hover {
            background: #1d4ed8;
        }

        .button:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }

        .secondary {
            background: #475569;
        }

        .secondary:hover {
            background: #334155;
        }

        .section-description {
            color: #64748b;
            line-height: 1.6;
        }

        .subject-form {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 15px;
            margin-top: 20px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .form-group label {
            font-size: 14px;
            font-weight: 600;
        }

        .form-group input,
        .form-group select {
            width: 100%;
            padding: 11px;
            border: 1px solid #cbd5e1;
            border-radius: 7px;
            font-size: 14px;
            background: white;
        }

        .form-submit {
            grid-column: 1 / -1;
            justify-self: start;
        }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 16px;
            margin-top: 20px;
        }

        .feature-card {
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 18px;
        }

        .feature-card p {
            color: #64748b;
            font-size: 14px;
            line-height: 1.6;
        }

        .feature-card .button {
            margin-top: 8px;
        }

        .notice {
            padding: 13px;
            background: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 8px;
            color: #1e40af;
            font-size: 14px;
            line-height: 1.6;
        }

        .message {
            margin-top: 14px;
            line-height: 1.6;
            overflow-wrap: anywhere;
        }

        .subject-list {
            margin-top: 20px;
        }

        @media (max-width: 600px) {
            body {
                padding: 15px 10px;
            }

            .profile-card,
            .section-card {
                padding: 18px;
            }

            .details,
            .subject-form,
            .feature-grid {
                grid-template-columns: 1fr;
            }

            .form-submit {
                grid-column: auto;
            }
        }
    </style>
</head>

<body>
<div class="container">

    <!-- Student profile -->
    <section class="profile-card">

        <div class="profile-header">
            <% if (hasPhoto) { %>
                <img
                    class="profile-picture"
                    src="<%= contextPath %>/uploads/<%= encodedPhoto %>"
                    alt="Student profile picture">
            <% } else { %>
                <div class="profile-picture avatar-placeholder">
                    <%= studentName.isEmpty()
                        ? "S"
                        : studentName.substring(0, 1).toUpperCase() %>
                </div>
            <% } %>

            <div>
                <h1><%= studentName %></h1>

                <div class="subtitle">
                    Roll Number: <%= rollNo %>
                </div>

                <div class="subtitle"><%= courseName %></div>

                <div class="subtitle">
                    Student ID: <%= studentId %>
                </div>
            </div>
        </div>

        <h2>Personal Details</h2>

        <div class="details">
            <div class="detail">
                <span class="label">Full Name</span>
                <span class="value">
                    <%= studentName.isEmpty()
                        ? "Not provided" : studentName %>
                </span>
            </div>

            <div class="detail">
                <span class="label">Roll Number</span>
                <span class="value">
                    <%= rollNo.isEmpty()
                        ? "Not provided" : rollNo %>
                </span>
            </div>

            <div class="detail">
                <span class="label">Email</span>
                <span class="value">
                    <%= student.getEmail() == null
                        ? "Not provided" : student.getEmail() %>
                </span>
            </div>

            <div class="detail">
                <span class="label">Phone</span>
                <span class="value">
                    <%= student.getPhone() == null
                        ? "Not provided" : student.getPhone() %>
                </span>
            </div>

            <div class="detail">
                <span class="label">Course</span>
                <span class="value"><%= courseName %></span>
            </div>

            <div class="detail">
                <span class="label">Address</span>
                <span class="value">
                    <%= student.getAddress() == null
                        || student.getAddress().trim().isEmpty()
                        ? "Not provided" : student.getAddress() %>
                </span>
            </div>
        </div>

        <div class="actions">
            <a class="button"
               href="<%= contextPath %>/students/edit?id=<%= studentId %>">
                Edit Student
            </a>

            <a class="button secondary"
               href="<%= contextPath %>/students">
                Back to Student List
            </a>
        </div>
    </section>

    <!-- Subject management -->
    <section class="section-card">
        <h2>My Subjects</h2>

        <p class="section-description">
            Add subjects directly from this profile. Enrolled subjects
            will be available for subject-wise attendance and marks.
        </p>

        <div class="notice">
            Student ID: <strong><%= studentId %></strong>.
            Subjects are managed through the Python backend.
        </div>

        <form class="subject-form" id="subjectForm">
            <div class="form-group">
                <label for="subjectName">Subject Name</label>
                <input
                    type="text"
                    id="subjectName"
                    name="subject_name"
                    maxlength="100"
                    placeholder="e.g. Python Programming"
                    required>
            </div>

            <div class="form-group">
                <label for="semester">Semester</label>
                <select id="semester" name="semester" required>
                    <option value="">Select semester</option>
                    <option value="1">Semester 1</option>
                    <option value="2">Semester 2</option>
                    <option value="3">Semester 3</option>
                    <option value="4">Semester 4</option>
                </select>
            </div>

            <div class="form-group form-submit">
                <button type="submit" class="button" id="addSubjectButton">
                    Add Subject
                </button>
            </div>
        </form>

        <div id="subjectMessage"
             class="message"
             role="status"
             aria-live="polite"></div>

        <div id="subjectList" class="subject-list">
            <p class="section-description">Loading subjects...</p>
        </div>
    </section>

    <!-- Attendance and marks -->
    <section class="section-card">
        <h2>Academic Records</h2>

        <div class="feature-grid">
            <div class="feature-card">
                <h3>Attendance</h3>
                <p>
                    View daily attendance, subject-wise presence,
                    absences, and attendance percentage.
                </p>

                <a class="button"
                   href="<%= contextPath %>/students/attendance?id=<%= studentId %>">
                    View Attendance
                </a>
            </div>

            <div class="feature-card">
                <h3>Marks and Results</h3>
                <p>
                    View subject-wise marks, exam results, totals,
                    percentages, and grades.
                </p>

                <a class="button"
                   href="<%= contextPath %>/student-marks.jsp?id=<%= studentId %>">
                    View Marks
                </a>
            </div>
        </div>
    </section>

</div>

<script>
(() => {
    "use strict";

    // These values are generated by this JSP for the current student.
    const studentId = <%= studentId %>;
    const flaskBaseUrl = "http://127.0.0.1:5000";
    const subjectsUrl =
        flaskBaseUrl + "/api/students/" + studentId + "/subjects";

    const subjectForm = document.getElementById("subjectForm");
    const subjectMessage = document.getElementById("subjectMessage");
    const subjectList = document.getElementById("subjectList");
    const addSubjectButton = document.getElementById("addSubjectButton");

    function showMessage(message, isError = false) {
        subjectMessage.textContent = message;
        subjectMessage.style.color = isError ? "#b91c1c" : "#166534";
    }

    async function readJsonResponse(response) {
        const contentType = response.headers.get("content-type") || "";

        if (!contentType.includes("application/json")) {
            throw new Error(
                "The server returned a non-JSON response. " +
                "Check the Flask URL and server logs."
            );
        }

        return await response.json();
    }

    async function loadSubjects() {
        subjectList.textContent = "Loading subjects...";

        try {
            console.log("Loading subjects from:", subjectsUrl);

            const response = await fetch(subjectsUrl, {
                method: "GET",
                headers: {
                    "Accept": "application/json"
                }
            });

            const data = await readJsonResponse(response);

            if (!response.ok) {
                throw new Error(
                    data.error || "Unable to load subjects. HTTP " +
                    response.status
                );
            }

            subjectList.replaceChildren();

            if (!Array.isArray(data.subjects) ||
                data.subjects.length === 0) {
                subjectList.textContent = "No subjects enrolled yet.";
                return;
            }

            const list = document.createElement("div");
            list.className = "details";

            data.subjects.forEach(subject => {
                const item = document.createElement("div");
                item.className = "detail";

                const name = document.createElement("strong");
                name.textContent = subject.subject_name || "Unnamed subject";

                const semester = document.createElement("div");
                semester.className = "subtitle";
                semester.textContent =
                    "Semester " + String(subject.semester);

                item.append(name, semester);
                list.appendChild(item);
            });

            subjectList.appendChild(list);

        } catch (error) {
            console.error("Load subjects error:", error);

            subjectList.textContent =
                "Could not load subjects. Check the Console for the " +
                "request URL and error details.";

            showMessage(
                error.message || "Unable to connect to the Python backend.",
                true
            );
        }
    }

    subjectForm.addEventListener("submit", async event => {
        event.preventDefault();

        const subjectName =
            document.getElementById("subjectName").value.trim();

        const semester =
            document.getElementById("semester").value;

        if (!subjectName || !semester) {
            showMessage(
                "Enter a subject name and select a semester.",
                true
            );
            return;
        }

        addSubjectButton.disabled = true;
        showMessage("Saving subject...");

        try {
            console.log("Adding subject through:", subjectsUrl);

            const response = await fetch(subjectsUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                },
                body: JSON.stringify({
                    subject_name: subjectName,
                    semester: Number(semester)
                })
            });

            const data = await readJsonResponse(response);

            if (!response.ok) {
                throw new Error(
                    data.error || "Unable to add subject. HTTP " +
                    response.status
                );
            }

            showMessage(data.message || "Subject enrolled successfully.");
            subjectForm.reset();

            await loadSubjects();

        } catch (error) {
            console.error("Subject enrollment error:", error);

            showMessage(
                error.message ||
                "Unable to connect to the Python backend.",
                true
            );

        } finally {
            addSubjectButton.disabled = false;
        }
    });

    loadSubjects();
})();
</script>

</body>
</html>
