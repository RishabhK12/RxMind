from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse

app = FastAPI()


@app.post("/upload-image/")
async def upload_image(file: UploadFile = File(...)):
    contents = await file.read()

    return JSONResponse(content={
        "filename": file.filename,
        "content_type": file.content_type,
        "size_bytes": len(contents),
        "message": "Image received successfully"
    })
