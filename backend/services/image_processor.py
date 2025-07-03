from fastapi import UploadFile
from PIL import Image
import io
from .ocr import extract_text_from_image
from PIL import features
from .llm import simplify_medical_text


async def process_uploaded_image(file: UploadFile) -> dict:
    contents = await file.read()

    try:
        image = Image.open(io.BytesIO(contents))
        image.verify()
        image = Image.open(io.BytesIO(contents))
    except UnidentifiedImageError:
        raise HTTPException(
            status_code=400, detail="Uploaded file is not a valid image")

    extracted_text = extract_text_from_image(image)
    llm_response = simplify_medical_text(extracted_text)

    return {
        "extracted_text": extracted_text,
        "llm_summary": llm_response["llm_output"],
        "message": "Image uploaded, text extracted, and summarized successfully"
    }
