"""
Student Management System: Python analytics and DAA algorithms.
Reads saved marks through the existing db.py connection helper.
"""
import time
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from db import get_db_connection


class StudentMarksAnalytics:
    def __init__(self):
        self.records = []
        self.dataframe = pd.DataFrame()

    def load_marks(self):
        connection = None
        cursor = None
        try:
            connection = get_db_connection()
            cursor = connection.cursor(dictionary=True)
            cursor.execute("""
                SELECT m.mark_id, m.student_id, s.roll_no, s.full_name,
                       s.course_id, m.subject_name, m.total_marks,
                       m.obtained_marks
                FROM marks m
                JOIN students s ON s.student_id = m.student_id
                ORDER BY s.full_name, m.subject_name
            """)
            self.records = cursor.fetchall()
            self.dataframe = pd.DataFrame(self.records)
            return self.dataframe
        finally:
            if cursor is not None:
                cursor.close()
            if connection is not None and connection.is_connected():
                connection.close()

    def calculate_subject_summary(self):
        if self.dataframe.empty:
            return pd.DataFrame()
        df = self.dataframe.copy()
        df["total_marks"] = pd.to_numeric(df["total_marks"], errors="coerce")
        df["obtained_marks"] = pd.to_numeric(
            df["obtained_marks"], errors="coerce"
        )
        df = df.dropna(subset=["total_marks", "obtained_marks"])
        if df.empty:
            return pd.DataFrame()
        df["percentage"] = np.where(
            df["total_marks"] > 0,
            df["obtained_marks"] / df["total_marks"] * 100,
            np.nan,
        )
        return (
            df.groupby("subject_name", as_index=False)
            .agg(
                students=("student_id", "nunique"),
                average_percentage=("percentage", "mean"),
                highest_percentage=("percentage", "max"),
                lowest_percentage=("percentage", "min"),
            )
            .sort_values("subject_name")
            .round(2)
        )

    def build_student_rankings(self):
        if self.dataframe.empty:
            return []
        df = self.dataframe.copy()
        df["total_marks"] = pd.to_numeric(df["total_marks"], errors="coerce")
        df["obtained_marks"] = pd.to_numeric(
            df["obtained_marks"], errors="coerce"
        )
        df = df.dropna(subset=["total_marks", "obtained_marks"])
        df = df[df["total_marks"] > 0]
        if df.empty:
            return []

        rankings = []
        for student_id, group in df.groupby("student_id"):
            total = float(np.sum(group["total_marks"].to_numpy(dtype=float)))
            obtained = float(
                np.sum(group["obtained_marks"].to_numpy(dtype=float))
            )
            first = group.iloc[0]
            rankings.append({
                "student_id": int(student_id),
                "roll_no": str(first["roll_no"]),
                "full_name": str(first["full_name"]),
                "subjects_count": int(group["subject_name"].nunique()),
                "total_marks": total,
                "obtained_marks": obtained,
                "percentage": obtained / total * 100 if total else 0.0,
            })
        return rankings

    @staticmethod
    def quick_sort(items):
        """Quick Sort, descending by percentage; returns a new list."""
        if len(items) <= 1:
            return list(items)
        pivot = items[len(items) // 2]["percentage"]
        higher = [x for x in items if x["percentage"] > pivot]
        equal = [x for x in items if x["percentage"] == pivot]
        lower = [x for x in items if x["percentage"] < pivot]
        return (
            StudentMarksAnalytics.quick_sort(higher)
            + equal
            + StudentMarksAnalytics.quick_sort(lower)
        )

    @staticmethod
    def merge_sort(items):
        """Merge Sort, descending by percentage; returns a new list."""
        if len(items) <= 1:
            return list(items)
        middle = len(items) // 2
        left = StudentMarksAnalytics.merge_sort(items[:middle])
        right = StudentMarksAnalytics.merge_sort(items[middle:])
        return StudentMarksAnalytics._merge(left, right)

    @staticmethod
    def _merge(left, right):
        merged = []
        i = j = 0
        while i < len(left) and j < len(right):
            if left[i]["percentage"] >= right[j]["percentage"]:
                merged.append(left[i])
                i += 1
            else:
                merged.append(right[j])
                j += 1
        merged.extend(left[i:])
        merged.extend(right[j:])
        return merged

    def compare_sorts(self, rankings):
        start = time.perf_counter()
        quick_result = self.quick_sort(list(rankings))
        quick_seconds = time.perf_counter() - start

        start = time.perf_counter()
        merge_result = self.merge_sort(list(rankings))
        merge_seconds = time.perf_counter() - start

        if [x["percentage"] for x in quick_result] != [
            x["percentage"] for x in merge_result
        ]:
            raise RuntimeError("Sorting algorithms returned different rankings.")
        return quick_result, merge_result, quick_seconds, merge_seconds

    def create_charts(self, rankings, summary):
        folder = Path(__file__).resolve().parent
        if rankings:
            labels = [f"{x['full_name']} ({x['roll_no']})" for x in rankings]
            values = [x["percentage"] for x in rankings]
            plt.figure(figsize=(10, 5))
            plt.bar(labels, values)
            plt.title("Student Overall Performance")
            plt.xlabel("Student")
            plt.ylabel("Overall Percentage")
            plt.ylim(0, 100)
            plt.xticks(rotation=25, ha="right")
            plt.tight_layout()
            plt.savefig(folder / "student_performance.png", dpi=150)
            plt.close()
        if not summary.empty:
            plt.figure(figsize=(9, 5))
            plt.bar(summary["subject_name"], summary["average_percentage"])
            plt.title("Average Percentage by Subject")
            plt.xlabel("Subject")
            plt.ylabel("Average Percentage")
            plt.ylim(0, 100)
            plt.xticks(rotation=25, ha="right")
            plt.tight_layout()
            plt.savefig(folder / "subject_performance.png", dpi=150)
            plt.close()


def main():
    analytics = StudentMarksAnalytics()
    try:
        df = analytics.load_marks()
    except Exception as error:
        print("Could not load marks from MySQL. Check MySQL and db.py settings.")
        print("Details:", error)
        return

    if df.empty:
        print("No saved marks found yet.")
        print("Save marks in teacher-marks.jsp, then run this script again.")
        return

    columns = [
        "student_id", "roll_no", "full_name", "subject_name",
        "total_marks", "obtained_marks",
    ]
    print("\n=== SAVED MARKS (Pandas DataFrame) ===")
    print(df[columns].to_string(index=False))

    summary = analytics.calculate_subject_summary()
    print("\n=== SUBJECT SUMMARY (Pandas + NumPy) ===")
    print(summary.to_string(index=False) if not summary.empty else "No valid numeric marks.")

    rankings = analytics.build_student_rankings()
    if not rankings:
        print("No valid marks available for ranking.")
        return

    quick, merge, quick_time, merge_time = analytics.compare_sorts(rankings)
    print("\n=== QUICK SORT RANKING ===")
    for rank, student in enumerate(quick, 1):
        print(f"{rank}. {student['full_name']} ({student['roll_no']}) - {student['percentage']:.2f}%")

    print("\n=== MERGE SORT RANKING ===")
    for rank, student in enumerate(merge, 1):
        print(f"{rank}. {student['full_name']} ({student['roll_no']}) - {student['percentage']:.2f}%")

    print("\n=== DAA COMPARISON ===")
    print(f"Quick Sort: {quick_time:.8f} seconds")
    print(f"Merge Sort: {merge_time:.8f} seconds")
    print("Quick Sort average time complexity: O(n log n)")
    print("Merge Sort time complexity: O(n log n)")
    print("Small-list timings are illustrative, not a reliable benchmark.")

    analytics.create_charts(quick, summary)
    print("\nCharts saved beside analytics.py:")
    print("- student_performance.png")
    print("- subject_performance.png")


if __name__ == "__main__":
    main()
