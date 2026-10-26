<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="jakarta.servlet.http.HttpServletResponse" %>
<%
    Object studentIdObject = request.getAttribute("studentId");
    if (studentIdObject == null) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Student ID is missing.");
        return;
    }
    int studentId = (Integer) studentIdObject;
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Attendance</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f4f7fb; margin: 0; padding: 24px; color: #1f2937; }
        .container { max-width: 1100px; margin: auto; background: #fff; padding: 24px; border-radius: 12px; box-shadow: 0 3px 15px #00000010; }
        .topbar { display: flex; justify-content: space-between; align-items: center; gap: 12px; flex-wrap: wrap; }
        h1 { margin: 0 0 8px; }
        .button { display: inline-block; padding: 10px 15px; border-radius: 6px; background: #2563eb; color: #fff; text-decoration: none; border: none; cursor: pointer; font-size: 14px; }
        .button:hover { background: #1d4ed8; }
        .filters { display: flex; align-items: end; gap: 10px; flex-wrap: wrap; margin: 20px 0; }
        .filters label { display: flex; flex-direction: column; gap: 6px; font-size: 14px; color: #475569; }
        input { padding: 10px; border: 1px solid #cbd5e1; border-radius: 6px; }
        .summary-grid { display: grid; grid-template-columns: repeat(5, minmax(130px, 1fr)); gap: 12px; margin: 18px 0 24px; }
        .summary-card { padding: 16px; border: 1px solid #e2e8f0; border-radius: 10px; background: #fff; }
        .summary-card .label { color: #64748b; font-size: 13px; margin-bottom: 8px; }
        .summary-card .value { font-size: 25px; font-weight: 700; overflow-wrap: anywhere; }
        .chart-card, .subject-card { border: 1px solid #e2e8f0; border-radius: 10px; padding: 18px; margin: 16px 0; }
        .chart-card h2, .subject-card h2 { margin-top: 0; }
        .chart-note { color: #64748b; font-size: 13px; margin: 8px 0 0; }
        .chart-wrap { width: 100%; overflow-x: auto; }
        #attendanceChart { display: block; width: 100%; min-width: 320px; height: 320px; }
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { text-align: left; padding: 10px; border-bottom: 1px solid #e5e7eb; }
        th { background: #f8fafc; }
        .message { margin: 14px 0; color: #475569; }
        .present { color: #15803d; font-weight: bold; }
        .absent { color: #dc2626; font-weight: bold; }
        .late { color: #b45309; font-weight: bold; }
        .empty { color: #64748b; padding: 18px 0; }
        @media (max-width: 800px) { .summary-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } body { padding: 12px; } .container { padding: 16px; } }
        @media (max-width: 420px) { .summary-grid { grid-template-columns: 1fr 1fr; } .summary-card .value { font-size: 21px; } }
    </style>
</head>
<body>
<div class="container">
    <div class="topbar">
        <div>
            <h1>Attendance Records</h1>
            <p>Student ID: <%= studentId %></p>
        </div>
        <a class="button" href="<%= contextPath %>/students/profile?id=<%= studentId %>">Back to Student Profile</a>
    </div>

    <div class="filters">
        <label>From:
            <input type="date" id="fromDate">
        </label>
        <label>To:
            <input type="date" id="toDate">
        </label>
        <button class="button" type="button" id="filterButton">Filter</button>
        <button class="button" type="button" id="resetButton" style="background:#475569">Reset</button>
    </div>

    <div id="message" class="message">Loading attendance...</div>
    <div id="summary" class="summary-grid" hidden>
        <div class="summary-card"><div class="label">Total Classes</div><div class="value" id="totalClasses">0</div></div>
        <div class="summary-card"><div class="label">Present Days</div><div class="value present" id="presentDays">0</div></div>
        <div class="summary-card"><div class="label">Absent Days</div><div class="value absent" id="absentDays">0</div></div>
        <div class="summary-card"><div class="label">Late Days</div><div class="value late" id="lateDays">0</div></div>
        <div class="summary-card"><div class="label">Attendance</div><div class="value" id="attendancePercentage">0%</div></div>
    </div>

    <section class="chart-card" id="chartCard" hidden>
        <h2>Subject-wise Attendance</h2>
        <div class="chart-wrap"><svg id="attendanceChart" role="img" aria-label="Bar chart showing attended days by subject"></svg></div>
        <p class="chart-note">The chart shows days attended (PRESENT + LATE) for each subject in the selected date range.</p>
    </section>

    <div id="attendanceContainer"></div>
</div>

<script>
    const studentId = <%= studentId %>;
    const flaskBaseUrl = "http://127.0.0.1:5000";
    let allRecords = [];

    document.getElementById("filterButton").addEventListener("click", renderAttendance);
    document.getElementById("resetButton").addEventListener("click", function () {
        document.getElementById("fromDate").value = "";
        document.getElementById("toDate").value = "";
        renderAttendance();
    });

    function getRecordDate(record) {
        return String(record.attendance_date || record.date || "").slice(0, 10);
    }

    function getStatus(record) {
        return String(record.status || "UNKNOWN").trim().toUpperCase();
    }

    function renderAttendance() {
        const message = document.getElementById("message");
        const container = document.getElementById("attendanceContainer");
        const fromDate = document.getElementById("fromDate").value;
        const toDate = document.getElementById("toDate").value;
        container.innerHTML = "";

        if (fromDate && toDate && fromDate > toDate) {
            message.textContent = "The From date cannot be later than the To date.";
            hideStatistics();
            return;
        }

        const filtered = allRecords.filter(function (record) {
            const date = getRecordDate(record);
            return (!fromDate || date >= fromDate) && (!toDate || date <= toDate);
        });

        if (filtered.length === 0) {
            message.textContent = allRecords.length === 0
                ? "No attendance records have been recorded for this student yet."
                : "No attendance records found for this date range.";
            hideStatistics();
            return;
        }

        message.textContent = "Showing " + filtered.length + " attendance record(s).";
        const totals = { total: filtered.length, present: 0, absent: 0, late: 0 };
        const groups = new Map();

        filtered.forEach(function (record) {
            const status = getStatus(record);
            if (status === "PRESENT") totals.present++;
            else if (status === "ABSENT") totals.absent++;
            else if (status === "LATE") totals.late++;

            const subjectId = String(record.subject_id == null ? "unknown" : record.subject_id);
            const subjectName = record.subject_name || ("Subject " + subjectId);
            if (!groups.has(subjectId)) groups.set(subjectId, { name: subjectName, records: [], present: 0, absent: 0, late: 0 });
            const group = groups.get(subjectId);
            group.records.push(record);
            if (status === "PRESENT") group.present++;
            else if (status === "ABSENT") group.absent++;
            else if (status === "LATE") group.late++;
        });

        document.getElementById("summary").hidden = false;
        document.getElementById("totalClasses").textContent = totals.total;
        document.getElementById("presentDays").textContent = totals.present;
        document.getElementById("absentDays").textContent = totals.absent;
        document.getElementById("lateDays").textContent = totals.late;
        const percentage = totals.total ? ((totals.present + totals.late) / totals.total * 100) : 0;
        document.getElementById("attendancePercentage").textContent = percentage.toFixed(1) + "%";

        document.getElementById("chartCard").hidden = false;
        drawBarChart(Array.from(groups.values()));

        groups.forEach(function (group) {
            const card = document.createElement("section");
            card.className = "subject-card";
            const heading = document.createElement("h2");
            heading.textContent = group.name;
            card.appendChild(heading);

            const subjectTotal = group.records.length;
            const subjectAttended = group.present + group.late;
            const subjectPercent = subjectTotal ? (subjectAttended / subjectTotal * 100) : 0;
            const summaryLine = document.createElement("p");
            summaryLine.textContent = "Classes: " + subjectTotal + " | Present: " + group.present + " | Absent: " + group.absent + " | Late: " + group.late + " | Attendance: " + subjectPercent.toFixed(1) + "%";
            card.appendChild(summaryLine);

            const tableWrap = document.createElement("div");
            tableWrap.className = "table-wrap";
            const table = document.createElement("table");
            const thead = document.createElement("thead");
            const headerRow = document.createElement("tr");
            ["Date", "Status"].forEach(function (label) {
                const th = document.createElement("th");
                th.textContent = label;
                headerRow.appendChild(th);
            });
            thead.appendChild(headerRow);
            const tbody = document.createElement("tbody");

            group.records.slice().sort(function (a, b) {
                return getRecordDate(b).localeCompare(getRecordDate(a));
            }).forEach(function (record) {
                const tr = document.createElement("tr");
                const dateCell = document.createElement("td");
                const statusCell = document.createElement("td");
                dateCell.textContent = getRecordDate(record) || "-";
                const status = getStatus(record);
                statusCell.textContent = status;
                if (["PRESENT", "ABSENT", "LATE"].includes(status)) statusCell.className = status.toLowerCase();
                tr.appendChild(dateCell);
                tr.appendChild(statusCell);
                tbody.appendChild(tr);
            });
            table.appendChild(thead);
            table.appendChild(tbody);
            tableWrap.appendChild(table);
            card.appendChild(tableWrap);
            container.appendChild(card);
        });
    }

    function hideStatistics() {
        document.getElementById("summary").hidden = true;
        document.getElementById("chartCard").hidden = true;
        document.getElementById("attendanceContainer").innerHTML = "";
    }

    function drawBarChart(groups) {
        const svg = document.getElementById("attendanceChart");
        while (svg.firstChild) svg.removeChild(svg.firstChild);
        const ns = "http://www.w3.org/2000/svg";
        const width = Math.max(640, groups.length * 150 + 100);
        const height = 320;
        const left = 55, right = 25, top = 25, bottom = 85;
        const plotHeight = height - top - bottom;
        const maxValue = Math.max(1, ...groups.map(function (g) { return g.present + g.late; }));
        const tickMax = Math.max(1, Math.ceil(maxValue / 2) * 2);
        svg.setAttribute("viewBox", "0 0 " + width + " " + height);
        svg.setAttribute("width", width);
        svg.setAttribute("height", height);

        function add(tag, attrs, text) {
            const el = document.createElementNS(ns, tag);
            Object.keys(attrs || {}).forEach(function (key) { el.setAttribute(key, attrs[key]); });
            if (text != null) el.textContent = text;
            svg.appendChild(el);
            return el;
        }

        for (let tick = 0; tick <= tickMax; tick++) {
            const y = top + plotHeight - (tick / tickMax) * plotHeight;
            add("line", { x1: left, y1: y, x2: width - right, y2: y, stroke: "#e2e8f0", "stroke-width": 1 });
            add("text", { x: left - 12, y: y + 4, "text-anchor": "end", "font-size": 12, fill: "#64748b" }, String(tick));
        }
        add("line", { x1: left, y1: top, x2: left, y2: top + plotHeight, stroke: "#94a3b8" });
        add("line", { x1: left, y1: top + plotHeight, x2: width - right, y2: top + plotHeight, stroke: "#94a3b8" });
        add("text", { x: 16, y: top + plotHeight / 2, transform: "rotate(-90 16 " + (top + plotHeight / 2) + ")", "text-anchor": "middle", "font-size": 12, fill: "#475569" }, "Days attended");

        const slot = (width - left - right) / Math.max(1, groups.length);
        const barWidth = Math.min(60, slot * 0.55);
        groups.forEach(function (group, index) {
            const attended = group.present + group.late;
            const barHeight = (attended / tickMax) * plotHeight;
            const x = left + slot * index + (slot - barWidth) / 2;
            const y = top + plotHeight - barHeight;
            add("rect", { x: x, y: y, width: barWidth, height: barHeight, rx: 4, fill: "#2563eb" });
            add("text", { x: x + barWidth / 2, y: Math.max(top + 12, y - 7), "text-anchor": "middle", "font-size": 12, fill: "#1f2937" }, String(attended));
            const label = group.name.length > 18 ? group.name.slice(0, 16) + "…" : group.name;
            add("text", { x: x + barWidth / 2, y: top + plotHeight + 18, "text-anchor": "end", "font-size": 11, fill: "#475569", transform: "rotate(-35 " + (x + barWidth / 2) + " " + (top + plotHeight + 18) + ")" }, label);
        });
        if (groups.length === 0) add("text", { x: width / 2, y: height / 2, "text-anchor": "middle", "font-size": 14, fill: "#64748b" }, "No subject data");
    }

    async function loadAttendance() {
        const message = document.getElementById("message");
        message.textContent = "Loading attendance...";
        try {
            const response = await fetch(flaskBaseUrl + "/api/students/" + studentId + "/attendance");
            if (!response.ok) throw new Error("HTTP " + response.status);
            const data = await response.json();
            allRecords = Array.isArray(data) ? data : (data.attendance || data.records || []);
            if (!Array.isArray(allRecords)) allRecords = [];
            renderAttendance();
        } catch (error) {
            allRecords = [];
            hideStatistics();
            message.textContent = "Could not load attendance. Make sure the Flask server is running. " + error.message;
        }
    }

    loadAttendance();
</script>
</body>
</html>
