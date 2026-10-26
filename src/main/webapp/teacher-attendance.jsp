<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="true" %>
<%
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Teacher Attendance</title>
<style>
*{box-sizing:border-box}
body{margin:0;padding:24px;font-family:Arial,sans-serif;background:#f1f5f9;color:#1e293b}
.container{max-width:1400px;margin:auto;padding:24px;background:#fff;border-radius:12px;box-shadow:0 4px 18px #0000000d}
.header,.controls,.actions{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px}
.controls{justify-content:flex-start;margin:24px 0}
select,input[type=date],button,.button{padding:10px 14px;border:1px solid #cbd5e1;border-radius:7px;font-size:14px}
button,.button{cursor:pointer;text-decoration:none;background:#2563eb;color:#fff;border:0;display:inline-block}
button:disabled{opacity:.55;cursor:not-allowed}
.table-wrap{overflow:auto;max-height:65vh;border:1px solid #e2e8f0;border-radius:8px}
table{border-collapse:collapse;width:100%;min-width:700px}
th,td{padding:12px;border-bottom:1px solid #e2e8f0;text-align:center}
th{background:#eff6ff;position:sticky;top:0;z-index:1}
th:first-child,td:first-child{text-align:left;position:sticky;left:0;background:#f8fafc;z-index:2}
th:first-child{z-index:3}
.student-name{font-weight:600}.roll{color:#64748b;font-size:12px;margin-top:4px}
input[type=checkbox]{width:19px;height:19px;cursor:pointer;accent-color:#16a34a}
.message{margin:14px 0;padding:12px;border-radius:7px;background:#f8fafc;white-space:pre-wrap}
.error{color:#b91c1c;background:#fef2f2}.success{color:#166534;background:#f0fdf4}
.hint{color:#64748b;font-size:13px}
@media(max-width:600px){body{padding:10px}.container{padding:14px}}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <div><h1>Course Attendance</h1><p>Mark attendance for all students and subjects in a course.</p></div>
    <a class="button" href="<%= contextPath %>/dashboard.jsp">Back to Dashboard</a>
  </div>

  <div class="controls">
    <label>Course: <select id="courseSelect"><option value="">Loading courses...</option></select></label>
    <label>Attendance date: <input type="date" id="attendanceDate"></label>
    <button type="button" id="loadButton">Load Attendance</button>
  </div>

  <p class="hint">Checked means Present. Unchecked means Absent. Existing attendance for the selected date can be edited and saved again.</p>
  <div id="message" class="message">Loading courses...</div>

  <div id="tableArea" hidden>
    <div class="table-wrap">
      <table id="attendanceTable"><thead></thead><tbody></tbody></table>
    </div>
    <div class="actions" style="margin-top:18px">
      <span id="summary" class="hint"></span>
      <button type="button" id="saveButton" onclick="saveAttendance()">Save Attendance</button>
    </div>
  </div>
</div>

<script>
"use strict";

// Flask API URL. Do not replace this with the Tomcat URL.
const API_BASE = "http://127.0.0.1:5000";
const courseSelect = document.getElementById("courseSelect");
const attendanceDate = document.getElementById("attendanceDate");
const loadButton = document.getElementById("loadButton");
const saveButton = document.getElementById("saveButton");
const message = document.getElementById("message");
const tableArea = document.getElementById("tableArea");
const table = document.getElementById("attendanceTable");
const summary = document.getElementById("summary");

let currentStudents = [];
let currentSubjects = [];
let existingAttendance = [];

function showMessage(text, type) {
  message.textContent = text;
  message.className = "message" + (type ? " " + type : "");
}

function localToday() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return year + "-" + month + "-" + day;
}

async function apiFetch(url, options) {
  const response = await fetch(url, options || {});
  const data = await response.json().catch(function () { return {}; });
  if (!response.ok) {
    throw new Error(data.error || ("Request failed: HTTP " + response.status));
  }
  return data;
}

async function loadCourses() {
  courseSelect.disabled = true;
  showMessage("Loading courses...");
  try {
    const data = await apiFetch(API_BASE + "/api/courses");
    courseSelect.replaceChildren();

    const placeholder = document.createElement("option");
    placeholder.value = "";
    placeholder.textContent = "Select a course";
    courseSelect.appendChild(placeholder);

    (data.courses || []).forEach(function (course) {
      const option = document.createElement("option");
      option.value = course.course_id;
      option.textContent = course.course_name + " (" +
        course.total_students + " students)";
      courseSelect.appendChild(option);
    });
    showMessage("Choose a course and date, then click Load Attendance.");
  } catch (error) {
    showMessage("Could not load courses: " + error.message, "error");
  } finally {
    courseSelect.disabled = false;
  }
}

async function loadAttendance() {
  const courseId = courseSelect.value;
  const selectedDate = attendanceDate.value;

  if (!courseId) {
    showMessage("Please select a course.", "error");
    return;
  }
  if (!selectedDate) {
    showMessage("Please select an attendance date.", "error");
    return;
  }

  loadButton.disabled = true;
  saveButton.disabled = true;
  tableArea.hidden = true;
  showMessage("Loading students, subjects, and saved attendance...");

  try {
    const url = API_BASE + "/api/courses/" + courseId +
      "/attendance?date=" + encodeURIComponent(selectedDate);
    const data = await apiFetch(url);

    currentStudents = data.students || [];
    currentSubjects = data.subjects || [];
    existingAttendance = data.attendance || [];
    renderAttendanceTable();
    tableArea.hidden = false;

    if (currentStudents.length === 0) {
      showMessage("No students are enrolled in this course.");
    } else if (currentSubjects.length === 0) {
      showMessage("This course has no subjects yet. Add course subjects first.", "error");
    } else {
      showMessage(data.course.course_name + ": " + currentStudents.length +
        " students, " + currentSubjects.length + " subjects.", "success");
    }
  } catch (error) {
    showMessage("Could not load attendance: " + error.message, "error");
  } finally {
    loadButton.disabled = false;
    updateSummary();
  }
}

function renderAttendanceTable() {
  const thead = table.querySelector("thead");
  const tbody = table.querySelector("tbody");
  thead.replaceChildren();
  tbody.replaceChildren();

  const headerRow = document.createElement("tr");
  const studentHeader = document.createElement("th");
  studentHeader.textContent = "Student";
  headerRow.appendChild(studentHeader);

  currentSubjects.forEach(function (subject) {
    const th = document.createElement("th");
    th.textContent = subject.subject_name;
    if (subject.semester) th.title = "Semester " + subject.semester;
    headerRow.appendChild(th);
  });
  thead.appendChild(headerRow);

  const savedMap = new Map();
  existingAttendance.forEach(function (record) {
    savedMap.set(String(record.student_id) + "-" + String(record.subject_id),
      String(record.status).toUpperCase());
  });

  currentStudents.forEach(function (student) {
    const row = document.createElement("tr");
    const nameCell = document.createElement("td");
    const name = document.createElement("div");
    name.className = "student-name";
    name.textContent = student.full_name || "";
    const roll = document.createElement("div");
    roll.className = "roll";
    roll.textContent = student.roll_no || "";
    nameCell.appendChild(name);
    nameCell.appendChild(roll);
    row.appendChild(nameCell);

    currentSubjects.forEach(function (subject) {
      const cell = document.createElement("td");
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.className = "attendance-checkbox";
      checkbox.dataset.studentId = student.student_id;
      checkbox.dataset.subjectId = subject.subject_id;
      checkbox.setAttribute("aria-label", (student.full_name || "Student") +
        " - " + subject.subject_name + " present");

      const key = String(student.student_id) + "-" + String(subject.subject_id);
      const status = savedMap.get(key);
      checkbox.checked = status === "PRESENT" || status === "LATE";
      cell.appendChild(checkbox);
      row.appendChild(cell);
    });
    tbody.appendChild(row);
  });
  updateSummary();
}

function updateSummary() {
  const boxes = Array.from(document.querySelectorAll(".attendance-checkbox"));
  const present = boxes.filter(function (box) { return box.checked; }).length;
  summary.textContent = present + " present out of " + boxes.length +
    " student-subject entries";
  saveButton.disabled = currentStudents.length === 0 || currentSubjects.length === 0;
}

table.addEventListener("change", function (event) {
  if (event.target.classList.contains("attendance-checkbox")) updateSummary();
});

async function saveAttendance() {
  const courseId = courseSelect.value;
  const selectedDate = attendanceDate.value;
  if (!courseId || !selectedDate) {
    showMessage("Select a course and date first.", "error");
    return;
  }
  if (currentStudents.length === 0 || currentSubjects.length === 0) {
    showMessage("There are no students or subjects to save.", "error");
    return;
  }

  const boxes = Array.from(document.querySelectorAll("#attendanceTable .attendance-checkbox"));
  if (boxes.length !== currentStudents.length * currentSubjects.length) {
    showMessage("Attendance table is incomplete. Click Load Attendance and try again.", "error");
    return;
  }

  const records = boxes.map(function (box) {
    return {
      student_id: Number(box.dataset.studentId),
      subject_id: Number(box.dataset.subjectId),
      status: box.checked ? "PRESENT" : "ABSENT"
    };
  });

  saveButton.disabled = true;
  loadButton.disabled = true;
  showMessage("Saving attendance...");

  try {
    showMessage("Sending " + records.length + " attendance records to the server...");
    const data = await apiFetch(
      API_BASE + "/api/courses/" + courseId + "/attendance",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          attendance_date: selectedDate,
          records: records
        })
      }
    );

    if (typeof data.saved_records !== "number") {
      showMessage(
        (data.message || "Server responded successfully.") +
        " The server did not report a saved-record count. Reloading to verify.",
        "success"
      );
    } else {
      showMessage(
        (data.message || "Attendance saved.") + " Saved " +
        data.saved_records + " records.",
        "success"
      );
    }

    await loadAttendance();
  } catch (error) {
    showMessage("Could not save attendance: " + error.message, "error");
  } finally {
    saveButton.disabled = false;
    loadButton.disabled = false;
  }
}

loadButton.addEventListener("click", loadAttendance);
// Inline onclick on the button calls this same function; expose it explicitly.
window.saveAttendance = saveAttendance;

const today = localToday();

function isSunday(dateString) {
    const date = new Date(dateString + "T12:00:00");
    return date.getDay() === 0;
}

function validateAttendanceDate() {
    const today = localToday();

    attendanceDate.max = today;

    if (attendanceDate.value > today) {
        attendanceDate.value = today;
    }

    if (isSunday(attendanceDate.value)) {
        showMessage(
            "Attendance cannot be marked on Sundays.",
            "error"
        );
        saveButton.disabled = true;
        return false;
    }

    saveButton.disabled = false;
    return true;
}

attendanceDate.value = localToday();
validateAttendanceDate();

attendanceDate.addEventListener(
    "change",
    validateAttendanceDate
);

if (attendanceDate.value > today) {
    attendanceDate.value = today;
}
loadCourses();
</script>
</body>
</html>
