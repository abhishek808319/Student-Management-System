
<%@ page contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1">
    <title>Add Student</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f1f5f9;
            margin: 0;
            padding: 30px;
            color: #1e293b;
        }

        .container {
            max-width: 600px;
            margin: 30px auto;
            background: white;
            padding: 28px;
            border-radius: 12px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, .08);
        }

        h1 {
            color: #1d4ed8;
        }

        label {
            display: block;
            margin-top: 16px;
            margin-bottom: 6px;
            font-weight: bold;
        }

        input {
            width: 100%;
            box-sizing: border-box;
            padding: 12px;
            border: 1px solid #cbd5e1;
            border-radius: 6px;
        }

        button, .back {
            display: inline-block;
            margin-top: 22px;
            padding: 12px 18px;
            border: none;
            border-radius: 6px;
            background: #1d4ed8;
            color: white;
            text-decoration: none;
            cursor: pointer;
        }

        .back {
            background: #475569;
            margin-left: 8px;
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

    <h1>Register New Student</h1>
    <p>Enter the student's basic details.</p>

<% if (request.getAttribute("errorMessage") != null) { %>
    <div style="background:#fee2e2; color:#991b1b;
                padding:12px; margin:12px 0;
                border-radius:6px;">
        <%= request.getAttribute("errorMessage") %>
    </div>
<% } %>

    <form method="post"
          action="${pageContext.request.contextPath}/students/add" enctype="multipart/form-data">

        <label for="rollNo">Roll Number *</label>
        <input type="text" id="rollNo" name="rollNo"
               maxlength="30" required pattern="[A-Za-z0-9]+"
       title="Use letters and numbers only, without spaces.">

        <label for="fullName">Full Name *</label>
        <input type="text" id="fullName" name="fullName"
               maxlength="100" required>

        <label for="email">Email</label>
        <input type="email" id="email" name="email"
               maxlength="120" title="Enter a valid email address.">

        <label for="phone">Phone</label>
        <input type="tel" id="phone" name="phone"
               pattern="[0-9]{10}"
       maxlength="10"
       minlength="10"
       title="Enter exactly 10 digits."
       inputmode="numeric">
        


<label for="course">Course</label>
<select id="course" name="course" required>
    <option value="">-- Select Course --</option>

    <%
        java.util.List<com.sms.model.Course> courses =
            (java.util.List<com.sms.model.Course>)
                request.getAttribute("courses");

        if (courses != null) {
            for (com.sms.model.Course c : courses) {
    %>
        <option value="<%= c.getCourseName() %>">
            <%= c.getCourseName() %>
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
        style="width:100%; padding:10px; box-sizing:border-box;"></textarea>
</div>


<div class="form-group">
    <label for="profilePicture">Profile Picture</label>

    <input
        type="file"
        id="profilePicture"
        name="profilePicture"
        accept="image/jpeg,image/png,image/webp"
    >

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
                alt="Crop your profile picture"
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


        <button type="submit">Save Student</button>

        <a class="back"
           href="${pageContext.request.contextPath}/students">
            Back to Students
        </a>
    </form>

</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
    const fileInput = document.getElementById("profilePicture");
    const container = document.getElementById("cropperContainer");
    const image = document.getElementById("imageToCrop");
    const croppedImageInput = document.getElementById("croppedImage");
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
        preview.innerHTML = "";
        croppedImageInput.value = "";
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
                center: true,
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
            croppedImageInput.value = "";
            preview.innerHTML = "";
            cropApplied = false;
        }
    });

    document.getElementById("applyCrop").addEventListener("click", function () {
        if (!cropper) {
            alert("Please select an image first.");
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
                croppedImageInput.value = reader.result;

                preview.innerHTML = "";

                const result = document.createElement("img");
                result.src = reader.result;
                result.alt = "Cropped profile picture";
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
            alert("Please click Apply Crop before submitting your photo.");
        }
    });
});
</script>
</body>
</html>

