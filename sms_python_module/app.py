from datetime import date
import math

from flask import Flask, jsonify, request
from flask_cors import CORS
from db import get_db_connection


app = Flask(__name__)

CORS(
    app,
    resources={
        r"/api/*": {
            "origins": [
                "http://localhost:8082",
                "http://127.0.0.1:8082"
            ]
        },
        r"/health": {
            "origins": [
                "http://localhost:8082",
                "http://127.0.0.1:8082"
            ]
        }
    },
    methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type"]
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def close_db(cursor=None, connection=None):
    """Close a cursor and connection safely."""
    if cursor is not None:
        try:
            cursor.close()
        except Exception:
            app.logger.exception("Failed to close database cursor")

    if connection is not None:
        try:
            if connection.is_connected():
                connection.close()
        except Exception:
            app.logger.exception("Failed to close database connection")


def parse_iso_date(value):
    """Return a date object for YYYY-MM-DD input, or None if invalid."""
    if not isinstance(value, str):
        return None

    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def get_student_course(cursor, student_id):
    """Return a student's course_id, or None if the student does not exist."""
    cursor.execute(
        """
        SELECT student_id, course_id
        FROM students
        WHERE student_id = %s
        """,
        (student_id,),
    )
    return cursor.fetchone()


# ---------------------------------------------------------------------------
# Home and database health
# ---------------------------------------------------------------------------

@app.route("/")
def home():
    return jsonify(
        {
            "application": "Student Management System",
            "module": "Attendance and Marks",
            "status": "running",
        }
    )


@app.route("/health")
def health():
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()

        return jsonify(
            {"status": "healthy", "database": "connected"}
        ), 200

    except Exception:
        app.logger.exception("Database health check failed")
        return jsonify(
            {"status": "error", "database": "disconnected"}
        ), 500

    finally:
        close_db(cursor, connection)


# ---------------------------------------------------------------------------
# Courses: used by the teacher's attendance dashboard
# ---------------------------------------------------------------------------

@app.route("/api/courses", methods=["GET"])
def get_courses():
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT
                c.course_id,
                c.course_name,
                COUNT(s.student_id) AS total_students
            FROM courses c
            LEFT JOIN students s
                ON s.course_id = c.course_id
            GROUP BY c.course_id, c.course_name
            ORDER BY c.course_name
            """
        )

        return jsonify({"courses": cursor.fetchall()}), 200

    except Exception:
        app.logger.exception("Failed to retrieve courses")
        return jsonify({"error": "Unable to retrieve courses."}), 500

    finally:
        close_db(cursor, connection)


# ---------------------------------------------------------------------------
# Shared subjects
# ---------------------------------------------------------------------------

@app.route(
    "/api/students/<int:student_id>/subjects",
    methods=["GET"],
)
def get_student_subjects(student_id):
    """
    Return every subject assigned to the student's course.
    Subjects are shared at course level, not individually created per student.
    """
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        student = get_student_course(cursor, student_id)
        if student is None:
            return jsonify({"error": "Student not found."}), 404

        if student["course_id"] is None:
            return jsonify(
                {
                    "student_id": student_id,
                    "subjects": [],
                }
            ), 200

        cursor.execute(
            """
            SELECT
                subject_id,
                subject_name,
                course_id,
                semester
            FROM subjects
            WHERE course_id = %s
            ORDER BY semester, subject_name
            """,
            (student["course_id"],),
        )
        subjects = cursor.fetchall()

        return jsonify(
            {
                "student_id": student_id,
                "course_id": student["course_id"],
                "subjects": subjects,
            }
        ), 200

    except Exception:
        app.logger.exception("Failed to retrieve student subjects")
        return jsonify(
            {"error": "Unable to retrieve student subjects."}
        ), 500

    finally:
        close_db(cursor, connection)


@app.route(
    "/api/students/<int:student_id>/subjects",
    methods=["POST"],
)
def add_student_subject(student_id):
    """
    Create or reuse a subject for the student's course and semester.
    Then enroll all students in that course in the shared subject.
    The URL is retained so the existing student-profile page can keep using it.
    """
    data = request.get_json(silent=True) or {}

    raw_subject_name = data.get("subject_name")
    subject_name = (
        raw_subject_name.strip()
        if isinstance(raw_subject_name, str)
        else ""
    )
    semester = data.get("semester")

    if not subject_name or len(subject_name) > 100:
        return jsonify(
            {
                "error": (
                    "Enter a subject name between 1 and 100 characters."
                )
            }
        ), 400

    try:
        semester = int(semester)
        if semester < 1 or semester > 4:
            raise ValueError()
    except (TypeError, ValueError):
        return jsonify(
            {"error": "Semester must be between 1 and 4."}
        ), 400

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)

        student = get_student_course(cursor, student_id)
        if student is None:
            connection.rollback()
            return jsonify({"error": "Student not found."}), 404

        course_id = student["course_id"]
        if course_id is None:
            connection.rollback()
            return jsonify(
                {"error": "The student is not assigned to a course."}
            ), 400

        cursor.execute(
            """
            SELECT subject_id, subject_name, course_id, semester
            FROM subjects
            WHERE LOWER(subject_name) = LOWER(%s)
              AND course_id = %s
              AND semester = %s
            LIMIT 1
            """,
            (subject_name, course_id, semester),
        )
        subject = cursor.fetchone()

        if subject is None:
            cursor.execute(
                """
                INSERT INTO subjects
                    (subject_name, course_id, semester)
                VALUES (%s, %s, %s)
                """,
                (subject_name, course_id, semester),
            )
            subject_id = cursor.lastrowid
        else:
            subject_id = subject["subject_id"]

        # Ensure every student enrolled in this course has this subject in
        # student_subjects. Existing enrollments are left unchanged.
        cursor.execute(
            """
            INSERT INTO student_subjects (student_id, subject_id)
            SELECT st.student_id, %s
            FROM students st
            WHERE st.course_id = %s
            ON DUPLICATE KEY UPDATE
                enrollment_id = enrollment_id
            """,
            (subject_id, course_id),
        )

        connection.commit()

        return jsonify(
            {
                "message": (
                    "Shared course subject created/reused and made available "
                    "to students in the course."
                ),
                "student_id": student_id,
                "course_id": course_id,
                "subject_id": subject_id,
                "subject_name": subject_name,
                "semester": semester,
            }
        ), 201

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("Subject creation/enrollment failed")
        return jsonify(
            {"error": "Unable to create or share this subject."}
        ), 500

    finally:
        close_db(cursor, connection)


# ---------------------------------------------------------------------------
# Teacher attendance sheet: get all students and subjects for a course/date
# ---------------------------------------------------------------------------

@app.route(
    "/api/courses/<int:course_id>/attendance",
    methods=["GET"],
)
def get_course_attendance_sheet(course_id):
    """
    Returns the course, its students, its shared subjects, and attendance
    already recorded for the requested date.
    Optional query string: ?date=YYYY-MM-DD
    """
    attendance_date = request.args.get("date")
    if attendance_date:
        parsed_date = parse_iso_date(attendance_date)
        if parsed_date is None:
            return jsonify(
                {"error": "Use a valid date in YYYY-MM-DD format."}
            ), 400
        attendance_date = parsed_date

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT course_id, course_name
            FROM courses
            WHERE course_id = %s
            """,
            (course_id,),
        )
        course = cursor.fetchone()

        if course is None:
            return jsonify({"error": "Course not found."}), 404

        cursor.execute(
            """
            SELECT student_id, roll_no, full_name
            FROM students
            WHERE course_id = %s
            ORDER BY roll_no, full_name
            """,
            (course_id,),
        )
        students = cursor.fetchall()

        cursor.execute(
            """
            SELECT subject_id, subject_name, semester
            FROM subjects
            WHERE course_id = %s
            ORDER BY semester, subject_name
            """,
            (course_id,),
        )
        subjects = cursor.fetchall()

        attendance = []
        if attendance_date is not None:
            cursor.execute(
                """
                SELECT
                    a.attendance_id,
                    a.student_id,
                    a.subject_id,
                    a.attendance_date,
                    a.status
                FROM attendance a
                JOIN students st
                    ON st.student_id = a.student_id
                JOIN subjects sub
                    ON sub.subject_id = a.subject_id
                WHERE st.course_id = %s
                  AND sub.course_id = %s
                  AND a.attendance_date = %s
                """,
                (course_id, course_id, attendance_date),
            )
            attendance = cursor.fetchall()

            for row in attendance:
                if row.get("attendance_date") is not None:
                    row["attendance_date"] = (
                        row["attendance_date"].isoformat()
                    )

        return jsonify(
            {
                "course": course,
                "attendance_date": (
                    attendance_date.isoformat()
                    if attendance_date is not None
                    else None
                ),
                "students": students,
                "subjects": subjects,
                "attendance": attendance,
            }
        ), 200

    except Exception:
        app.logger.exception("Failed to retrieve course attendance sheet")
        return jsonify(
            {"error": "Unable to retrieve course attendance sheet."}
        ), 500

    finally:
        close_db(cursor, connection)


