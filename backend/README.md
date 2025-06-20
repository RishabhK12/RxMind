This directory holds the backend code for the project.

1. Run the following to install the required dependencies:
   ```bash
    pip install fastapi uvicorn python-multipart
   ```

2. Run the app with the following command:
   ```bash
    python -m uvicorn main:app --reload
   ```
3. Access the Swagger UI for the API at: http://localhost:8000/docs