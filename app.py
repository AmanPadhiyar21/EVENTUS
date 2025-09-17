from flask import Flask, request, jsonify
from flask_cors import CORS
from apscheduler.schedulers.background import BackgroundScheduler
import pymysql
from datetime import datetime, timedelta
import random
import os
import requests
from openai import OpenAI
from dotenv import load_dotenv
from werkzeug.utils import secure_filename
from flask import send_from_directory

# Load env vars
load_dotenv()

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "static/uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "gif"}

app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ------------------ CONFIG ------------------
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASS", "rootpassword"),
    "database": os.getenv("DB_NAME", "eventus")
}


CITIES = ["Ahmedabad", "Mumbai", "Delhi", "Bangalore", "Rajkot", "Porbandar", "Pune", "Udaipur"]
CATEGORIES = ["Sports", "Tech", "Music", "Art", "Cultural", "Adventure", "Theatre", "Politics", "GeoPolitics", "Economy"]

# ------------------ DB CONNECTION ------------------
def get_db_connection():
    return pymysql.connect(**DB_CONFIG, cursorclass=pymysql.cursors.DictCursor)

# ------------------ HELPERS ------------------
def parse_expiry(expiry_str: str | None) -> datetime | None:
    if not expiry_str:
        return None
    s = str(expiry_str).strip()
    fmts = ["%Y-%m-%d", "%Y-%m-%d %H:%M", "%Y-%m-%d %H:%M:%S"]
    for fmt in fmts:
        try:
            dt = datetime.strptime(s, fmt)
            if fmt == "%Y-%m-%d":
                dt = dt.replace(hour=23, minute=59, second=59)
            return dt
        except ValueError:
            continue
    return None

def parse_date(date_str: str) -> datetime | None:
    try:
        return datetime.strptime(date_str.strip(), "%Y-%m-%d")
    except Exception:
        return None

# ------------------ EVENT GENERATION ------------------
def generate_mock_event():
    d = (datetime.now() + timedelta(days=random.randint(1, 14))).date()
    return {
        "title": random.choice(["Hackathon", "Concert", "Football Match", "Painting Workshop"]),
        "description": "An exciting event you won't want to miss!",
        "date": d.strftime("%Y-%m-%d"),
        "city": random.choice(CITIES),
        "category": random.choice(CATEGORIES),
        "registration_link": "https://example.com",
    }

def generate_mock_events(count=5):
    return [generate_mock_event() for _ in range(count)]

def store_events_in_db(events):
    try:
        db_conn = get_db_connection()
        cursor = db_conn.cursor()

        # 🚨 delete only system-generated events, not user-added
        cursor.execute("DELETE FROM events WHERE source='system'")

        for event in events:
            title = event.get("title")
            description = event.get("description", "")
            location = event.get("location", "")
            city = event.get("city")
            category = event.get("category")
            college = event.get("college", "")
            date_str = event.get("date")
            expiry_str = event.get("expiry")
            registration_link = event.get("registration_link", "")

            event_date = parse_date(date_str)
            expiry_dt = parse_expiry(expiry_str)
            if expiry_dt is None and event_date:
                expiry_dt = event_date.replace(hour=23, minute=59, second=59)

            cursor.execute(
                """
                INSERT INTO events (title, description, date, location, city, category, college, registration_link, expiry, is_active, source)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,TRUE,'system')
                """,
                (
                    title,
                    description,
                    event_date,
                    location,
                    city,
                    category,
                    college,
                    registration_link,
                    expiry_dt,
                ),
            )
            print(f"📌 Inserted system event '{title}' with expiry = {expiry_dt}")

        db_conn.commit()
        cursor.close()
        db_conn.close()
    except Exception as e:
        print("❌ Error storing events in DB:", e)


def load_new_events_to_db():
    events = generate_mock_events(5)
    store_events_in_db(events)

def delete_expired_events():
    """Delete expired events (set is_active=FALSE instead of hard delete)."""
    try:
        db_conn = get_db_connection()
        cursor = db_conn.cursor()
        cursor.execute("UPDATE events SET is_active=FALSE WHERE expiry IS NOT NULL AND expiry <= NOW() AND is_active=TRUE")
        deleted_count = cursor.rowcount
        db_conn.commit()
        cursor.close()
        db_conn.close()
        if deleted_count > 0:
            print(f"🗑️ Marked {deleted_count} expired events inactive at {datetime.now()}")
        else:
            print(f"ℹ️ No expired events at {datetime.now()}")
    except Exception as e:
        print("❌ Error deleting expired events:", e)