@app.route(
    "/api/courses/<int:course_id>/attendance",
    methods=["POST"],
)
def save_course_attendance_sheet(course_id):
    """
    Save a whole course attendance sheet for one date.

    Expected JSON:
    {
      "attendance_date": "2026-10-25",
      "records": [
        {"student_id": 23, "subject_id": 1, "status": "PRESENT"},
        {"student_id": 24, "subject_id": 1, "status": "ABSENT"}
      ]
    }

    Send a record for every student/subject cell. An unchecked checkbox should
    be sent as ABSENT. Existing records for the same date are updated.
    """
    data = request.get_json(silent=True) or {}
    parsed_date = parse_iso_date(data.get("attendance_date"))
    records = data.get("records")

    if parsed_date is None:
        return jsonify(
            {"error": "Use a valid attendance_date in YYYY-MM-DD format."}
        ), 400

    if not isinstance(records, list) or not records:
        return jsonify(
            {"error": "records must be a non-empty list."}
        ), 400

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT course_id FROM courses WHERE course_id = %s",
            (course_id,),
        )
        if cursor.fetchone() is None:
            connection.rollback()
            return jsonify({"error": "Course not found."}), 404

        # Validate all records before writing any of them.
        normalized_records = []
        seen_cells = set()

        for index, record in enumerate(records):
            if not isinstance(record, dict):
                connection.rollback()
                return jsonify(
                    {"error": f"Record {index + 1} must be an object."}
                ), 400

            try:
                student_id = int(record.get("student_id"))
                subject_id = int(record.get("subject_id"))
            except (TypeError, ValueError):
                connection.rollback()
                return jsonify(
                    {
                        "error": (
                            f"Record {index + 1} needs valid student_id "
                            "and subject_id values."
                        )
                    }
                ), 400

            status = str(record.get("status", "")).strip().upper()
            if status not in {"PRESENT", "ABSENT", "LATE"}:
                connection.rollback()
                return jsonify(
                    {
                        "error": (
                            f"Record {index + 1} status must be PRESENT, "
                            "ABSENT, or LATE."
                        )
                    }
                ), 400

            cell = (student_id, subject_id)
            if cell in seen_cells:
                connection.rollback()
                return jsonify(
                    {
                        "error": (
                            "The request contains a duplicate "
                            "student/subject cell."
                        )
                    }
                ), 400

            seen_cells.add(cell)
            normalized_records.append((student_id, subject_id, status))

        for student_id, subject_id, status in normalized_records:
            cursor.execute(
                """
                SELECT 1
                FROM students st
                JOIN subjects sub
                    ON sub.course_id = st.course_id
                WHERE st.student_id = %s
                  AND st.course_id = %s
                  AND sub.subject_id = %s
                """,
                (student_id, course_id, subject_id),
            )

            if cursor.fetchone() is None:
                connection.rollback()
                return jsonify(
                    {
                        "error": (
                            "A student or subject does not belong to "
                            "the selected course."
                        ),
                        "student_id": student_id,
                        "subject_id": subject_id,
                    }
                ), 400

        # Use the existing unique key (student_id, subject_id, date) to update
        # existing attendance instead of producing duplicate rows.
        for student_id, subject_id, status in normalized_records:
            cursor.execute(
                """
                INSERT INTO attendance
                    (student_id, subject_id, attendance_date, status)
                VALUES (%s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    status = VALUES(status)
                """,
                (student_id, subject_id, parsed_date, status),
            )

        connection.commit()

        return jsonify(
            {
                "message": "Course attendance saved successfully.",
                "course_id": course_id,
                "attendance_date": parsed_date.isoformat(),
                "saved_records": len(normalized_records),
            }
        ), 200

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("Failed to save course attendance")
        return jsonify(
            {"error": "Unable to save course attendance."}
        ), 500

    finally:
        close_db(cursor, connection)


