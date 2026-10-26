
package com.sms.model;

public class Course {

    private int courseId;
    private String courseName;
    private int semester;

    public Course() {
    }

    public Course(int courseId, String courseName, int semester) {
        this.courseId = courseId;
        this.courseName = courseName;
        this.semester = semester;
    }

    public int getCourseId() {
        return courseId;
    }

    public void setCourseId(int courseId) {
        this.courseId = courseId;
    }

    public String getCourseName() {
        return courseName;
    }

    public void setCourseName(String courseName) {
        this.courseName = courseName;
    }

    public int getSemester() {
        return semester;
    }

    public void setSemester(int semester) {
        this.semester = semester;
    }
}
