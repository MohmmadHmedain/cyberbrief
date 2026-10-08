# app.py
from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.neighbors import NearestNeighbors

app = FastAPI(title="CyberGuard AI API", version="1.0")

# تحميل المصنف الجاهز
clf_pipe = joblib.load("baseline_clf_ar.joblib")

# تحميل البيانات العربية
df = pd.read_csv("cyber_dataset_ar_from_kaggle.csv")

def build_text(row):
    parts = []
    if isinstance(row.get("description_ar"), str):
        parts.append(row["description_ar"])
    if isinstance(row.get("indicators_ar"), str) and row["indicators_ar"].strip():
        parts.append("مؤشرات: " + row["indicators_ar"])
    return " | ".join(parts).strip()

df["text"] = df.apply(build_text, axis=1)

vec = TfidfVectorizer(ngram_range=(1, 2), max_features=60000)
X = vec.fit_transform(df["text"])
nn = NearestNeighbors(n_neighbors=1, metric="cosine").fit(X)

class TextInput(BaseModel):
    text: str

@app.post("/classify")
def classify(inp: TextInput):
    label = clf_pipe.predict([inp.text])[0]
    probs = clf_pipe.predict_proba([inp.text])[0]
    idx = list(clf_pipe.classes_).index(label)
    confidence = float(probs[idx])
    return {"attack_type": label, "confidence": round(confidence, 3)}

@app.post("/respond")
def respond(inp: TextInput):
    q = vec.transform([inp.text])
    dist, idx = nn.kneighbors(q, return_distance=True)
    rec = df.iloc[idx[0][0]]
    resp = (rec.get("response_ar") or "").strip()
    mit = (rec.get("mitigation_ar") or "").strip()
    plan = resp
    if mit:
        plan += " | وقاية لاحقة: " + mit
    return {
        "matched_attack": rec.get("attack_name_ar", "غير معروف"),
        "similarity": round(1 - dist[0][0], 3),
        "plan": plan or "لم يتم العثور على خطة مناسبة"
    }

@app.get("/")
def root():
    return {"status": "✅ CyberGuard AI API تعمل بنجاح"}
