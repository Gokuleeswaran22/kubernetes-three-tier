from flask import Flask, jsonify
import pymysql
import os
import time

app = Flask(__name__)


def get_db_connection():
    return pymysql.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "appuser"),
        password=os.getenv("DB_PASSWORD", "AppPass123!"),
        database=os.getenv("DB_NAME", "appdb"),
        port=int(os.getenv("DB_PORT", "3306")),
        cursorclass=pymysql.cursors.DictCursor
    )


@app.route("/")
def home():
    return jsonify({
        "message": "Backend API is running",
        "status": "success"
    })


@app.route("/api/health")
def health():
    return jsonify({
        "status": "healthy"
    })


@app.route("/api/users")
def get_users():

    connection = None

    try:
        connection = get_db_connection()

        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users")
            users = cursor.fetchall()

        return jsonify(users)

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

    finally:
        if connection:
            connection.close()


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000
    )