# ------------------ SCHEDULER ------------------
scheduler = BackgroundScheduler()
def start_scheduler_once():
    if not scheduler.running:
        scheduler.add_job(load_new_events_to_db, 'interval', hours=6, id="load_new_events", replace_existing=True)
        scheduler.add_job(delete_expired_events, 'interval', minutes=15, id="delete_expired", replace_existing=True)
        scheduler.start()
        print("⏰ Scheduler started (load every 6h, expire sweep every 15m)")

@app.before_request
def ensure_scheduler_running():
    start_scheduler_once()

# ------------------ ROUTES ------------------
@app.route("/events/load", methods=["POST"])
def load_events():
    try:
        events = generate_mock_events(5)
        store_events_in_db(events)
        return jsonify({"success": True, "count": len(events), "events": events})
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@app.route("/api/events", methods=["GET"])
def get_events():
    try:
        city = request.args.get("city", "").strip().lower()
        interests = [i.strip().lower() for i in request.args.get("interests", "").split(",") if i.strip()]

        db_conn = get_db_connection()
        cursor = db_conn.cursor(pymysql.cursors.DictCursor)

        query = """
            SELECT id, title, description, date, location, city, college, category,
                   registration_link AS registrationLink, expiry, source
            FROM events
            WHERE is_active=TRUE
        """
        values = []

        # 🔹 Apply city filter only if given
        if city:
            query += " AND LOWER(city) = %s"
            values.append(city)

        # 🔹 Apply interest filter only if given
        if interests:
            placeholders = ','.join(['%s'] * len(interests))
            query += f" AND LOWER(category) IN ({placeholders})"
            values.extend(interests)

        query += " ORDER BY date ASC"

        cursor.execute(query, tuple(values))
        results = cursor.fetchall()
        cursor.close()
        db_conn.close()

        return jsonify(results)
    except Exception as e:
        print("❌ get_events error:", e)
        return jsonify({"error": str(e)}), 500



@app.route("/api/events/filter", methods=["POST"])
def filter_events():
    try:
        data = request.get_json() or {}
        city = data.get("city")
        college = data.get("college")  # ✅ new
        interests = data.get("interests", [])

        db_conn = get_db_connection()
        cursor = db_conn.cursor(pymysql.cursors.DictCursor)

        query = "SELECT * FROM events WHERE is_active=TRUE"
        params = []

        if city:
            query += " AND city=%s"
            params.append(city)

        if college:  # ✅ filter by college if selected
            query += " AND college=%s"
            params.append(college)

        if interests:
            query += " AND category IN %s"
            params.append(tuple(interests))

        cursor.execute(query, tuple(params))
        events = cursor.fetchall()

        cursor.close()
        db_conn.close()
        return jsonify(events), 200
    except Exception as e:
        print("❌ Filter error:", e)
        return jsonify({"error": str(e)}), 500


@app.route("/api/events/add", methods=["POST"])
def add_event():
    try:
        data = request.get_json() or {}
        required = ["title", "date", "city", "category"]
        for f in required:
            if not data.get(f):
                return jsonify({"error": f"Missing field: {f}"}), 400

        event_date = parse_date(data["date"])
        expiry_dt = parse_expiry(data.get("expiry"))
        if expiry_dt is None and event_date:
            expiry_dt = event_date.replace(hour=23, minute=59, second=59)

        db_conn = get_db_connection()
        cursor = db_conn.cursor()

        # ✅ prevent duplicates
        cursor.execute(
            """
            SELECT id FROM events
            WHERE title=%s AND date=%s AND city=%s AND is_active=TRUE
            """,
            (data["title"], event_date, data["city"])
        )
        if cursor.fetchone():
            cursor.close()
            db_conn.close()
            return jsonify({"error": "Event already exists"}), 409

        cursor.execute(
            """
            INSERT INTO events (title, description, date, location, city, college, category, registration_link, expiry, is_active, source)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,TRUE,'user')
            """,
            (
                data["title"],
                data.get("description", ""),
                event_date,
                data.get("location", ""),
                data["city"],
                data.get("college", ""),
                data["category"],
                data.get("registration_link", "") or data.get("registrationLink", ""),
                expiry_dt,
            ),
        )

        db_conn.commit()
        cursor.close()
        db_conn.close()
        return jsonify({"message": "✅ Event added successfully"}), 201
    except Exception as e:
        print("❌ Insert error:", e)
        return jsonify({"error": str(e)}), 500