# ---------------------------------------------------------------------------
# Individual attendance endpoint (kept for compatibility with existing pages)
# ---------------------------------------------------------------------------

@app.route(
    "/api/students/<int:student_id>/attendance",
    methods=["POST"],
)
def record_student_attendance(student_id):
    data = request.get_json(silent=True) or {}

    subject_id = data.get("subject_id")
    parsed_date = parse_iso_date(data.get("attendance_date"))
    status = str(data.get("status", "")).strip().upper()

    if status not in {"PRESENT", "ABSENT", "LATE"}:
        return jsonify(
            {"error": "Status must be PRESENT, ABSENT, or LATE."}
        ), 400

    try:
        subject_id = int(subject_id)
        if subject_id <= 0:
            raise ValueError()
    except (TypeError, ValueError):
        return jsonify({"error": "A valid subject_id is required."}), 400

    if parsed_date is None:
        return jsonify(
            {"error": "Use a valid date in YYYY-MM-DD format."}
        ), 400

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)

        # Confirm that the student and subject belong to the same course.
        # This supports shared course subjects without relying on manual
        # per-student enrollment rows.
        cursor.execute(
            """
            SELECT 1
            FROM students st
            JOIN subjects sub
                ON sub.course_id = st.course_id
            WHERE st.student_id = %s
              AND sub.subject_id = %s
            """,
            (student_id, subject_id),
        )

        if cursor.fetchone() is None:
            connection.rollback()
            return jsonify(
                {
                    "error": (
                        "The student and subject must belong to the same "
                        "course."
                    )
                }
            ), 400

        cursor.execute(
            """
            INSERT INTO attendance
                (student_id, subject_id, attendance_date, status)
            VALUES (%s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                status = VALUES(status)
            """,
            (student_id, subject_id, parsed_date, status),
        )

        connection.commit()

        return jsonify(
            {
                "message": "Attendance recorded successfully.",
                "student_id": student_id,
                "subject_id": subject_id,
                "attendance_date": parsed_date.isoformat(),
                "status": status,
            }
        ), 200

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("Failed to record attendance")
        return jsonify({"error": "Unable to record attendance."}), 500

    finally:
        close_db(cursor, connection)


