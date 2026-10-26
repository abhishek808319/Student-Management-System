
package com.sms.servlet;

import com.sms.dao.StudentDAO;
import com.sms.dao.ActivityLogger;
import com.sms.model.Student;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.SQLIntegrityConstraintViolationException;
import java.util.Base64;
import java.util.UUID;

import javax.imageio.ImageIO;

@WebServlet("/students/update")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 5 * 1024 * 1024,
    maxRequestSize = 8 * 1024 * 1024
)
public class StudentUpdateServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final StudentDAO studentDAO = new StudentDAO();
    private final ActivityLogger activityLogger = new ActivityLogger();

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        int studentId;

        try {
            studentId = Integer.parseInt(
                request.getParameter("studentId")
            );
        } catch (NumberFormatException e) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid student ID."
            );
            return;
        }

        if (studentId <= 0) {
            response.sendError(
                HttpServletResponse.SC_BAD_REQUEST,
                "Invalid student ID."
            );
            return;
        }

        try {
            // Retrieve the existing student before updating.
            Student currentStudent = studentDAO.findById(studentId);

            if (currentStudent == null) {
                response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Student not found."
                );
                return;
            }

            String rollNo = request.getParameter("rollNo");
            String fullName = request.getParameter("fullName");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String course = request.getParameter("course");
            String address = request.getParameter("address");
            String croppedImage = request.getParameter("croppedImage");

            String errorMessage = null;

            // Validate student details.
            if (rollNo == null
                    || !rollNo.matches("[A-Za-z0-9]{1,30}")) {

                errorMessage =
                    "Roll number must contain only letters and numbers (maximum 30 characters).";

            } else if (email != null
                    && !email.trim().isEmpty()
                    && (email.length() > 120
                    || !email.matches(
                        "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
                    ))) {

                errorMessage = "Please enter a valid email address.";

            } else if (phone != null
                    && !phone.trim().isEmpty()
                    && !phone.matches("[0-9]{10}")) {

                errorMessage =
                    "Phone number must contain exactly 10 digits.";

            } else if (address != null && address.length() > 500) {

                errorMessage = "Address must not exceed 500 characters.";
            }

            if (errorMessage != null) {
                request.setAttribute("errorMessage", errorMessage);
                request.setAttribute("student", currentStudent);

                request.getRequestDispatcher("/edit-student.jsp")
                       .forward(request, response);
                return;
            }

            // Keep the existing photo unless a cropped replacement is supplied.
            String uploadedFileName = currentStudent.getProfilePicture();

            if (croppedImage != null && !croppedImage.isBlank()) {

                String prefix = "data:image/jpeg;base64,";

                if (!croppedImage.startsWith(prefix)) {
                    request.setAttribute(
                        "errorMessage",
                        "Invalid cropped image. Please crop the photo again."
                    );
                    request.setAttribute("student", currentStudent);

                    request.getRequestDispatcher("/edit-student.jsp")
                           .forward(request, response);
                    return;
                }

                String base64Data =
                    croppedImage.substring(prefix.length());

                if (base64Data.length() > 4_000_000) {
                    request.setAttribute(
                        "errorMessage",
                        "Cropped photo is too large. Please use a smaller image."
                    );
                    request.setAttribute("student", currentStudent);

                    request.getRequestDispatcher("/edit-student.jsp")
                           .forward(request, response);
                    return;
                }

                byte[] imageBytes;

                try {
                    imageBytes = Base64.getDecoder().decode(base64Data);
                } catch (IllegalArgumentException e) {
                    request.setAttribute(
                        "errorMessage",
                        "Invalid image data. Please crop the photo again."
                    );
                    request.setAttribute("student", currentStudent);

                    request.getRequestDispatcher("/edit-student.jsp")
                           .forward(request, response);
                    return;
                }

                BufferedImage image;

                try (ByteArrayInputStream input =
                        new ByteArrayInputStream(imageBytes)) {

                    image = ImageIO.read(input);
                }

                if (image == null
                        || image.getWidth() != 400
                        || image.getHeight() != 400) {

                    request.setAttribute(
                        "errorMessage",
                        "Invalid cropped image. Please crop the photo again."
                    );
                    request.setAttribute("student", currentStudent);

                    request.getRequestDispatcher("/edit-student.jsp")
                           .forward(request, response);
                    return;
                }

                String uploadDirectory =
                    getServletContext().getRealPath("/uploads");

                if (uploadDirectory == null) {
                    throw new ServletException(
                        "Upload directory is unavailable."
                    );
                }

                Path uploadPath = Paths.get(uploadDirectory)
                                       .toAbsolutePath()
                                       .normalize();

                Files.createDirectories(uploadPath);

                uploadedFileName = UUID.randomUUID() + ".jpg";

                Path imagePath = uploadPath.resolve(uploadedFileName)
                                           .normalize();

                if (!imagePath.startsWith(uploadPath)) {
                    throw new ServletException("Invalid image path.");
                }

                if (!ImageIO.write(image, "jpg", imagePath.toFile())) {
                    throw new ServletException(
                        "Unable to save the cropped photo."
                    );
                }
            }

            /*
             * Capture the original values before updating the database.
             */
            String oldData =
                    "{\"rollNo\":\"" + jsonEscape(currentStudent.getRollNo()) + "\","
                  + "\"fullName\":\"" + jsonEscape(currentStudent.getFullName()) + "\","
                  + "\"email\":\"" + jsonEscape(currentStudent.getEmail()) + "\","
                  + "\"phone\":\"" + jsonEscape(currentStudent.getPhone()) + "\","
                  + "\"course\":\"" + jsonEscape(currentStudent.getCourse()) + "\","
                  + "\"address\":\"" + jsonEscape(currentStudent.getAddress()) + "\","
                  + "\"profilePicture\":\"" + jsonEscape(currentStudent.getProfilePicture()) + "\"}";

            // Build the updated student record.
            Student student = new Student();

            student.setStudentId(studentId);
            student.setRollNo(rollNo);
            student.setFullName(fullName);

            student.setEmail(
                email == null || email.trim().isEmpty()
                    ? null : email.trim()
            );

            student.setPhone(
                phone == null || phone.trim().isEmpty()
                    ? null : phone.trim()
            );

            student.setCourse(course);
            student.setAddress(address);
            student.setProfilePicture(uploadedFileName);

            // Build the new values before updating.
            String newData =
                    "{\"rollNo\":\"" + jsonEscape(student.getRollNo()) + "\","
                  + "\"fullName\":\"" + jsonEscape(student.getFullName()) + "\","
                  + "\"email\":\"" + jsonEscape(student.getEmail()) + "\","
                  + "\"phone\":\"" + jsonEscape(student.getPhone()) + "\","
                  + "\"course\":\"" + jsonEscape(student.getCourse()) + "\","
                  + "\"address\":\"" + jsonEscape(student.getAddress()) + "\","
                  + "\"profilePicture\":\"" + jsonEscape(student.getProfilePicture()) + "\"}";

            // Update the database first.
            studentDAO.update(student);

            // Log the activity only after the update succeeds.
            activityLogger.logStudentActivity(
                studentId,
                "UPDATE",
                "Updated student: " + student.getFullName(),
                oldData,
                newData
            );

            request.getSession().setAttribute(
                "successMessage",
                "Student updated successfully!"
            );

            response.sendRedirect(
                request.getContextPath() + "/students"
            );

        } catch (SQLIntegrityConstraintViolationException e) {

            throw new ServletException(
                "These details conflict with an existing record. "
                + "Please check the roll number and email.",
                e
            );

        } catch (ServletException e) {

            throw e;

        } catch (Exception e) {

            throw new ServletException(
                "Unable to update student.", e
            );
        }
    }

    // Escape special characters before storing values as JSON.
    private String jsonEscape(String value) {

        if (value == null) {
            return "";
        }

        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
