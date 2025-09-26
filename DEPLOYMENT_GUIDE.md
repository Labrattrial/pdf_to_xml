# PDF to MusicXML Converter - Deployment Guide

## 🚀 Ready to Deploy!

Your PDF to MusicXML converter is now ready for deployment with your local Audiveris installation.

## 📋 What's Included

- ✅ Flask API server (`app.py`)
- ✅ Docker configuration (`Dockerfile`)
- ✅ Render deployment config (`render.yaml`)
- ✅ Your local Audiveris installation (`audiveris_local/`)
- ✅ Health check endpoint with Audiveris verification
- ✅ Production-ready configuration

## 🌐 Deploy to Render.com

### Step 1: Create GitHub Repository
1. Go to [GitHub.com](https://github.com) and create a new repository
2. Copy the repository URL (e.g., `https://github.com/yourusername/pdf-converter.git`)

### Step 2: Push Your Code
```bash
git remote add origin YOUR_GITHUB_REPO_URL
git branch -M main
git push -u origin main
```

### Step 3: Deploy on Render
1. Go to [render.com](https://render.com) and sign up/login
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub account and select your repository
4. Render will automatically detect your `render.yaml` configuration
5. Click **"Deploy"**

## 🔍 Verify Deployment

### Check Health Endpoint
Once deployed, visit: `https://your-app-name.onrender.com/health`

You should see:
```json
{
  "status": "ok",
  "audiveris_path": "/usr/local/bin/audiveris",
  "audiveris_available": true,
  "platform": "posix",
  "environment": "production"
}
```

### Test PDF Conversion
Send a POST request to: `https://your-app-name.onrender.com/convert`
- Include a PDF file in the request body
- You'll receive MusicXML content in response

## 📱 API Endpoints

### Health Check
- **URL**: `GET /health`
- **Response**: Server status and Audiveris availability

### Convert PDF
- **URL**: `POST /convert`
- **Body**: Multipart form with PDF file
- **Response**: JSON with MusicXML content

## ⚡ Performance Notes

- **First deployment**: Takes ~10-15 minutes (copying Audiveris files)
- **Subsequent deployments**: ~3-5 minutes (Docker layer caching)
- **Cold starts**: ~30 seconds on free tier
- **Processing time**: Depends on PDF complexity (30s-5min typical)

## 🛠️ Troubleshooting

### If `audiveris_available: false`
1. Check Render build logs for errors
2. Verify `audiveris_local/` folder was uploaded correctly
3. Check Docker build process in deployment logs

### If conversion fails
1. Ensure PDF contains clear sheet music notation
2. Check file size limits (Render free tier has limits)
3. Monitor timeout settings (currently 5 minutes)

## 💡 Usage in Your App

```javascript
// Example: Upload PDF and get MusicXML
const formData = new FormData();
formData.append('file', pdfFile);

const response = await fetch('https://your-app.onrender.com/convert', {
  method: 'POST',
  body: formData
});

const result = await response.json();
const musicXML = result.musicxml; // Your converted MusicXML content
```

## 🎯 Next Steps

1. **Push to GitHub** using the commands above
2. **Deploy on Render** following the steps
3. **Test with sample PDFs** to verify functionality
4. **Integrate with your app** using the API endpoints

Your PDF to MusicXML conversion server is ready to go! 🎵