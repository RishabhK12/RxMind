from google import genai
import os
import logging
from dotenv import load_dotenv
import os

load_dotenv()

api_key = os.getenv('GEMINI_API_KEY')
if not api_key:
    raise RuntimeError("GEMINI_API_KEY not found in environment")

client = genai.Client(api_key=api_key)

def simplify_medical_text(text: str) -> dict:
    prompt = f"""
You are a medical assistant. Simplify the following medical instructions into:
1. A plain-language summary for a non-expert.
2. A checklist of tasks or reminders.

Original Text:
{text}

Respond in this format:
Summary: <simple explanation>
Checklist: [<item 1>, <item 2>, ...]
"""
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        return {"llm_output": response.text.strip()}
    except Exception as e:
        logging.exception("Gemini API call failed")
        return {"error": str(e)}
