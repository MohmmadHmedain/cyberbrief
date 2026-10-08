import os
import time
from typing import Any, Dict, List

import requests
import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer


# ============================================================
# Configuration
# ============================================================

BASE_MODEL = "Qwen/Qwen2.5-3B-Instruct"
ADAPTER_PATH = "./qwen_cyber_lora"

VIRUSTOTAL_API_KEY = os.getenv("VIRUSTOTAL_API_KEY")
NEWS_API_KEY = os.getenv("NEWS_API_KEY")


# ============================================================
# System Prompt
# ============================================================

SYSTEM_PROMPT = """
You are a bilingual cybersecurity assistant for non-technical users.

You help with cybersecurity and online safety questions only.

Your job is to:
1. understand the user's situation,
2. identify the likely threat or scam type,
3. explain the risk simply,
4. tell the user what to do now,
5. tell the user what to avoid.

Rules:
- Answer cyber questions only.
- If the question is not about cybersecurity or online safety,
  politely redirect the user back to cyber topics.
- Keep replies calm, supportive, natural, short, and not robotic.
- You can answer in Arabic or English depending on the user's language.
""".strip()


# ============================================================
# Load AI Model
# ============================================================

print("Loading tokenizer...", flush=True)

tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)

if tokenizer.pad_token_id is None:
    tokenizer.pad_token = tokenizer.eos_token


print("Loading base model...", flush=True)

base_model = AutoModelForCausalLM.from_pretrained(
    BASE_MODEL,
    torch_dtype=torch.float32,
    low_cpu_mem_usage=True,
)


print("Loading LoRA adapter...", flush=True)

model = PeftModel.from_pretrained(
    base_model,
    ADAPTER_PATH,
)

model.eval()

print("Model loaded successfully.", flush=True)


# ============================================================
# FastAPI
# ============================================================

app = FastAPI(
    title="CyberGuard Backend",
    description="Backend API for the CyberGuard cybersecurity assistant.",
    version="1.0.0",
)


# ============================================================
# Request Models
# ============================================================

class ChatRequest(BaseModel):
    messages: List[Dict[str, Any]]


class URLScanRequest(BaseModel):
    url: str


# ============================================================
# Root
# ============================================================

@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "CyberGuard Backend is running",
        "services": [
            "chat",
            "news",
            "virus_total_url_scan",
        ],
    }


# ============================================================
# AI CHAT
# ============================================================

@app.post("/chat")
def chat(request: ChatRequest):
    print("CHAT request received", flush=True)

    start_time = time.time()

    incoming_messages = request.messages or []

    prompt_messages = [
        {
            "role": "system",
            "content": SYSTEM_PROMPT,
        }
    ]

    # Use only the latest 8 messages
    for msg in incoming_messages[-8:]:

        role = str(
            msg.get("role", "user")
        ).strip()

        content = str(
            msg.get("content", "")
        ).strip()

        if role not in {
            "system",
            "user",
            "assistant",
        }:
            continue

        if not content:
            continue

        prompt_messages.append(
            {
                "role": role,
                "content": content,
            }
        )

    prompt_text = tokenizer.apply_chat_template(
        prompt_messages,
        tokenize=False,
        add_generation_prompt=True,
    )

    inputs = tokenizer(
        prompt_text,
        return_tensors="pt",
    )

    print("Starting generation...", flush=True)

    with torch.no_grad():

        outputs = model.generate(
            **inputs,
            max_new_tokens=120,
            do_sample=False,
            temperature=0.0,
            pad_token_id=tokenizer.pad_token_id,
            eos_token_id=tokenizer.eos_token_id,
        )

    elapsed = time.time() - start_time

    print(
        f"Generation finished in {elapsed:.1f} seconds",
        flush=True,
    )

    generated_tokens = outputs[0][
        inputs["input_ids"].shape[1]:
    ]

    reply = tokenizer.decode(
        generated_tokens,
        skip_special_tokens=True,
    ).strip()

    if not reply:
        reply = (
            "Sorry, I could not generate "
            "a response right now."
        )

    return {
        "reply": reply
    }


# ============================================================
# NEWS API
# ============================================================

