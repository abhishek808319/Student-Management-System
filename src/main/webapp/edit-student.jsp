
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Student</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            margin: 0;
            padding: 30px;
        }
        .container {
            max-width: 500px;
            margin: 30px auto;
            padding: 25px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 4px 15px #0001;
        }
        h2 { text-align: center; color: #1e293b; }
        label {
            display: block;
            margin-top: 15px;
            font-weight: bold;
        }
        input {
            box-sizing: border-box;
            width: 100%;
            padding: 11px;
            margin-top: 6px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
        }
        button {
            width: 100%;
            padding: 12px;
            margin-top: 22px;
            background: #2563eb;
            color: white;
            border: none;
            border-radius: 6px;
            cursor: pointer;
        }
        .button-backToStudentList{
                background: #2563eb;
            color: white;
            border: 0;
            padding: 6px 10px;
            border-radius: 4px;
            cursor: pointer;
            margin: 2px;
            text-decoration: none;
        }
    </style>
    
<link
    rel="stylesheet"
    href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.css"
/>

<script
    src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.2/cropper.min.js">
</script>
    
</head>
<body>
<div class="container">
    <h2>Edit Student</h2>

<% if (request.getAttribute("errorMessage") != null) { %>
    <div style="background:#fee2e2; color:#991b1b;
                padding:12px; margin:12px 0;
                border-radius:6px;">
        <%= request.getAttribute("errorMessage") %>
    </div>
<% } %>

    <form method="post"
          action="${pageContext.request.contextPath}/students/update" enctype="multipart/form-data">

        <input type="hidden" name="studentId"
               value="<c:out value='${student.studentId}'/>">

        <label>Roll Number</label>
        <input type="text" name="rollNo" required
               value="<c:out value='${student.rollNo}'/>" required
maxlength="30"
pattern="[A-Za-z0-9]+"
title="Use letters and numbers only, without spaces.">

        <label>Full Name</label>
        <input type="text" name="fullName" required
               value="<c:out value='${student.fullName}'/>">

        <label>Email</label>
        <input type="email" name="email"
               value="<c:out value='${student.email}'/>"
maxlength="120"
title="Enter a valid email address.">

        <label>Phone</label>
        <input type="text" name="phone"
               value="<c:out value='${student.phone}'/>"
pattern="[0-9]{10}"
minlength="10"
maxlength="10"
inputmode="numeric"
title="Enter exactly 10 digits.">


<label for="course">Course</label>

<label for="course">Course</label>


<%
    com.sms.model.Student student =
        (com.sms.model.Student) request.getAttribute("student");

    java.util.List<com.sms.model.Course> courses =
        (java.util.List<com.sms.model.Course>)
            request.getAttribute("courses");
%>

<label for="course">Course</label>

<select id="course" name="course" required>
    <option value="">-- Select Course --</option>

    <%
        if (courses != null) {
            for (com.sms.model.Course c : courses) {
                String courseName = c.getCourseName();
                boolean selected = student != null
                    && courseName.equals(student.getCourse());
    %>
        <option value="<%= courseName %>"
                <%= selected ? "selected" : "" %>>
            <%= courseName %>
        </option>
    <%
            }
        }
    %>
</select>



<div class="form-group">
    <label for="address">Residential Address</label>
    <textarea
        id="address"
        name="address"
        maxlength="500"
        rows="3"
        placeholder="Enter student's full address"
        style="width:100%; padding:10px; box-sizing:border-box;"><%= request.getAttribute("student") != null ? ((com.sms.model.Student) request.getAttribute("student")).getAddress() : "" %></textarea>
</div>

<%
    com.sms.model.Student profileStudent =
        (com.sms.model.Student) request.getAttribute("student");

    if (profileStudent != null
            && profileStudent.getProfilePicture() != null
            && !profileStudent.getProfilePicture().isEmpty()) {
%>
    <div class="form-group">
        <label>Current Profile Picture</label>
        <img
            src="${pageContext.request.contextPath}/uploads/<%= java.net.URLEncoder.encode(profileStudent.getProfilePicture(), "UTF-8") %>"
            alt="Student profile picture"
            style="width:120px; height:120px; object-fit:cover;
                   border-radius:50%; display:block; margin:10px 0;">
    </div>
<%
    }
%>


<div class="form-group">
    <label for="profilePicture">Change Profile Picture</label>

    <input
        type="file"
        id="profilePicture"
        name="profilePicture"
        accept="image/jpeg,image/png,image/webp"
    >

    <small>Optional. Select a photo to crop, or leave empty to keep the current picture.</small>

    <div id="cropperContainer" style="display:none; margin-top:15px;">
        <div style="
            width:280px;
            height:280px;
            border-radius:50%;
            overflow:hidden;
            border:3px solid #2563eb;
            margin:15px auto;
        ">
            <img
                id="imageToCrop"
                src=""
                alt="Crop your new profile picture"
                style="display:block; max-width:100%;"
            >
        </div>

        <div style="
            display:flex;
            justify-content:center;
            flex-wrap:wrap;
            gap:10px;
            margin-bottom:15px;
        ">
            <button type="button" id="zoomIn">Zoom In +</button>
            <button type="button" id="zoomOut">Zoom Out −</button>
            <button type="button" id="resetCrop">Reset</button>
            <button type="button" id="applyCrop">Apply Crop</button>
        </div>
    </div>

    <div id="croppedPreview" style="margin-top:15px;"></div>

    <input type="hidden" name="croppedImage" id="croppedImage">
</div>



        <button type="submit">Update Student</button>
    </form>

    <p style="text-align:center">
        <a class="button-backToStudentList" href="${pageContext.request.contextPath}/students">
            Back to Student List
        </a>
    </p>
</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
    const fileInput = document.getElementById("profilePicture");
    const container = document.getElementById("cropperContainer");
    const image = document.getElementById("imageToCrop");
    const croppedInput = document.getElementById("croppedImage");
    const preview = document.getElementById("croppedPreview");
    const form = fileInput.closest("form");

    let cropper = null;
    let imageUrl = null;
    let cropApplied = false;

    fileInput.addEventListener("change", function () {
        const file = fileInput.files[0];

        if (!file) return;

        if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
            alert("Please select a JPG, PNG, or WebP image.");
            fileInput.value = "";
            return;
        }

        if (file.size > 5 * 1024 * 1024) {
            alert("Image size must not exceed 5 MB.");
            fileInput.value = "";
            return;
        }

        if (cropper) {
            cropper.destroy();
            cropper = null;
        }

        if (imageUrl) {
            URL.revokeObjectURL(imageUrl);
        }

        imageUrl = URL.createObjectURL(file);
        image.src = imageUrl;
        container.style.display = "block";
        preview.replaceChildren();
        croppedInput.value = "";
        cropApplied = false;

        image.onload = function () {
            cropper = new Cropper(image, {
                aspectRatio: 1,
                viewMode: 1,
                dragMode: "move",
                autoCropArea: 0.8,
                responsive: true,
                background: false,
                guides: false,
                movable: true,
                zoomable: true,
                cropBoxMovable: false,
                cropBoxResizable: false,
                toggleDragModeOnDblclick: false
            });
        };
    });

    document.getElementById("zoomIn").addEventListener("click", function () {
        if (cropper) cropper.zoom(0.1);
    });

    document.getElementById("zoomOut").addEventListener("click", function () {
        if (cropper) cropper.zoom(-0.1);
    });

    document.getElementById("resetCrop").addEventListener("click", function () {
        if (cropper) {
            cropper.reset();
            croppedInput.value = "";
            preview.replaceChildren();
            cropApplied = false;
        }
    });

    document.getElementById("applyCrop").addEventListener("click", function () {
        if (!cropper) {
            alert("Please select a photo first.");
            return;
        }

        const canvas = cropper.getCroppedCanvas({
            width: 400,
            height: 400,
            imageSmoothingEnabled: true,
            imageSmoothingQuality: "high"
        });

        if (!canvas) {
            alert("Unable to crop this image. Please try another.");
            return;
        }

        canvas.toBlob(function (blob) {
            if (!blob) {
                alert("Unable to process the cropped image.");
                return;
            }

            const reader = new FileReader();

            reader.onloadend = function () {
                croppedInput.value = reader.result;
                preview.replaceChildren();

                const result = document.createElement("img");
                result.src = reader.result;
                result.alt = "Cropped photo preview";
                result.style.width = "100px";
                result.style.height = "100px";
                result.style.objectFit = "cover";
                result.style.borderRadius = "50%";
                result.style.border = "2px solid #2563eb";

                preview.appendChild(result);
                cropApplied = true;
            };

            reader.readAsDataURL(blob);
        }, "image/jpeg", 0.9);
    });

    form.addEventListener("submit", function (event) {
        if (fileInput.files.length > 0 && !cropApplied) {
            event.preventDefault();
            alert("Please click Apply Crop before updating the student.");
        }
    });
});
</script>
</body>
</html>

</html>
