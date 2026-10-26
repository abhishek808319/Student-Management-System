
import os
import mysql.connector
from mysql.connector import Error


def get_db_connection():
    try:
        connection = mysql.connector.connect(
            host=os.getenv("SMS_DB_HOST", "localhost"),
            port=int(os.getenv("SMS_DB_PORT", "3306")),
            user=os.getenv("SMS_DB_USER", "root"),
            password=os.getenv("SMS_DB_PASSWORD", ""),
            database="student_management"
        )

        return connection

    except Error as error:
        print("Database connection failed:", error)
        raise
