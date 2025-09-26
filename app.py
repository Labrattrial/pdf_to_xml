from flask import Flask, request, jsonify
import subprocess
import os
import zipfile
import shutil

app = Flask(__name__)

def cleanup_directories():
    """Clean up uploads and outputs directories before processing"""
    try:
        if os.path.exists("uploads"):
            shutil.rmtree("uploads")
        if os.path.exists("outputs"):
            shutil.rmtree("outputs")
    except Exception as e:
        print(f"Warning: Could not clean directories: {e}")

# ✅ New landing page
@app.route("/")
def home():
    return "🎵 PDF to MusicXML Converter is running!"

@app.get("/health")
def health():
    # Check if Audiveris is available
    audiveris_path = os.environ.get('AUDIVERIS_PATH', '/usr/local/bin/audiveris')
    
    # Check if we're on Windows (for local development)
    if os.name == 'nt' and not os.environ.get('AUDIVERIS_PATH'):
        audiveris_path = r"D:\Audiveris\audiveris\app\build\distributions\app-5.6.2\bin\Audiveris.bat"
    
    audiveris_available = os.path.exists(audiveris_path)
    
    # Additional debugging info for deployment
    debug_info = {
        "audiveris_path": audiveris_path,
        "path_exists": audiveris_available,
        "environment_audiveris_path": os.environ.get('AUDIVERIS_PATH', 'Not set'),
        "platform": os.name,
        "cwd": os.getcwd(),
    }
    
    # Check common Audiveris locations
    common_paths = [
        '/usr/local/bin/audiveris',
        '/opt/audiveris/bin/Audiveris',
        '/opt/audiveris/audiveris',
        '/usr/bin/audiveris'
    ]
    
    found_paths = []
    for path in common_paths:
        if os.path.exists(path):
            found_paths.append(path)
    
    debug_info["found_audiveris_paths"] = found_paths
    
    # List contents of /opt/audiveris if it exists
    if os.path.exists('/opt/audiveris'):
        try:
            debug_info["opt_audiveris_contents"] = os.listdir('/opt/audiveris')
        except:
            debug_info["opt_audiveris_contents"] = "Permission denied"
    
    # Test if Audiveris can actually run
    if audiveris_available:
        try:
            result = subprocess.run([audiveris_path, '-help'], 
                                  capture_output=True, text=True, timeout=10)
            debug_info["audiveris_test"] = {
                "can_execute": True,
                "exit_code": result.returncode,
                "stdout_preview": result.stdout[:200] if result.stdout else "No output",
                "stderr_preview": result.stderr[:200] if result.stderr else "No errors"
            }
        except subprocess.TimeoutExpired:
            debug_info["audiveris_test"] = {"can_execute": False, "error": "Timeout after 10 seconds"}
        except Exception as e:
            debug_info["audiveris_test"] = {"can_execute": False, "error": str(e)}
    else:
        debug_info["audiveris_test"] = {"can_execute": False, "error": "File not found"}
    
    # Check Java availability
    try:
        java_result = subprocess.run(['java', '-version'], 
                                   capture_output=True, text=True, timeout=5)
        debug_info["java_test"] = {
            "available": True,
            "version_info": java_result.stderr[:200] if java_result.stderr else java_result.stdout[:200]
        }
    except Exception as e:
        debug_info["java_test"] = {"available": False, "error": str(e)}
    
    return jsonify({
        "status": "ok",
        "audiveris_available": audiveris_available,
        "environment": "production" if not os.environ.get('DEBUG', 'False').lower() == 'true' else "development",
        "debug": debug_info
    }), 200