@app.route(
    "/api/students/<int:student_id>/attendance",
    methods=["GET"],
)
def get_student_attendance(student_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT student_id
            FROM students
            WHERE student_id = %s
            """,
            (student_id,),
        )

        if cursor.fetchone() is None:
            return jsonify({"error": "Student not found."}), 404

        cursor.execute(
            """
            SELECT
                a.attendance_id,
                a.student_id,
                a.subject_id,
                s.subject_name,
                s.semester,
                a.attendance_date,
                a.status
            FROM attendance a
            JOIN subjects s
                ON s.subject_id = a.subject_id
            WHERE a.student_id = %s
            ORDER BY a.attendance_date DESC, s.subject_name
            """,
            (student_id,),
        )

        records = cursor.fetchall()

        for record in records:
            if record.get("attendance_date") is not None:
                record["attendance_date"] = (
                    record["attendance_date"].isoformat()
                )

        return jsonify(
            {
                "student_id": student_id,
                "attendance": records,
            }
        ), 200

    except Exception:
        app.logger.exception("Failed to retrieve student attendance")
        return jsonify(
            {"error": "Unable to retrieve attendance records."}
        ), 500

    finally:
        close_db(cursor, connection)


# ---------------------------------------------------------------------------
# Start Flask
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Teacher Marks Management
# ---------------------------------------------------------------------------

@app.route("/api/courses/<int:course_id>/marks", methods=["GET"])
def get_course_marks(course_id):
    """Return enrolled students and any marks saved for the selected subject."""
    raw_subject_id = request.args.get("subject_id")

    try:
        subject_id = int(raw_subject_id)
        if subject_id <= 0:
            raise ValueError()
    except (TypeError, ValueError):
        return jsonify({"error": "A valid subject_id is required."}), 400

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT course_id, course_name
            FROM courses
            WHERE course_id = %s
            """,
            (course_id,)
        )
        course = cursor.fetchone()

        if course is None:
            return jsonify({"error": "Course not found."}), 404

        cursor.execute(
            """
            SELECT subject_id, subject_name, course_id, semester
            FROM subjects
            WHERE subject_id = %s AND course_id = %s
            """,
            (subject_id, course_id)
        )
        subject = cursor.fetchone()

        if subject is None:
            return jsonify(
                {"error": "Subject does not belong to this course."}
            ), 400

        # Use actual student-subject enrollment records, not every student
        # in the course, so only enrolled students appear.
        cursor.execute(
            """
            SELECT
                st.student_id,
                st.roll_no,
                st.full_name,
                m.mark_id,
                m.total_marks,
                m.obtained_marks
            FROM students st
            JOIN student_subjects ss
                ON ss.student_id = st.student_id
            JOIN subjects sub
                ON sub.subject_id = ss.subject_id
            LEFT JOIN marks m
                ON m.student_id = st.student_id
                AND m.subject_name = sub.subject_name
            WHERE st.course_id = %s
              AND sub.course_id = %s
              AND sub.subject_id = %s
            ORDER BY st.roll_no, st.full_name
            """,
            (course_id, course_id, subject_id)
        )
        students = cursor.fetchall()

        return jsonify({
            "course": course,
            "subject": subject,
            "students": students
        }), 200

    except Exception:
        app.logger.exception("Failed to retrieve course marks")
        return jsonify({"error": "Unable to retrieve marks."}), 500

    finally:
        close_db(cursor, connection)


