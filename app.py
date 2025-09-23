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

@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200

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

    # Path to Audiveris - use environment variable or default Linux path
    audiveris_cmd = os.environ.get('AUDIVERIS_PATH', 'audiveris')

    # Run Audiveris
    try:
        print(f"Running Audiveris with command: {audiveris_cmd} -batch -export -output {output_dir} {pdf_path}")
        result = subprocess.run([
            audiveris_cmd,
            "-batch",
            "-export", 
            "-output", output_dir,
            pdf_path
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
    # Audiveris sometimes creates MXL files in the same directory as the input PDF
    print(f"Searching for MXL files in: {output_dir} and uploads directory")
    mxl_files = []
    
    # Search in output directory first
    for root, dirs, files in os.walk(output_dir):
        print(f"Checking output directory: {root}")
        print(f"Files found: {files}")
        for f in files:
            if f.lower().endswith(".mxl"):
                mxl_files.append(os.path.join(root, f))
                print(f"Found MXL file in output: {os.path.join(root, f)}")
    
    # If no MXL files in output directory, check uploads directory
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
        # Also check if Audiveris created any files at all in the output directory
        all_files = []
        for root, dirs, files in os.walk(output_dir):
            all_files.extend(files)
        
        print(f"No MXL files found. All files in output directory: {all_files}")
        
        if not all_files:
            return jsonify({'error': 'No files were generated - this PDF does not appear to contain recognizable sheet music'}), 400
        else:
            return jsonify({'error': 'PDF was processed but no music notation was found - please ensure the PDF contains clear sheet music'}), 400

    # Move MXL files from uploads to output directory if they were created there
    final_mxl_files = []
    for mxl_file in mxl_files:
        if "uploads" in mxl_file:
            # Move the file to output directory
            filename = os.path.basename(mxl_file)
            new_path = os.path.join(output_dir, filename)
            shutil.move(mxl_file, new_path)
            final_mxl_files.append(new_path)
            print(f"Moved MXL file from uploads to output: {new_path}")
        else:
            final_mxl_files.append(mxl_file)
    
    # Take the first MXL file found (should be from current conversion only)
    mxl_path = final_mxl_files[0]
    musicxml_path = os.path.join(output_dir, "score.musicxml")

    # Extract MusicXML from MXL
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

    # Read the MusicXML content and return it
    try:
        with open(musicxml_path, 'r', encoding='utf-8') as f:
            musicxml_content = f.read()
        
        print(f"MusicXML content length: {len(musicxml_content)}")
        print(f"MusicXML preview: {musicxml_content[:200]}...")
        
        # Basic validation - check if the MusicXML contains actual music elements
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
        'musicxml': musicxml_content,  # This is what Flutter expects
        'musicxml_path': musicxml_path,
        'mxl_source': mxl_path,
        'mxl_files': final_mxl_files
    })

if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=False, host="0.0.0.0", port=port)
