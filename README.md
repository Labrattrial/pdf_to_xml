# Audiveris + Flask API for Render.com

This project provides a ready-to-deploy Flask API for converting PDF sheet music to MusicXML using Audiveris, designed for easy deployment on Render.com (no Docker required).

## Features
- Upload a PDF via `/upload` endpoint
- Converts PDF to MusicXML using Audiveris
- Serves MusicXML files via `/musicxml/<filename>` endpoint
- Stores uploaded PDFs and generated MusicXML files on the server

## Folder Structure
- `uploads/` — stores uploaded PDF files
- `musicxml/` — stores generated MusicXML files

## Endpoints

### POST `/upload`
- **Body:** `file` (PDF file, multipart/form-data)
- **Response:** `{ "musicxml_url": "https://<your-app>.onrender.com/musicxml/<filename>.musicxml" }`

### GET `/musicxml/<filename>`
- Returns the MusicXML file for download or frontend use

## Deploying on Render.com

1. **Push this folder to a new GitHub repository.**
2. **Go to [Render.com](https://render.com/)** and create a new Web Service.
3. **Connect your GitHub repo.**
4. **Set the following:**
   - **Build Command:** `./render-build.sh`
   - **Start Command:** `python pdf_to_musicxml.py`
   - **Environment:** Python 3.9+
5. **Click Create Web Service.**
6. **Wait for build and deploy to finish.**

## Usage Example

**Upload a PDF:**
```bash
curl -F "file=@your_score.pdf" https://<your-app>.onrender.com/upload
```
**Get the MusicXML:**
Use the `musicxml_url` from the response to download or display the MusicXML file.

## Notes
- Audiveris is downloaded automatically during build (see `render-build.sh`).
- The API listens on port 10000 as required by Render.com.
- You can use the returned MusicXML URL in your frontend (e.g., Flutter) to display the music sheet.

---

**Questions?** Open an issue or contact the author. 