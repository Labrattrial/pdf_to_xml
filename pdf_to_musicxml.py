import os
from flask import Flask, request, send_from_directory, jsonify
import subprocess
from werkzeug.utils import secure_filename
from flask_cors import CORS
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

UPLOAD_FOLDER = 'uploads'
MUSICXML_FOLDER = 'musicxml'
AUDIVERIS_JAR = 'audiveris.jar'  # Path to Audiveris jar after build

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(MUSICXML_FOLDER, exist_ok=True)

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MUSICXML_FOLDER'] = MUSICXML_FOLDER

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        logger.error('No file part in request')
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        logger.error('No selected file')
        return jsonify({'error': 'No selected file'}), 400
    if file and file.filename.lower().endswith('.pdf'):
        filename = secure_filename(file.filename)
        pdf_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(pdf_path)
        logger.info(f'File saved: {filename}')
        
        # Run Audiveris
        xml_filename = os.path.splitext(filename)[0] + '.musicxml'
        xml_path = os.path.join(app.config['MUSICXML_FOLDER'], xml_filename)
        try:
            logger.info('Starting Audiveris conversion')
            subprocess.run([
                'java', '-jar', AUDIVERIS_JAR,
                '-batch', '-export', pdf_path,
                '-output', app.config['MUSICXML_FOLDER']
            ], check=True)
            logger.info('Audiveris conversion completed')
        except subprocess.CalledProcessError as e:
            logger.error(f'Audiveris failed: {str(e)}')
            return jsonify({'error': 'Audiveris failed', 'details': str(e)}), 500
        if not os.path.exists(xml_path):
            # Try .xml extension fallback
            xml_filename = os.path.splitext(filename)[0] + '.xml'
            xml_path = os.path.join(app.config['MUSICXML_FOLDER'], xml_filename)
            if not os.path.exists(xml_path):
                logger.error('MusicXML not found after conversion')
                return jsonify({'error': 'MusicXML not found after conversion'}), 500
        # Return URL to fetch MusicXML
        url = request.url_root.rstrip('/') + '/musicxml/' + xml_filename
        logger.info(f'Conversion successful, returning URL: {url}')
        return jsonify({'musicxml_url': url}), 200
    else:
        logger.error('Invalid file type uploaded')
        return jsonify({'error': 'Invalid file type, only PDF allowed'}), 400

@app.route('/musicxml/<filename>', methods=['GET'])
def get_musicxml(filename):
    return send_from_directory(app.config['MUSICXML_FOLDER'], filename, as_attachment=True)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 10000))
    app.run(host='0.0.0.0', port=port) 