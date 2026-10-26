<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Teacher Marks Management</title>
<style>
*{box-sizing:border-box}
body{margin:0;padding:24px;font-family:Arial,sans-serif;background:#f1f5f9;color:#1e293b}
.container{max-width:1100px;margin:auto;padding:24px;background:white;border-radius:12px;box-shadow:0 4px 18px #0000000d}
.header,.controls,.actions{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px}
.controls{justify-content:flex-start;margin:24px 0}
select,input,button,.button{padding:10px 12px;border:1px solid #cbd5e1;border-radius:7px;font-size:14px}
button,.button{cursor:pointer;background:#2563eb;color:white;border:0;text-decoration:none;display:inline-block}
button:disabled{opacity:.5;cursor:not-allowed}
input[type=number]{width:110px}
.table-wrap{overflow:auto;margin-top:18px}
table{border-collapse:collapse;width:100%;min-width:650px}
th,td{padding:12px;border-bottom:1px solid #e2e8f0;text-align:left}
th{background:#eff6ff}
.message{padding:12px;margin:14px 0;background:#f8fafc;border-radius:7px;white-space:pre-wrap}
.error{color:#b91c1c;background:#fef2f2}
.success{color:#166534;background:#f0fdf4}
.hint{font-size:13px;color:#64748b}
@media(max-width:600px){body{padding:10px}.container{padding:14px}}
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <div>
            <h1>Marks Management</h1>
            <p>Enter, save, and update student marks.</p>
        </div>
        <a class="button" href="<%= contextPath %>/dashboard.jsp">Back to Dashboard</a>
    </div>

    <div class="controls">
        <label>Course:
            <select id="courseSelect"><option value="">Loading courses...</option></select>
        </label>
        <label>Subject:
            <select id="subjectSelect" disabled><option value="">Select subject</option></select>
        </label>
        <label>Total marks:
            <input id="totalMarks" type="number" min="1" max="1000" step="any" value="100">
        </label>
        <button id="loadButton" type="button">Load Students</button>
    </div>

    <p class="hint">Enter marks between zero and the maximum marks. Existing marks can be edited and saved again.</p>
    <div id="message" class="message">Loading courses...</div>

    <div id="tableArea" hidden>
        <div class="table-wrap">
            <table id="marksTable">
                <thead>
                    <tr><th>Roll Number</th><th>Student Name</th><th>Obtained Marks</th><th>Percentage</th></tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
        <div class="actions" style="margin-top:18px">
            <span id="summary" class="hint"></span>
            <button id="saveButton" type="button">Save Marks</button>
        </div>
    </div>
</div>

<script>
"use strict";

const API_BASE = "http://127.0.0.1:5000";
const courseSelect = document.getElementById("courseSelect");
const subjectSelect = document.getElementById("subjectSelect");
const totalMarksInput = document.getElementById("totalMarks");
const loadButton = document.getElementById("loadButton");
const saveButton = document.getElementById("saveButton");
const message = document.getElementById("message");
const tableArea = document.getElementById("tableArea");
const tbody = document.querySelector("#marksTable tbody");
const summary = document.getElementById("summary");

let currentStudents = [];

function showMessage(text, type) {
    message.textContent = text;
    message.className = "message" + (type ? " " + type : "");
}

async function apiFetch(url, options) {
    const response = await fetch(url, options || {});
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
        throw new Error(data.error || ("HTTP " + response.status));
    }
    return data;
}

async function loadCourses() {
    courseSelect.disabled = true;
    try {
        const data = await apiFetch(API_BASE + "/api/courses");
        courseSelect.replaceChildren(new Option("Select course", ""));
        (data.courses || []).forEach(course => {
            courseSelect.add(new Option(
                course.course_name + " (" + course.total_students + " students)",
                course.course_id
            ));
        });
        showMessage("Select a course and subject.");
    } catch (error) {
        showMessage("Could not load courses: " + error.message, "error");
    } finally {
        courseSelect.disabled = false;
    }
}

async function loadSubjects() {
    subjectSelect.replaceChildren(new Option("Select subject", ""));
    subjectSelect.disabled = true;
    tableArea.hidden = true;

    if (!courseSelect.value) return;

    try {
        // The existing course attendance endpoint returns the course subjects.
        const data = await apiFetch(
            API_BASE + "/api/courses/" + courseSelect.value + "/attendance"
        );
        (data.subjects || []).forEach(subject => {
            subjectSelect.add(new Option(
                subject.subject_name,
                subject.subject_id
            ));
        });
        subjectSelect.disabled = false;
        showMessage("Select a subject and click Load Students.");
    } catch (error) {
        showMessage("Could not load subjects: " + error.message, "error");
    }
}

function updateSummary() {
    const total = Number(totalMarksInput.value);
    const inputs = [...tbody.querySelectorAll(".obtained")];
    let valid = Number.isFinite(total) && total > 0;
    let sum = 0;

    inputs.forEach(input => {
        const value = Number(input.value);
        if (input.value === "" || !Number.isFinite(value) || value < 0 || value > total) {
            valid = false;
        } else {
            sum += value;
        }

        const percentageCell = input.closest("tr").querySelector(".percentage");
        percentageCell.textContent =
            input.value !== "" && total > 0 && value >= 0 && value <= total
                ? (value / total * 100).toFixed(2) + "%"
                : "—";
    });

    summary.textContent = inputs.length
        ? inputs.length + " students · Average: " +
          (sum / inputs.length).toFixed(2) + " / " +
          (Number.isFinite(total) && total > 0 ? total : "—")
        : "No students loaded";

    saveButton.disabled = !valid || inputs.length === 0;
}

async function loadStudents() {
    const courseId = courseSelect.value;
    const subjectId = subjectSelect.value;

    if (!courseId || !subjectId) {
        showMessage("Please select a course and subject.", "error");
        return;
    }

    loadButton.disabled = true;
    saveButton.disabled = true;
    tableArea.hidden = true;

    try {
        const data = await apiFetch(
            API_BASE + "/api/courses/" + courseId +
            "/marks?subject_id=" + encodeURIComponent(subjectId)
        );

        currentStudents = data.students || [];
        tbody.replaceChildren();

        currentStudents.forEach(student => {
            const row = document.createElement("tr");
            const rollCell = document.createElement("td");
            const nameCell = document.createElement("td");
            const marksCell = document.createElement("td");
            const percentageCell = document.createElement("td");

            rollCell.textContent = student.roll_no || "";
            nameCell.textContent = student.full_name || "";

            const input = document.createElement("input");
            input.type = "number";
            input.className = "obtained";
            input.min = "0";
            input.max = totalMarksInput.value;
            input.step = "any";
            input.required = true;
            input.dataset.studentId = student.student_id;
            input.value = student.obtained_marks == null
                ? "" : student.obtained_marks;
            input.addEventListener("input", updateSummary);

            marksCell.appendChild(input);
            percentageCell.className = "percentage";
            percentageCell.textContent = "—";

            row.append(rollCell, nameCell, marksCell, percentageCell);
            tbody.appendChild(row);
        });

        tableArea.hidden = false;
        showMessage(
            data.course.course_name + " — " + data.subject.subject_name +
            ": loaded " + currentStudents.length + " enrolled students.",
            "success"
        );
        updateSummary();
    } catch (error) {
        showMessage("Could not load students: " + error.message, "error");
    } finally {
        loadButton.disabled = false;
    }
}

async function saveMarks() {
    const courseId = courseSelect.value;
    const subjectId = subjectSelect.value;
    const totalMarks = Number(totalMarksInput.value);
    const inputs = [...tbody.querySelectorAll(".obtained")];

    if (!courseId || !subjectId || !Number.isFinite(totalMarks) ||
        totalMarks <= 0 || inputs.length === 0) {
        showMessage("Select a course and subject, then load students.", "error");
        return;
    }

    const records = [];
    for (const input of inputs) {
        const value = Number(input.value);
        if (input.value === "" || !Number.isFinite(value) ||
            value < 0 || value > totalMarks) {
            showMessage(
                "Enter valid marks from 0 to " + totalMarks + " for every student.",
                "error"
            );
            input.focus();
            return;
        }
        records.push({
            student_id: Number(input.dataset.studentId),
            obtained_marks: value
        });
    }

    saveButton.disabled = true;
    loadButton.disabled = true;
    showMessage("Saving marks...");

    try {
        const data = await apiFetch(
            API_BASE + "/api/courses/" + courseId + "/marks",
            {
                method: "POST",
                headers: {"Content-Type": "application/json"},
                body: JSON.stringify({
                    subject_id: Number(subjectId),
                    total_marks: totalMarks,
                    records: records
                })
            }
        );

        showMessage(
            data.message + " Saved " + data.saved_records + " student records.",
            "success"
        );
        await loadStudents();
    } catch (error) {
        showMessage("Could not save marks: " + error.message, "error");
    } finally {
        saveButton.disabled = false;
        loadButton.disabled = false;
        updateSummary();
    }
}

courseSelect.addEventListener("change", loadSubjects);
loadButton.addEventListener("click", loadStudents);
saveButton.addEventListener("click", saveMarks);
totalMarksInput.addEventListener("input", updateSummary);

loadCourses();
</script>
</body>
</html>