@app.get("/news")
def get_news(language: str = "en"):

    if not NEWS_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="NEWS_API_KEY is not configured.",
        )

    if language not in {"ar", "en"}:
        language = "en"

    if language == "ar":

        query = (
            '("الأمن السيبراني" OR '
            '"هجوم سيبراني" OR '
            '"اختراق" OR '
            '"احتيال إلكتروني" OR '
            '"جرائم إلكترونية" OR '
            '"حماية البيانات") '
            'AND '
            '(الأردن OR الأردنية OR عمان)'
        )

    else:

        query = (
            'cybersecurity OR '
            '"cyber attack" OR '
            'hacking OR '
            'malware OR '
            'phishing OR '
            'ransomware'
        )

    params = {
        "q": query,
        "language": language,
        "sortBy": "publishedAt",
        "pageSize": 20,
        "apiKey": NEWS_API_KEY,
    }

    try:

        response = requests.get(
            "https://newsapi.org/v2/everything",
            params=params,
            timeout=20,
        )

        if response.status_code != 200:

            print(
                "News API error:",
                response.text,
                flush=True,
            )

            raise HTTPException(
                status_code=response.status_code,
                detail="News API request failed.",
            )

        data = response.json()

        articles = data.get(
            "articles",
            [],
        )

        filtered_articles = []

        for article in articles:

            title = str(
                article.get("title") or ""
            ).strip()

            description = str(
                article.get("description") or ""
            ).strip()

            if (
                title
                and title != "[Removed]"
                and description != "[Removed]"
            ):
                filtered_articles.append(article)

        return {
            "status": "ok",
            "articles": filtered_articles,
        }

    except requests.RequestException as e:

        print(
            f"News API connection error: {e}",
            flush=True,
        )

        raise HTTPException(
            status_code=502,
            detail="Unable to reach News API.",
        )


# ============================================================
# VIRUSTOTAL URL SCAN
# ============================================================

@app.post("/scan-url")
def scan_url(request: URLScanRequest):

    if not VIRUSTOTAL_API_KEY:

        raise HTTPException(
            status_code=500,
            detail="VIRUSTOTAL_API_KEY is not configured.",
        )

    url = request.url.strip()

    if not url:

        raise HTTPException(
            status_code=400,
            detail="URL cannot be empty.",
        )

    headers = {
        "accept": "application/json",
        "x-apikey": VIRUSTOTAL_API_KEY,
    }

    try:

        response = requests.post(
            "https://www.virustotal.com/api/v3/urls",
            headers=headers,
            data={
                "url": url,
            },
            timeout=30,
        )

        if response.status_code not in {
            200,
            201,
        }:

            print(
                "VirusTotal scan error:",
                response.text,
                flush=True,
            )

            raise HTTPException(
                status_code=response.status_code,
                detail="VirusTotal URL scan failed.",
            )

        data = response.json()

        analysis_id = (
            data
            .get("data", {})
            .get("id")
        )

        if not analysis_id:

            raise HTTPException(
                status_code=502,
                detail="VirusTotal did not return an analysis ID.",
            )

        return {
            "status": "submitted",
            "scan_id": analysis_id,
        }

    except requests.RequestException as e:

        print(
            f"VirusTotal connection error: {e}",
            flush=True,
        )

        raise HTTPException(
            status_code=502,
            detail="Unable to reach VirusTotal.",
        )


# ============================================================
# VIRUSTOTAL ANALYSIS RESULT
# ============================================================

@app.get("/scan-url/{scan_id}")
def get_scan_result(scan_id: str):

    if not VIRUSTOTAL_API_KEY:

        raise HTTPException(
            status_code=500,
            detail="VIRUSTOTAL_API_KEY is not configured.",
        )

    headers = {
        "accept": "application/json",
        "x-apikey": VIRUSTOTAL_API_KEY,
    }

    try:

        response = requests.get(
            f"https://www.virustotal.com/api/v3/analyses/{scan_id}",
            headers=headers,
            timeout=30,
        )

        if response.status_code != 200:

            print(
                "VirusTotal analysis error:",
                response.text,
                flush=True,
            )

            raise HTTPException(
                status_code=response.status_code,
                detail="Unable to retrieve VirusTotal analysis.",
            )

        data = response.json()

        analysis_data = data.get(
            "data",
            {},
        )

        attributes = analysis_data.get(
            "attributes",
            {},
        )

        stats = attributes.get(
            "stats",
            {},
        )

        status = attributes.get(
            "status",
            "unknown",
        )

        return {
            "status": status,
            "stats": stats,
            "results": attributes.get(
                "results",
                {},
            ),
        }

    except requests.RequestException as e:

        print(
            f"VirusTotal connection error: {e}",
            flush=True,
        )

        raise HTTPException(
            status_code=502,
            detail="Unable to reach VirusTotal.",
        )


# ============================================================
# Startup Information
# ============================================================

@app.on_event("startup")
def startup_event():

    print(
        "========================================",
        flush=True,
    )

    print(
        "CyberGuard Backend started",
        flush=True,
    )

    print(
        f"News API configured: "
        f"{bool(NEWS_API_KEY)}",
        flush=True,
    )

    print(
        f"VirusTotal configured: "
        f"{bool(VIRUSTOTAL_API_KEY)}",
        flush=True,
    )

    print(
        "========================================",
        flush=True,
    )