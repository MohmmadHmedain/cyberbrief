# CyberBrief 🛡️

**AI-Powered Cybersecurity Assistant & Digital Safety Platform**

CyberBrief is a cybersecurity-focused mobile application designed to help non-technical users understand cyber threats, identify suspicious activity, and receive practical cybersecurity guidance in Arabic and English.

The project combines a **Flutter mobile application** with a **FastAPI backend** and an AI-powered cybersecurity assistant.

---

## 🎯 Project Goal

The goal of CyberBrief is to make cybersecurity information easier to understand and more accessible to everyday users.

The application focuses on:

* Cybersecurity awareness
* AI-assisted cybersecurity guidance
* Suspicious URL analysis
* Cybersecurity news
* Frequently asked security questions
* Threat awareness and reporting
* Arabic and English support

---

## ✨ Key Features

### 🤖 AI Cybersecurity Assistant

* Bilingual Arabic/English cybersecurity assistant
* Designed for non-technical users
* Provides simple explanations of cyber threats
* Gives practical steps users can take after a security incident
* Uses a Qwen-based language model with a cybersecurity LoRA adapter

### 🔗 Suspicious URL Scanning

* URL scanning through the backend
* VirusTotal API v3 integration
* Returns analysis status and detection statistics
* API credentials are handled through environment variables

### 📰 Cybersecurity News

* Cybersecurity news integration through NewsAPI
* Arabic and English content
* Supports cybersecurity-related topics such as:

  * Phishing
  * Malware
  * Ransomware
  * Cyber attacks
  * Hacking

### 🔐 Authentication & Security

* Supabase authentication
* Local authentication/session management
* Secure local storage mechanisms
* Password hashing and protected credential handling

### 🌐 Bilingual Interface

* Arabic
* English
* Saved language preference
* Cybersecurity content adapted for both languages

---

## 🏗️ Architecture

```text
┌──────────────────────────────┐
│       Flutter Application    │
│                              │
│  Authentication              │
│  AI Chat                     │
│  URL Scanner                 │
│  Cyber News                  │
│  Threat Information          │
└──────────────┬───────────────┘
               │
               │ HTTP / JSON
               ▼
┌──────────────────────────────┐
│       FastAPI Backend        │
│                              │
│  /chat                       │
│  /news                       │
│  /scan-url                   │
│  /scan-url/{scan_id}         │
└───────┬─────────┬────────────┘
        │         │
        ▼         ▼
   AI Model    External APIs
   Qwen +      NewsAPI
   LoRA        VirusTotal
```

---

## 🧰 Technologies

### Mobile Application

* Flutter
* Dart
* Supabase
* HTTP/REST APIs
* Secure local storage

### Backend

* Python
* FastAPI
* Pydantic
* Requests

### AI

* Qwen2.5-3B-Instruct
* Hugging Face Transformers
* PEFT / LoRA
* PyTorch

### Cybersecurity Services

* VirusTotal API v3
* Cybersecurity news feeds
* URL threat analysis

---

## 📁 Project Structure

```text
cyberbrief/
│
├── android/              # Android application
├── ios/                  # iOS application
├── lib/                  # Flutter source code
│   ├── screens/
│   ├── services/
│   └── widgets/
│
├── backend/
│   ├── main.py           # FastAPI backend
│   └── qwen_cyber_lora/  # Model configuration/metadata
│
├── ai_training/          # AI training and data preparation scripts
├── assets/               # Application assets
├── pubspec.yaml          # Flutter dependencies
└── README.md
```

---

## 🔐 Security & Secrets Management

API credentials are **not hardcoded in the source code**.

The backend expects external configuration through environment variables:

```text
NEWS_API_KEY
VIRUSTOTAL_API_KEY
```

The Flutter application uses environment-based configuration for the backend URL and Supabase configuration.

Sensitive files such as:

* API keys
* `.env` files
* local databases
* AI model weights
* training datasets
* build artifacts

are excluded from the public repository through `.gitignore`.

> Never commit production secrets, private API keys, Supabase service-role keys, or model credentials to source control.

---

## 🚀 Running the Backend

Install the required Python dependencies, then configure the required environment variables.

Example:

```powershell
$env:NEWS_API_KEY="YOUR_NEWS_API_KEY"
$env:VIRUSTOTAL_API_KEY="YOUR_VIRUSTOTAL_API_KEY"
```

Start the FastAPI server:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8000
```

The backend provides:

```text
GET  /
POST /chat
GET  /news
POST /scan-url
GET  /scan-url/{scan_id}
```

---

## 📱 Running the Flutter Application

Install Flutter dependencies:

```bash
flutter pub get
```

For an Android emulator, the default backend URL is:

```text
http://10.0.2.2:8000
```

A different backend can be supplied using:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_BACKEND:8000
```

For production deployments, an HTTPS backend should be used.

---

## 🤖 AI Model

CyberBrief uses:

```text
Qwen/Qwen2.5-3B-Instruct
```

with a cybersecurity-focused LoRA adapter.

The model weights are intentionally **not included in this repository** because of their size and deployment considerations.

The backend expects the required model files to be available locally when running the AI service.

---

## ⚠️ Project Limitations

CyberBrief is a cybersecurity portfolio and educational project.

Important limitations include:

* URL scanning depends on the availability of VirusTotal.
* Cybersecurity news depends on NewsAPI.
* The AI assistant can produce incorrect or incomplete responses.
* The local file/hash scanning functionality should not be considered a full antivirus engine.
* AI model weights are not included in the public repository.
* Production deployment would require additional security controls, monitoring, rate limiting, HTTPS, and proper infrastructure configuration.

CyberBrief should therefore be considered an **assistive cybersecurity tool**, not a replacement for professional incident response or security products.

---

## 🎓 Portfolio Focus

This project demonstrates practical experience with:

* Cybersecurity application development
* Secure API integration
* REST API design
* AI/LLM integration
* Prompt engineering
* LoRA-based model adaptation
* Authentication
* Secret management
* Threat intelligence API integration
* Flutter mobile development
* Python/FastAPI backend development

---

## 👨‍💻 Author

**Mohammad Hmedain**

Cybersecurity Graduate | Cybersecurity Analyst | Penetration Testing | Incident Response

GitHub: **MohmmadHmedain**

---

## 📌 Disclaimer

This project was developed for educational, research, and portfolio purposes.

Always verify security recommendations with trusted cybersecurity sources and follow applicable laws and organizational security policies.