@app.route('/convert', methods=['POST'])
def convert_pdf():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    pdf = request.files['file']
    
    # Clean up any previous files to prevent cross-contamination
    cleanup_directories()

    # Save uploaded PDF
    os.makedirs("uploads", exist_ok=True)
    pdf_path = os.path.abspath(os.path.join("uploads", pdf.filename))
    pdf.save(pdf_path)

    # Create output folder
    output_dir = os.path.abspath(os.path.join("outputs", os.path.splitext(pdf.filename)[0]))
    os.makedirs(output_dir, exist_ok=True)

    # Path to Audiveris - configurable via environment variable
    audiveris_path = os.environ.get('AUDIVERIS_PATH', '/opt/audiveris/bin/Audiveris')
    
    # Check if we're on Windows (for local development)
    if os.name == 'nt' and not os.environ.get('AUDIVERIS_PATH'):
        audiveris_path = r"D:\Audiveris\audiveris\app\build\distributions\app-5.6.2\bin\Audiveris.bat"

    # Run Audiveris
    try:
        print(f"Running Audiveris with command: {audiveris_path} -batch {pdf_path} -export {output_dir}")
        result = subprocess.run([
            audiveris_path,
            "-batch",
            pdf_path,
            "-export", output_dir
        ], check=True, capture_output=True, text=True, timeout=300)
        print(f"Audiveris stdout: {result.stdout}")
        print(f"Audiveris stderr: {result.stderr}")
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Conversion timed out - the PDF may be too complex or not contain music'}), 500
    except subprocess.CalledProcessError as e:
        print(f"Audiveris failed with return code: {e.returncode}")
        print(f"Audiveris stdout: {e.stdout}")
        print(f"Audiveris stderr: {e.stderr}")
        return jsonify({'error': f'Audiveris processing failed: {e.stderr if e.stderr else "Unknown error"}'}), 500

    # Search for MXL files in both output directory and uploads directory
    print(f"Searching for MXL files in: {output_dir} and uploads directory")
    mxl_files = []
    
    for root, dirs, files in os.walk(output_dir):
        print(f"Checking output directory: {root}")
        print(f"Files found: {files}")
        for f in files:
            if f.lower().endswith(".mxl"):
                mxl_files.append(os.path.join(root, f))
                print(f"Found MXL file in output: {os.path.join(root, f)}")
    
    if not mxl_files:
        uploads_dir = os.path.abspath("uploads")
        for root, dirs, files in os.walk(uploads_dir):
            print(f"Checking uploads directory: {root}")
            print(f"Files found: {files}")
            for f in files:
                if f.lower().endswith(".mxl"):
                    mxl_files.append(os.path.join(root, f))
                    print(f"Found MXL file in uploads: {os.path.join(root, f)}")

    if not mxl_files:
        all_files = []
        for root, dirs, files in os.walk(output_dir):
            all_files.extend(files)
        
        print(f"No MXL files found. All files in output directory: {all_files}")
        
        if not all_files:
            return jsonify({'error': 'No files were generated - this PDF does not appear to contain recognizable sheet music'}), 400
        else:
            return jsonify({'error': 'PDF was processed but no music notation was found - please ensure the PDF contains clear sheet music'}), 400

    final_mxl_files = []
    for mxl_file in mxl_files:
        if "uploads" in mxl_file:
            filename = os.path.basename(mxl_file)
            new_path = os.path.join(output_dir, filename)
            shutil.move(mxl_file, new_path)
            final_mxl_files.append(new_path)
            print(f"Moved MXL file from uploads to output: {new_path}")
        else:
            final_mxl_files.append(mxl_file)
    
    mxl_path = final_mxl_files[0]
    musicxml_path = os.path.join(output_dir, "score.musicxml")

    try:
        print(f"Extracting MusicXML from: {mxl_path}")
        with zipfile.ZipFile(mxl_path, 'r') as zip_ref:
            xml_files = [f for f in zip_ref.namelist() if f.lower().endswith(".xml") and not f.startswith("container")]
            print(f"XML files found in MXL: {xml_files}")
            if not xml_files:
                return jsonify({'error': 'No MusicXML content found inside the generated file'}), 500
            with zip_ref.open(xml_files[0]) as f_in, open(musicxml_path, 'wb') as f_out:
                f_out.write(f_in.read())
                print(f"Extracted MusicXML to: {musicxml_path}")
    except zipfile.BadZipFile:
        return jsonify({'error': 'Generated file is corrupted - the PDF may not contain valid sheet music'}), 500

    try:
        with open(musicxml_path, 'r', encoding='utf-8') as f:
            musicxml_content = f.read()
        
        print(f"MusicXML content length: {len(musicxml_content)}")
        print(f"MusicXML preview: {musicxml_content[:200]}...")
        
        if '<score-partwise' not in musicxml_content and '<score-timewise' not in musicxml_content:
            print("ERROR: No score-partwise or score-timewise found in MusicXML")
            return jsonify({'error': 'Generated file does not contain valid music notation'}), 400
        else:
            print("SUCCESS: Valid MusicXML structure found")
            
    except Exception as e:
        print(f"ERROR reading MusicXML: {str(e)}")
        return jsonify({'error': f'Failed to read generated MusicXML: {str(e)}'}), 500

    return jsonify({
        'message': 'Conversion done',
        'musicxml': musicxml_content,
        'musicxml_path': musicxml_path,
        'mxl_source': mxl_path,
        'mxl_files': final_mxl_files
    })

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
