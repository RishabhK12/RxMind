This directory holds the backend code for the project.

1. Run the following to install the required dependencies:
   ```bash
    pip install fastapi uvicorn python-multipart pytesseract python-dotenv google-genai
   ```

2. Download the Tesseract installer from this link: https://github.com/UB-Mannheim/tesseract/wiki
   and install it on your system. Make sure to add the following to your system's PATH environment variable.

   `C:\Program Files\Tesseract-OCR` (or your own installation path).

3. Make a copy of the `sample.env` file and rename it to `.env`. Set the `GEMINI_API_KEY` in the `.env` file to your Gemini API key. To obtain a Gemini API key, navigate to https://aistudio.google.com/app/apikey and create an API key.

4. Run the app with the following command:
   ```bash
    python -m uvicorn main:app --reload
   ```
5. Access the Swagger UI for the API at: http://localhost:8000/docs