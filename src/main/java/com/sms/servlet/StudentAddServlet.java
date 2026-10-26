
package com.sms.servlet;

import com.sms.dao.ActivityLogger;
import com.sms.dao.CourseDAO;
import com.sms.dao.StudentDAO;
import com.sms.model.Course;
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
import java.util.List;
import java.util.UUID;

import javax.imageio.ImageIO;

@WebServlet("/students/add")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 5 * 1024 * 1024,
    maxRequestSize = 8 * 1024 * 1024
)
public class StudentAddServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private final StudentDAO studentDAO = new StudentDAO();
    private final CourseDAO courseDAO = new CourseDAO();
    private final ActivityLogger activityLogger = new ActivityLogger();

    // Load all courses from MySQL.
    private void loadCourses(HttpServletRequest request)
            throws ServletException {
        try {
            List<Course> courses = courseDAO.findAll();

            System.out.println("Courses loaded: " + courses.size());

            for (Course course : courses) {
                System.out.println(course.getCourseName());
            }

            request.setAttribute("courses", courses);
            System.out.println("Courses loaded: " + courses.size());

        } catch (Exception e) {
            throw new ServletException("Unable to load courses", e);
        }
    }

    // Open the Add Student form.
    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {
    	System.out.println("StudentAddServlet doGet is running!");
        loadCourses(request);

        request.getRequestDispatcher("/add-student.jsp")
               .forward(request, response);
    }

    // Process the Add Student form.
    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String rollNo = request.getParameter("rollNo");
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String course = request.getParameter("course");
        String address = request.getParameter("address");
        String croppedImage = request.getParameter("croppedImage");

        String uploadedFileName = null;
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
            loadCourses(request);

            request.getRequestDispatcher("/add-student.jsp")
                   .forward(request, response);
            return;
        }

        // Process the cropped JPEG image.
        if (croppedImage != null && !croppedImage.isBlank()) {

            try {
                String prefix = "data:image/jpeg;base64,";

                if (!croppedImage.startsWith(prefix)) {
                    throw new IllegalArgumentException(
                        "Invalid cropped image format."
                    );
                }

                String base64Data =
                    croppedImage.substring(prefix.length());

                if (base64Data.length() > 4_000_000) {
                    throw new IllegalArgumentException(
                        "Cropped image is too large."
                    );
                }

                byte[] imageBytes =
                    Base64.getDecoder().decode(base64Data);

                BufferedImage image;

                try (ByteArrayInputStream input =
                        new ByteArrayInputStream(imageBytes)) {
                    image = ImageIO.read(input);
                }

                if (image == null
                        || image.getWidth() != 400
                        || image.getHeight() != 400) {

                    throw new IllegalArgumentException(
                        "Invalid cropped image dimensions."
                    );
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

                uploadedFileName =
                    UUID.randomUUID().toString() + ".jpg";

                Path imagePath =
                    uploadPath.resolve(uploadedFileName).normalize();

                if (!imagePath.startsWith(uploadPath)) {
                    throw new ServletException("Invalid image path.");
                }

                if (!ImageIO.write(image, "jpg", imagePath.toFile())) {
                    throw new ServletException(
                        "Unable to save the cropped image."
                    );
                }

            } catch (IllegalArgumentException e) {

                request.setAttribute(
                    "errorMessage",
                    "Invalid cropped photo. Please select and crop the image again."
                );

                loadCourses(request);

                request.getRequestDispatcher("/add-student.jsp")
                       .forward(request, response);
                return;
            }
        }

        // Create the student record.
        Student student = new Student();
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

        try {
        	studentDAO.add(student);

        	System.out.println("DEBUG: Student inserted successfully.");

        	int savedStudentId = student.getStudentId();

        	System.out.println("DEBUG: Generated student ID = " + savedStudentId);
        	// The DAO should set the generated ID on this object.


        	if (savedStudentId > 0) {
        		System.out.println("DEBUG: Entered activity logging block.");
        	    String newData =
        	            "{\"rollNo\":\"" + jsonEscape(rollNo) + "\","
        	          + "\"fullName\":\"" + jsonEscape(fullName) + "\","
        	          + "\"email\":\"" + jsonEscape(email == null ? "" : email) + "\","
        	          + "\"phone\":\"" + jsonEscape(phone == null ? "" : phone) + "\","
        	          + "\"course\":\"" + jsonEscape(course) + "\","
        	          + "\"address\":\"" + jsonEscape(address == null ? "" : address) + "\"}";

        	    activityLogger.logStudentActivity(

        	            savedStudentId,
        	            "ADD",
        	            "Added student: " + fullName,
        	            null,
        	            newData
        	    );
	    		System.out.println("DEBUG: Activity logger call completed.");
        	}



            request.getSession().setAttribute(
                "successMessage",
                "Student added successfully!"
            );

            response.sendRedirect(
                request.getContextPath() + "/students?success=added"
            );

        } catch (SQLIntegrityConstraintViolationException e) {

            String message = e.getMessage();

            if (message != null && message.contains("roll_no")) {
                errorMessage =
                    "This roll number already exists. Please enter a unique roll number.";

            } else if (message != null && message.contains("email")) {
                errorMessage =
                    "This email already exists. Please enter a different email.";

            } else if (message != null && message.contains("phone")) {
                errorMessage =
                    "This phone number already exists. Please enter a different number.";

            } else {
                errorMessage =
                    "These details conflict with an existing record. Please check your entries.";
            }

            request.setAttribute("errorMessage", errorMessage);
            loadCourses(request);

            request.getRequestDispatcher("/add-student.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                "Unable to add student.", e
            );
        }
    }
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