@app.route("/api/courses/<int:course_id>/marks", methods=["POST"])
def save_course_marks(course_id):
    """
    Save or update marks for one subject.

    Expected JSON:
    {
        "subject_id": 2,
        "total_marks": 100,
        "records": [
            {"student_id": 5, "obtained_marks": 82},
            {"student_id": 16, "obtained_marks": 76}
        ]
    }
    """
    data = request.get_json(silent=True) or {}
    records = data.get("records")

    try:
        subject_id = int(data.get("subject_id"))
        total_marks = float(data.get("total_marks"))

        if subject_id <= 0:
            raise ValueError()

        if not math.isfinite(total_marks) or total_marks <= 0:
            raise ValueError()

    except (TypeError, ValueError, OverflowError):
        return jsonify({
            "error": "Provide a valid subject_id and positive total_marks."
        }), 400

    if not isinstance(records, list) or not records:
        return jsonify({"error": "records must be a non-empty list."}), 400

    normalized_records = []
    seen_student_ids = set()

    for index, record in enumerate(records):
        if not isinstance(record, dict):
            return jsonify({
                "error": f"Record {index + 1} must be an object."
            }), 400

        try:
            student_id = int(record.get("student_id"))
            obtained_marks = float(record.get("obtained_marks"))

            if student_id <= 0:
                raise ValueError()

            if not math.isfinite(obtained_marks) or obtained_marks < 0:
                raise ValueError()

        except (TypeError, ValueError, OverflowError):
            return jsonify({
                "error": (
                    f"Record {index + 1} needs a valid student_id "
                    "and non-negative obtained_marks."
                )
            }), 400

        if obtained_marks > total_marks:
            return jsonify({
                "error": (
                    f"Obtained marks cannot exceed total marks "
                    f"for student {student_id}."
                )
            }), 400

        if student_id in seen_student_ids:
            return jsonify({
                "error": "Duplicate student IDs were submitted."
            }), 400

        seen_student_ids.add(student_id)
        normalized_records.append((student_id, obtained_marks))

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        connection.start_transaction()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT course_id FROM courses WHERE course_id = %s",
            (course_id,)
        )
        if cursor.fetchone() is None:
            connection.rollback()
            return jsonify({"error": "Course not found."}), 404

        cursor.execute(
            """
            SELECT subject_name
            FROM subjects
            WHERE subject_id = %s AND course_id = %s
            """,
            (subject_id, course_id)
        )
        subject = cursor.fetchone()

        if subject is None:
            connection.rollback()
            return jsonify({
                "error": "Subject does not belong to this course."
            }), 400

        subject_name = subject["subject_name"]

        # Validate every student before writing any records.
        for student_id, obtained_marks in normalized_records:
            cursor.execute(
                """
                SELECT 1
                FROM students st
                JOIN student_subjects ss
                    ON ss.student_id = st.student_id
                JOIN subjects sub
                    ON sub.subject_id = ss.subject_id
                WHERE st.student_id = %s
                  AND st.course_id = %s
                  AND sub.course_id = %s
                  AND sub.subject_id = %s
                LIMIT 1
                """,
                (student_id, course_id, course_id, subject_id)
            )

            if cursor.fetchone() is None:
                connection.rollback()
                return jsonify({
                    "error": (
                        f"Student {student_id} is not enrolled in "
                        "the selected subject for this course."
                    )
                }), 400

        # The existing marks table has no confirmed unique key for
        # (student_id, subject_name), so update the first match if present.
        for student_id, obtained_marks in normalized_records:
            cursor.execute(
                """
                SELECT mark_id
                FROM marks
                WHERE student_id = %s AND subject_name = %s
                ORDER BY mark_id
                LIMIT 1
                """,
                (student_id, subject_name)
            )
            existing_mark = cursor.fetchone()

            if existing_mark:
                cursor.execute(
                    """
                    UPDATE marks
                    SET total_marks = %s, obtained_marks = %s
                    WHERE mark_id = %s
                    """,
                    (
                        total_marks,
                        obtained_marks,
                        existing_mark["mark_id"]
                    )
                )
            else:
                cursor.execute(
                    """
                    INSERT INTO marks
                        (student_id, subject_name, total_marks, obtained_marks)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        student_id,
                        subject_name,
                        total_marks,
                        obtained_marks
                    )
                )

        connection.commit()

        return jsonify({
            "message": "Marks saved successfully.",
            "course_id": course_id,
            "subject_id": subject_id,
            "saved_records": len(normalized_records)
        }), 200

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("Failed to save course marks")
        return jsonify({"error": "Unable to save marks."}), 500

    finally:
        close_db(cursor, connection)

# ---------------------------------------------------------------------------
# Student Marks View API
# Add this route to app.py before: if __name__ == "__main__":
# Uses the existing marks table and close_db() helper.
# ---------------------------------------------------------------------------

@app.route("/api/students/<int:student_id>/marks", methods=["GET"])
def get_student_marks(student_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT student_id, roll_no, full_name, course_id
            FROM students
            WHERE student_id = %s
            """,
            (student_id,)
        )
        student = cursor.fetchone()

        if student is None:
            return jsonify({"error": "Student not found."}), 404

        cursor.execute(
            """
            SELECT
                mark_id,
                student_id,
                subject_name,
                total_marks,
                obtained_marks
            FROM marks
            WHERE student_id = %s
            ORDER BY subject_name, mark_id
            """,
            (student_id,)
        )
        marks = cursor.fetchall()

        return jsonify({
            "student": student,
            "marks": marks
        }), 200

    except Exception:
        app.logger.exception("Failed to retrieve student marks")
        return jsonify({"error": "Unable to retrieve student marks."}), 500

    finally:
        close_db(cursor, connection)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
