from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import mysql.connector
import smtplib
from email.mime.text import MIMEText
import random
import os
import json
from werkzeug.utils import secure_filename

from flask_cors import CORS

from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins=["https://blog-app-9a745.web.app"], supports_credentials=True)

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# ✅ Railway MySQL Connection
db = mysql.connector.connect(
    host="gondola.proxy.rlwy.net",
    user="root",
    password="PKpqjYoazbjHnybxtqjvxxIFuNpFAfqK",
    database="railway",
    port=25845,
    ssl_disabled=True
)
cursor = db.cursor(dictionary=True)
otp_store = {}

# ✅ Updated reconnect_db with Railway config
def reconnect_db():
    global db, cursor
    try:
        db.ping(reconnect=True, attempts=3, delay=2)
    except:
        db = mysql.connector.connect(
            host="gondola.proxy.rlwy.net",
            user="root",
            password="PKpqjYoazbjHnybxtqjvxxIFuNpFAfqK",
            database="railway",
            port=25845,
            ssl_disabled=True
        )
        cursor = db.cursor(dictionary=True)

def clear_results():
    while cursor.nextset():
        pass

def send_email_otp(receiver_email, otp):
    sender_email = "factsandblogs247@gmail.com"
    sender_password = "szus zbci lnfy qvjg"  # Your Gmail app password
    msg = MIMEText(f"Your OTP for password reset is: {otp}")
    msg['Subject'] = "Reset Password - OTP Verification"
    msg['From'] = sender_email
    msg['To'] = receiver_email

    try:
        server = smtplib.SMTP_SSL("smtp.gmail.com", 465)
        server.login(sender_email, sender_password)
        server.send_message(msg)
        server.quit()
        return True
    except Exception as e:
        print("Email OTP Error:", e)
        return False

@app.route('/register', methods=['POST'])
def register():
    reconnect_db()
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    phone = data.get('phone')
    password = data.get('password')

    if not name or not email or not phone or not password:
        return jsonify({'status': 'error', 'message': 'Missing fields'}), 400

    cursor.execute("INSERT INTO users (name, email, phone, password) VALUES (%s, %s, %s, %s)", 
                   (name, email, phone, password))
    db.commit()

    cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
    user_id = cursor.fetchone()[0]

    return jsonify({'status': 'success', 'user_id': user_id}), 200
@app.route('/login', methods=['POST'])
def login():
    reconnect_db()
    clear_results()
    data = request.get_json()
    email_or_phone = data.get('email_or_phone')
    password = data.get('password')
    if not email_or_phone or not password:
        return jsonify({'status': 'error', 'message': 'Missing credentials'}), 400

    cursor.execute("SELECT * FROM users WHERE (email = %s OR phone = %s) AND password = %s",
                   (email_or_phone, email_or_phone, password))
    user = cursor.fetchone()
    if user:
        return jsonify({'status': 'success', 'message': 'Login successful', 'user_id': user['id']})
    return jsonify({'status': 'error', 'message': 'Invalid credentials'}), 401

@app.route('/send_otp_email', methods=['POST'])
def send_otp_email():
    reconnect_db()
    clear_results()
    data = request.get_json()
    email = data.get('email')

    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    if not cursor.fetchone():
        return jsonify({'status': 'error', 'message': 'Email not found'}), 404

    otp = str(random.randint(1000, 9999))
    otp_store[email] = otp

    if send_email_otp(email, otp):  # 🔁 Calls the function below
        return jsonify({'status': 'success', 'message': 'OTP sent'})
    return jsonify({'status': 'error', 'message': 'Failed to send OTP'}), 500

@app.route('/verify_otp', methods=['POST'])
def verify_otp():
    reconnect_db()
    clear_results()
    data = request.get_json()
    email = data.get('email')
    entered_otp = data.get('otp')
    if otp_store.get(email) == entered_otp:
        return jsonify({'status': 'success', 'message': 'OTP verified'})
    return jsonify({'status': 'error', 'message': 'Invalid OTP'}), 400

@app.route('/reset_password', methods=['POST'])
def reset_password():
    reconnect_db()
    clear_results()
    data = request.get_json()
    email = data.get('email')
    new_password = data.get('new_password')
    cursor.execute("UPDATE users SET password = %s WHERE email = %s", (new_password, email))
    db.commit()
    otp_store.pop(email, None)
    if cursor.rowcount == 0:
        return jsonify({'status': 'error', 'message': 'Email not found'}), 404
    return jsonify({'status': 'success', 'message': 'Password updated'})

@app.route('/submit_blog', methods=['POST'])
def submit_blog():
    user_id = request.form.get('user_id')
    title = request.form.get('title')
    content = request.form.get('content')
    category = request.form.get('category')

    file = request.files.get('thumbnail')
    thumbnail_url = None

    if file:
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        thumbnail_url = f"https://blog-app-k878.onrender.com/uploads/{filename}"

    cursor = db.cursor()
    cursor.execute("INSERT INTO blogs (user_id, title, content, category, thumbnail_url) VALUES (%s, %s, %s, %s, %s)",
                   (user_id, title, content, category, thumbnail_url))
    db.commit()

    return jsonify({"status": "success", "message": "Blog submitted successfully"})

