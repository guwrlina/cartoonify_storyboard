from flask import Flask, request, send_file, render_template
import cv2
import numpy as np
import os
from io import BytesIO
from PIL import Image

app = Flask(__name__)  # Use the default templates folder

UPLOAD_FOLDER = './uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Cartoonization function using OpenCV
def cartoonize_image(img_path):
    img = cv2.imread(img_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.medianBlur(gray, 5)
    
    edges = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C,
                                  cv2.THRESH_BINARY, 9, 9)
    
    color = cv2.bilateralFilter(img, 9, 300, 300)
    cartoon_img = cv2.bitwise_and(color, color, mask=edges)
    
    return cartoon_img

@app.route('/')
def home():
    return render_template('index.html')  # Ensure this file exists in the templates folder

@app.route('/cartoonize', methods=['POST'])
def cartoonize():
    if 'file' not in request.files:
        return "No file part", 400

    file = request.files['file']
    if file.filename == '':
        return "No selected file", 400

    img_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
    file.save(img_path)

    # Apply cartoonization
    cartoon_img = cartoonize_image(img_path)

    # Convert the cartoonized image to a byte stream
    is_success, buffer = cv2.imencode(".png", cartoon_img)
    if not is_success:
        return "Failed to convert image", 500

    byte_io = BytesIO(buffer)
    return send_file(byte_io, mimetype='image/png')

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', use_reloader=False)
