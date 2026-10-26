<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
    String contextPath = request.getContextPath();
    String studentIdParam = request.getParameter("id");
    int studentId = -1;
    try {
        studentId = Integer.parseInt(studentIdParam);
    } catch (Exception ignored) {
        studentId = -1;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>My Marks and Results</title>
<style>
*{box-sizing:border-box}
body{margin:0;padding:24px;background:#f1f5f9;color:#172033;font-family:Arial,sans-serif}
.container{max-width:1100px;margin:auto;background:#fff;border-radius:14px;padding:24px;box-shadow:0 5px 22px #0f172a0c}
.top{display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap}
h1{margin:0 0 8px}p{color:#64748b}
.button{display:inline-block;text-decoration:none;border:0;border-radius:8px;background:#2563eb;color:#fff;padding:11px 15px;cursor:pointer}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:14px;margin:24px 0}
.card{padding:18px;border:1px solid #e2e8f0;border-radius:10px;background:#f8fafc}
.card small{color:#64748b}.value{font-size:26px;font-weight:700;margin-top:8px}
.message{padding:12px;border-radius:8px;background:#f8fafc;margin:16px 0;white-space:pre-wrap}
.error{background:#fef2f2;color:#b91c1c}
.success{background:#f0fdf4;color:#166534}
.table-wrap{overflow:auto}
table{border-collapse:collapse;width:100%;min-width:560px;margin-top:12px}
th,td{padding:12px;border-bottom:1px solid #e2e8f0;text-align:left}
th{background:#eff6ff}
.chartbox{margin-top:24px;padding:18px;border:1px solid #e2e8f0;border-radius:10px}
canvas{width:100%;height:320px;display:block}
.hint{font-size:13px;color:#64748b}
@media(max-width:600px){body{padding:10px}.container{padding:15px}}
</style>
</head>
<body>
<div class="container">
  <div class="top">
    <div>
      <h1>Marks and Results</h1>
      <p id="studentDetails">Loading student details and marks...</p>
    </div>
    <a class="button" href="<%= contextPath %>/student-profile.jsp?id=<%= studentId %>">Back to Profile</a>
  </div>

  <div id="message" class="message">Loading marks...</div>
  <div class="cards">
    <div class="card"><small>Subjects with marks</small><div class="value" id="subjectCount">—</div></div>
    <div class="card"><small>Total obtained</small><div class="value" id="obtainedTotal">—</div></div>
    <div class="card"><small>Total possible</small><div class="value" id="possibleTotal">—</div></div>
    <div class="card"><small>Overall percentage</small><div class="value" id="overallPercentage">—</div></div>
  </div>

  <h2>Subject-wise Marks</h2>
  <div class="table-wrap">
    <table>
      <thead><tr><th>Subject</th><th>Obtained</th><th>Total</th><th>Percentage</th><th>Grade</th></tr></thead>
      <tbody id="marksBody"><tr><td colspan="5">Loading...</td></tr></tbody>
    </table>
  </div>

  <div class="chartbox">
    <h2>Performance Graph</h2>
    <p class="hint">Bars show the student's percentage for each subject with saved marks.</p>
    <canvas id="marksChart" width="1000" height="320" aria-label="Subject marks percentage bar chart"></canvas>
  </div>
</div>

<script>
"use strict";
const studentId = <%= studentId %>;
const API_BASE = "http://127.0.0.1:5000";
const message = document.getElementById("message");

function showMessage(text, type) {
  message.textContent = text;
  message.className = "message" + (type ? " " + type : "");
}
function gradeFor(p) {
  if (p >= 90) return "A+";
  if (p >= 80) return "A";
  if (p >= 70) return "B";
  if (p >= 60) return "C";
  if (p >= 50) return "D";
  return "Needs improvement";
}
function drawChart(rows) {
  const canvas = document.getElementById("marksChart");
  const ctx = canvas.getContext("2d");
  const width = canvas.width, height = canvas.height;
  ctx.clearRect(0, 0, width, height);
  if (!rows.length) {
    ctx.fillStyle = "#64748b";
    ctx.font = "18px Arial";
    ctx.fillText("No saved marks available to graph yet.", 24, 45);
    return;
  }
  const left = 55, right = 20, top = 24, bottom = 82;
  const plotW = width - left - right, plotH = height - top - bottom;
  ctx.font = "13px Arial";
  ctx.strokeStyle = "#cbd5e1";
  ctx.fillStyle = "#475569";
  for (let pct = 0; pct <= 100; pct += 20) {
    const y = top + plotH - (pct / 100) * plotH;
    ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(width - right, y); ctx.stroke();
    ctx.fillText(pct + "%", 8, y + 4);
  }
  const slot = plotW / rows.length;
  const barW = Math.min(90, slot * 0.58);
  rows.forEach((r, i) => {
    const pct = Math.max(0, Math.min(100, r.percentage));
    const barH = (pct / 100) * plotH;
    const x = left + i * slot + (slot - barW) / 2;
    const y = top + plotH - barH;
    ctx.fillStyle = "#2563eb";
    ctx.fillRect(x, y, barW, barH);
    ctx.fillStyle = "#0f172a";
    ctx.textAlign = "center";
    ctx.fillText(pct.toFixed(1) + "%", x + barW / 2, Math.max(15, y - 7));
    const label = r.subject_name.length > 13 ? r.subject_name.slice(0, 12) + "…" : r.subject_name;
    ctx.save();
    ctx.translate(x + barW / 2, top + plotH + 18);
    ctx.rotate(-0.35);
    ctx.fillText(label, 0, 0);
    ctx.restore();
  });
  ctx.textAlign = "left";
}
async function loadMarks() {
  if (studentId <= 0) {
    showMessage("A valid student ID is missing. Open this page from a student's profile.", "error");
    document.getElementById("marksBody").innerHTML = '<tr><td colspan="5">No student selected.</td></tr>';
    drawChart([]);
    return;
  }
  try {
    const response = await fetch(`${API_BASE}/api/students/${studentId}/marks`);
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Could not load marks.");

    const student = data.student || {};
    const rows = data.marks || [];
    document.getElementById("studentDetails").textContent =
      `${student.full_name || "Student"} · Roll No: ${student.roll_no || "—"}`;

    let obtainedTotal = 0, possibleTotal = 0;
    const validRows = rows.map(r => {
      const total = Number(r.total_marks);
      const obtained = Number(r.obtained_marks);
      const percentage = total > 0 ? obtained / total * 100 : 0;
      return {...r, total: total, obtained: obtained, percentage: percentage};
    }).filter(r => Number.isFinite(r.total) && r.total > 0 && Number.isFinite(r.obtained));

    const body = document.getElementById("marksBody");
    body.replaceChildren();
    if (!validRows.length) {
      const tr = document.createElement("tr"), td = document.createElement("td");
      td.colSpan = 5; td.textContent = "No marks have been saved for this student yet.";
      tr.appendChild(td); body.appendChild(tr);
    } else {
      validRows.forEach(r => {
        obtainedTotal += r.obtained; possibleTotal += r.total;
        const tr = document.createElement("tr");
        [r.subject_name, r.obtained.toFixed(2), r.total.toFixed(2),
         r.percentage.toFixed(2) + "%", gradeFor(r.percentage)].forEach(value => {
          const td = document.createElement("td"); td.textContent = value; tr.appendChild(td);
        });
        body.appendChild(tr);
      });
    }
    document.getElementById("subjectCount").textContent = validRows.length;
    document.getElementById("obtainedTotal").textContent = obtainedTotal.toFixed(2);
    document.getElementById("possibleTotal").textContent = possibleTotal.toFixed(2);
    document.getElementById("overallPercentage").textContent =
      possibleTotal > 0 ? (obtainedTotal / possibleTotal * 100).toFixed(2) + "%" : "—";
    drawChart(validRows);
    showMessage(validRows.length ? "Marks loaded successfully." : "No saved marks found yet.", validRows.length ? "success" : "");
  } catch (error) {
    showMessage("Could not load marks: " + error.message, "error");
    document.getElementById("marksBody").innerHTML = '<tr><td colspan="5">Unable to load marks.</td></tr>';
    drawChart([]);
  }
}
loadMarks();
</script>
</body>
</html>
