import os
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from services.image_processor import process_uploaded_image
import logging
from dotenv import load_dotenv

load_dotenv()
app = FastAPI()


@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    result = await process_uploaded_image(file)

    return JSONResponse(content=result)