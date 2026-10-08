# baseline_retrieval_ar.py
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.neighbors import NearestNeighbors

AR_CSV = "cyber_dataset_ar_from_kaggle.csv"
df = pd.read_csv(AR_CSV)

def build_text(row):
    parts = []
    if isinstance(row.get("description_ar"), str):
        parts.append(row["description_ar"])
    if isinstance(row.get("indicators_ar"), str) and row["indicators_ar"].strip():
        parts.append("مؤشرات: " + row["indicators_ar"])
    return " | ".join(parts).strip()

df["text"] = df.apply(build_text, axis=1)
df = df[(df["text"].str.strip()!="")].reset_index(drop=True)

vec = TfidfVectorizer(ngram_range=(1,2), max_features=60000)
X = vec.fit_transform(df["text"])

nn = NearestNeighbors(n_neighbors=1, metric="cosine")
nn.fit(X)

def suggest_plan(user_text):
    q = vec.transform([user_text])
    dist, idx = nn.kneighbors(q, return_distance=True)
    i = idx[0][0]
    rec = df.iloc[i]
    resp = (rec.get("response_ar") or "").strip()
    mit  = (rec.get("mitigation_ar") or "").strip()
    plan = []
    if resp: plan.append(resp)
    if mit:  plan.append("وقاية لاحقة: " + mit)
    return {
        "matched_attack": rec.get("attack_name_ar","غير معروف"),
        "similarity": float(1 - dist[0][0]),
        "plan": " | ".join([p for p in plan if p])
    }

if __name__ == "__main__":
    while True:
        s = input("\nاكتب وصف المشكلة بالعربي (أو اكتب quit):\n> ").strip()
        if s.lower() == "quit":
            break
        out = suggest_plan(s)
        print(f"\n🔎 أقرب هجوم: {out['matched_attack']}")
        print(f"درجة التشابه: {out['similarity']:.3f}")
        print(f"\n🛠️ خطة فورية:\n{out['plan'] if out['plan'] else 'لا توجد خطة جاهزة في السطر المطابق'}")
