# Audiforge Service

This is a Dockerized version of the Audiforge service for converting PDF music scores to MusicXML format.

## Deployment on Render.com

1. Fork or clone this repository
2. Go to [Render.com](https://render.com)
3. Sign up/Login
4. Click "New +"
5. Select "Web Service"
6. Connect your GitHub repository
7. Select this repository
8. Render will automatically detect the configuration from `render.yaml`

## Local Development

To run the service locally:

```bash
# Pull the image
docker pull ghcr.io/nirmata-1/audiforge:latest

# Run the container
docker run -d -p 8080:8080 \
  -v $(pwd)/uploads:/tmp/uploads \
  -v $(pwd)/downloads:/tmp/downloads \
  ghcr.io/nirmata-1/audiforge:latest
```

## Usage

The service will be available at:
- Local: `http://localhost:8080`
- Render: `https://your-app-name.onrender.com`

### API Endpoints

- `POST /convert` - Convert PDF to MusicXML
  - Send PDF file in the request body
  - Returns MusicXML file

### Example Usage in Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

class AudiforgeService {
  final String baseUrl = 'https://your-app-name.onrender.com'; // Change to your Render URL

  Future<String> convertPdfToMusicXml(File pdfFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/convert'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          pdfFile.path,
        ),
      );

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        String outputPath = '${pdfFile.path}.musicxml';
        File(outputPath).writeAsBytesSync(responseData);
        return outputPath;
      } else {
        throw Exception('Failed to convert PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error converting PDF: $e');
    }
  }
}
```

## Notes

- The free tier of Render.com has some limitations:
  - Service spins down after 15 minutes of inactivity
  - First request after spin-down might take 30-60 seconds
  - Limited storage (1GB per disk)
  - Limited bandwidth

## License

This project uses the Audiforge service from [Nirmata](https://github.com/nirmata-1/audiforge). 