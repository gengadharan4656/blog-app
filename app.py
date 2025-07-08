# ✅ Final Updated Flask Backend with Live Like Fix and Thumbnail Required for Upload
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import mysql.connector
import smtplib
from email.mime.text import MIMEText
import random
import os
import json
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app, origins=["https://blog-app-9a745.web.app"], supports_credentials=True)

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# ✅ Railway MySQL Connection
def connect_db():
    return mysql.connector.connect(
        host="gondola.proxy.rlwy.net",
        user="root",
        password="PKpqjYoazbjHnybxtqjvxxIFuNpFAfqK",
        database="railway",
        port=25845,
        ssl_disabled=True
    )

def send_email_otp(receiver_email, otp):
    sender_email = "factsandblogs247@gmail.com"
    sender_password = "szus zbci lnfy qvjg"
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

otp_store = {}

@app.route('/register', methods=['POST'])
def register():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    phone = data.get('phone')
    password = data.get('password')

    cursor.execute("INSERT INTO users (name, email, phone, password) VALUES (%s, %s, %s, %s)",
                   (name, email, phone, password))
    db.commit()

    cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
    user_id = cursor.fetchone()['id']
    cursor.close()
    db.close()

    return jsonify({'status': 'success', 'user_id': user_id})

@app.route('/login', methods=['POST'])
def login():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    data = request.get_json()
    email_or_phone = data.get('email_or_phone')
    password = data.get('password')

    cursor.execute("SELECT * FROM users WHERE (email = %s OR phone = %s) AND password = %s",
                   (email_or_phone, email_or_phone, password))
    user = cursor.fetchone()
    cursor.close()
    db.close()

    if user:
        return jsonify({'status': 'success', 'user_id': user['id']})
    return jsonify({'status': 'error', 'message': 'Invalid credentials'}), 401

@app.route('/send_otp_email', methods=['POST'])
def send_otp_email():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    data = request.get_json()
    email = data.get('email')

    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    if not cursor.fetchone():
        return jsonify({'status': 'error', 'message': 'Email not found'}), 404

    otp = str(random.randint(1000, 9999))
    otp_store[email] = otp
    if send_email_otp(email, otp):
        return jsonify({'status': 'success', 'message': 'OTP sent'})
    return jsonify({'status': 'error', 'message': 'Failed to send OTP'}), 500

@app.route('/verify_otp', methods=['POST'])
def verify_otp():
    data = request.get_json()
    email = data.get('email')
    entered_otp = data.get('otp')

    if otp_store.get(email) == entered_otp:
        return jsonify({'status': 'success'})
    return jsonify({'status': 'error', 'message': 'Invalid OTP'})

@app.route('/submit_blog', methods=['POST'])
def submit_blog():
    db = connect_db()
    cursor = db.cursor(dictionary=True)

    try:
        user_id = request.form.get('user_id')
        title = request.form.get('title')
        content = request.form.get('content')
        category = request.form.get('category')
        file = request.files.get('thumbnail')

        if not user_id or not title or not content or not category or not file:
            return jsonify({'status': 'error', 'message': 'All fields including thumbnail are required'}), 400

        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        cursor.execute(
            "INSERT INTO blogs (user_id, title, content, category, thumbnail) VALUES (%s, %s, %s, %s, %s)",
            (user_id, title, content, category, filename)
        )
        db.commit()
        return jsonify({'status': 'success', 'message': 'Blog uploaded'})

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

    finally:
        cursor.close()
        db.close()

@app.route('/uploads/<filename>')
def serve_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/search')
def search():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    user_id = request.args.get('user_id')
    query = request.args.get('q', '')

    with open('predefined_blogs.json') as f:
        predefined = json.load(f)

    predefined_results = [b for b in predefined if query.lower() in b['title'].lower()]

    cursor.execute("SELECT * FROM blogs WHERE title LIKE %s OR content LIKE %s OR category LIKE %s",
                   (f'%{query}%', f'%{query}%', f'%{query}%'))
    blogs = cursor.fetchall()

    for blog in blogs:
        cursor.execute("SELECT name FROM users WHERE id = %s", (blog['user_id'],))
        blog['username'] = cursor.fetchone()['name']
        cursor.execute("SELECT 1 FROM likes WHERE user_id = %s AND blog_id = %s", (user_id, blog['id']))
        blog['liked'] = cursor.fetchone() is not None
        cursor.execute("SELECT COUNT(*) as count FROM likes WHERE blog_id = %s", (blog['id'],))
        blog['likes'] = cursor.fetchone()['count']

    cursor.close()
    db.close()
    return jsonify({'predefined': predefined_results, 'user': blogs})

@app.route('/like_blog', methods=['POST'])
def like_blog():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    data = request.get_json()
    blog_id = data['blog_id']
    user_id = data['user_id']

    cursor.execute("SELECT * FROM likes WHERE blog_id = %s AND user_id = %s", (blog_id, user_id))
    liked = cursor.fetchone()

    if liked:
        cursor.execute("DELETE FROM likes WHERE blog_id = %s AND user_id = %s", (blog_id, user_id))
    else:
        cursor.execute("INSERT INTO likes (blog_id, user_id) VALUES (%s, %s)", (blog_id, user_id))
    db.commit()

    cursor.execute("SELECT COUNT(*) as count FROM likes WHERE blog_id = %s", (blog_id,))
    like_count = cursor.fetchone()['count']

    cursor.close()
    db.close()
    return jsonify({'liked': not bool(liked), 'like_count': like_count})

@app.route('/delete_blog', methods=['POST'])
def delete_blog():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    data = request.get_json()
    blog_id = data['blog_id']
    user_id = data['user_id']

    cursor.execute("SELECT * FROM blogs WHERE id = %s AND user_id = %s", (blog_id, user_id))
    if cursor.fetchone():
        cursor.execute("DELETE FROM blogs WHERE id = %s", (blog_id,))
        db.commit()
        result = {'status': 'success'}
    else:
        result = {'status': 'error', 'message': 'Not authorized'}

    cursor.close()
    db.close()
    return jsonify(result)

@app.route('/categories')
def categories():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT DISTINCT category FROM blogs")
    categories = [row['category'] for row in cursor.fetchall()]
    cursor.close()
    db.close()
    return jsonify(categories)

@app.route('/suggest_blogs')
def suggest():
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM blogs ORDER BY views DESC LIMIT 5")
    blogs = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(blogs)

@app.route('/view_blog/<int:blog_id>', methods=['POST'])
def view_blog(blog_id):
    db = connect_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("UPDATE blogs SET views = views + 1 WHERE id = %s", (blog_id,))
    db.commit()
    cursor.close()
    db.close()
    return jsonify({'status': 'success'})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