@app.route('/delete_blog', methods=['POST'])
def delete_blog():
    reconnect_db()
    clear_results()
    data = request.get_json()
    blog_id = data.get('blog_id')
    user_id = data.get('user_id')

    cursor.execute("SELECT user_id FROM blogs WHERE id = %s", (blog_id,))
    blog = cursor.fetchone()
    if not blog:
        return jsonify({'status': 'error', 'message': 'Blog not found'}), 404

    if blog['user_id'] != user_id:
        return jsonify({'status': 'error', 'message': 'Unauthorized'}), 403

    cursor.execute("DELETE FROM blogs WHERE id = %s", (blog_id,))
    db.commit()
    return jsonify({'status': 'success', 'message': 'Blog deleted'})

@app.route('/like_blog', methods=['POST'])
def like_blog():
    data = request.json
    blog_id = data.get('blog_id')
    user_id = data.get('user_id')

    try:
        cursor = db.cursor()

        cursor.execute("SELECT * FROM likes WHERE blog_id = %s AND user_id = %s", (blog_id, user_id))
        existing_like = cursor.fetchone()

        if existing_like:
            cursor.execute("DELETE FROM likes WHERE blog_id = %s AND user_id = %s", (blog_id, user_id))
            db.commit()
            action = 'unliked'
        else:
            cursor.execute("INSERT INTO likes (blog_id, user_id) VALUES (%s, %s)", (blog_id, user_id))
            db.commit()
            action = 'liked'

        cursor.execute("SELECT COUNT(*) FROM likes WHERE blog_id = %s", (blog_id,))
        like_count = cursor.fetchone()[0]

        return jsonify({'success': True, 'action': action, 'likes': like_count})

    except Exception as e:
        print("Error in like_blog:", str(e))
        return jsonify({'success': False, 'error': str(e)})

    finally:
        cursor.close()

@app.route('/is_liked')
def is_liked():
    blog_id = request.args.get('blog_id')
    user_id = request.args.get('user_id')
    cursor = db.cursor()
    cursor.execute("SELECT * FROM likes WHERE blog_id = %s AND user_id = %s", (blog_id, user_id))
    liked = cursor.fetchone() is not None
    return jsonify({'liked': liked})

@app.route('/search', methods=['GET'])
def search():
    reconnect_db()
    clear_results()
    query = request.args.get('q', '').lower()
    user_id = request.args.get('user_id', type=int)
    try:
        with open('predefined_blogs.json') as f:
            predefined = json.load(f)
    except:
        predefined = []

    cursor.execute("""
        SELECT blogs.id, blogs.title, blogs.content, blogs.category, blogs.thumbnail, blogs.views, blogs.likes,
               blogs.user_id, users.name AS username
        FROM blogs
        JOIN users ON blogs.user_id = users.id
        WHERE LOWER(blogs.title) LIKE %s OR LOWER(blogs.content) LIKE %s OR LOWER(blogs.category) LIKE %s
        ORDER BY blogs.id DESC
    """, (f"%{query}%", f"%{query}%", f"%{query}%"))
    results = cursor.fetchall()

    for blog in results:
        if blog['thumbnail']:
            blog['thumbnail'] = f"{request.host_url}uploads/{blog['thumbnail']}"
        blog['liked'] = False

    cursor.execute("SELECT id, title, category, views FROM blogs ORDER BY views DESC LIMIT 3")
    suggestions = cursor.fetchall()

    return jsonify({'predefined': predefined, 'user': results, 'suggestions': suggestions})

@app.route('/get_blogs')
def get_blogs():
    reconnect_db()
    clear_results()
    user_id = request.args.get('user_id', type=int)
    cursor.execute("""
        SELECT blogs.id, blogs.title, blogs.content, blogs.category, blogs.thumbnail, blogs.views, blogs.likes,
               blogs.user_id, users.name AS username
        FROM blogs
        JOIN users ON blogs.user_id = users.id
        ORDER BY blogs.id DESC
    """)
    blogs = cursor.fetchall()
    for blog in blogs:
        if blog['thumbnail']:
            blog['thumbnail'] = f"{request.host_url}uploads/{blog['thumbnail']}"
        blog['liked'] = False
    return jsonify(blogs)

@app.route('/view_blog/<int:blog_id>', methods=['POST'])
def view_blog(blog_id):
    reconnect_db()
    clear_results()
    cursor.execute("UPDATE blogs SET views = views + 1 WHERE id = %s", (blog_id,))
    db.commit()
    return jsonify({'status': 'success', 'message': 'View counted'})

@app.route('/categories')
def get_categories():
    reconnect_db()
    clear_results()
    cursor.execute("SELECT DISTINCT category FROM blogs")
    rows = cursor.fetchall()
    categories = [row['category'] for row in rows if row['category']]
    return jsonify(categories)

@app.route('/uploads/<filename>')
def serve_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
