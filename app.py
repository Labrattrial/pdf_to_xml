from flask import Flask, request, send_file
from flask_cors import CORS
import os
import subprocess
from werkzeug.utils import secure_filename
import tempfile

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = '/tmp/uploads'
DOWNLOAD_FOLDER = '/tmp/downloads'
ALLOWED_EXTENSIONS = {'pdf'}

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(DOWNLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/health', methods=['GET'])
def health_check():
    return {'status': 'healthy'}, 200

@app.route('/convert', methods=['POST'])
def convert_pdf():
    if 'file' not in request.files:
        return {'error': 'No file part'}, 400
    
    file = request.files['file']
    if file.filename == '':
        return {'error': 'No selected file'}, 400
    
    if not allowed_file(file.filename):
        return {'error': 'Invalid file type'}, 400

    try:
        # Save uploaded file
        filename = secure_filename(file.filename)
        pdf_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(pdf_path)

        # Convert to MusicXML
        output_path = os.path.join(DOWNLOAD_FOLDER, f"{os.path.splitext(filename)[0]}.musicxml")
        
        # Run Audiveris conversion
        subprocess.run([
            'audiveris',
            '-batch', '-export', pdf_path,
            '-output', DOWNLOAD_FOLDER
        ], check=True)

        # Check if conversion was successful
        if not os.path.exists(output_path):
            return {'error': 'Conversion failed'}, 500

        # Send the converted file
        return send_file(
            output_path,
            mimetype='application/xml',
            as_attachment=True,
            download_name=f"{os.path.splitext(filename)[0]}.musicxml"
        )

    except Exception as e:
        return {'error': str(e)}, 500
    finally:
        # Cleanup
        if os.path.exists(pdf_path):
            os.remove(pdf_path)
        if os.path.exists(output_path):
            os.remove(output_path)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port) 