@app.route("/api/events/<int:event_id>", methods=["DELETE"])
def delete_event(event_id):
    try:
        db_conn = get_db_connection()
        cursor = db_conn.cursor()
        # Soft delete instead of hard delete
        cursor.execute("UPDATE events SET is_active=FALSE WHERE id = %s AND is_active=TRUE", (event_id,))
        db_conn.commit()
        deleted_count = cursor.rowcount
        cursor.close()
        db_conn.close()
        if deleted_count > 0:
            return jsonify({"success": True, "message": f"Event {event_id} marked inactive."})
        else:
            return jsonify({"success": False, "message": "Event not found or already deleted."}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/events/<int:event_id>/not-interested", methods=["POST"])
def mark_not_interested(event_id):
    try:
        data = request.get_json() or {}
        user_id = data.get("userId")
        if not user_id:
            return jsonify({"error": "userId required"}), 400

        db_conn = get_db_connection()
        cursor = db_conn.cursor(pymysql.cursors.DictCursor)

        # Fetch current not_interested_users
        cursor.execute("SELECT not_interested_users FROM events WHERE id=%s", (event_id,))
        row = cursor.fetchone()
        if not row:
            cursor.close()
            db_conn.close()
            return jsonify({"error": "Event not found"}), 404

        import json
        not_interested = row["not_interested_users"]
        if not_interested:
            not_interested = json.loads(not_interested)
        else:
            not_interested = []

        if user_id not in not_interested:
            not_interested.append(user_id)

        # Update DB
        cursor.execute(
            "UPDATE events SET not_interested_users=%s WHERE id=%s",
            (json.dumps(not_interested), event_id)
        )
        db_conn.commit()
        cursor.close()
        db_conn.close()

        return jsonify({"success": True, "message": "Marked as not interested"})
    except Exception as e:
        print("❌ mark_not_interested error:", e)
        return jsonify({"error": str(e)}), 500


@app.route("/api/events/<int:event_id>/rate", methods=["POST"])
def rate_event(event_id):
    try:
        data = request.get_json() or {}
        rating = data.get("rating")
        if rating is None or not (0 <= rating <= 5):
            return jsonify({"error": "Invalid rating"}), 400

        db_conn = get_db_connection()
        cursor = db_conn.cursor()

        cursor.execute("UPDATE events SET rating=%s WHERE id=%s", (rating, event_id))
        db_conn.commit()
        cursor.close()
        db_conn.close()
        return jsonify({"success": True, "message": "Event rated successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route("/api/events/<int:event_id>/upload-image", methods=["POST"])
def upload_event_image(event_id):
    try:
        if "file" not in request.files:
            return jsonify({"error": "No file provided"}), 400

        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "Empty filename"}), 400
        if not allowed_file(file.filename):
            return jsonify({"error": "Invalid file type"}), 400

        filename = secure_filename(f"event_{event_id}_{file.filename}")
        filepath = os.path.join(app.config["UPLOAD_FOLDER"], filename)
        file.save(filepath)

        # ✅ Full URL
        host = request.host_url
        image_url = f"{host}static/uploads/{filename}"

        # Update DB
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE events SET image_url=%s WHERE id=%s", (image_url, event_id))
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "✅ Image uploaded", "imageUrl": image_url}), 200

    except Exception as e:
        print("❌ upload_event_image error:", e)
        return jsonify({"error": str(e)}), 500

# Serve uploaded images
@app.route('/static/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)


@app.route("/api/boxbot", methods=["POST"])
def boxbot():
    try:
        data = request.get_json()
        message = data.get("message", "").lower().strip()

        if not message:
            return jsonify({"reply": "No message received"}), 400

        # 🔹 Simple predefined replies
        rules = {
            "hi": "Hello 👋, I’m BoxBot!",
            "hello": "Hey there! How can I help you?",
            "help": "I can assist you with login, events, and app info.",
            "bye": "Goodbye 👋, see you soon!",
            "who are you": "I’m BoxBot 🤖, your assistant."
        }

        reply = rules.get(message, "Sorry, I don’t understand 🤔")
        return jsonify({"reply": reply})

    except Exception as e:
        print("❌ BoxBot Exception:", e)
        return jsonify({"reply": f"❌ Server Error: {str(e)}"}), 500

@app.route('/uploads/<path:filename>')
def serve_upload(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)


# ------------------ MAIN ------------------
if __name__ == "__main__":
    load_new_events_to_db()
    start_scheduler_once()
    print("🚀 Flask app running with scheduler enabled")
    app.run(host="0.0.0.0", port=5001)
