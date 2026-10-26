
from db import get_db_connection

connection = get_db_connection()

try:
    if connection.is_connected():
        print("MySQL connection successful!")
        print("Database:", connection.database)
finally:
    connection.close()
