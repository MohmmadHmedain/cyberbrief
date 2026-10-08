# prepare_data_ar.py
import pandas as pd
from sklearn.model_selection import train_test_split

AR_CSV = "cyber_dataset_ar_from_kaggle.csv"
df = pd.read_csv(AR_CSV)

required = ["attack_name_ar","description_ar","indicators_ar","mitigation_ar","response_ar"]
missing = [c for c in required if c not in df.columns]
if missing:
    raise ValueError(f"الأعمدة الناقصة: {missing}")

def build_text(row):
    parts = []
    if isinstance(row.get("description_ar"), str):
        parts.append(row["description_ar"])
    if isinstance(row.get("indicators_ar"), str) and row["indicators_ar"].strip():
        parts.append("مؤشرات: " + row["indicators_ar"])
    return " | ".join(parts).strip()

data = pd.DataFrame({
    "text": df.apply(build_text, axis=1),
    "label": df["attack_name_ar"].fillna("").astype(str)
})
data = data[(data["text"].str.strip()!="") & (data["label"].str.strip()!="")].reset_index(drop=True)

train_df, valid_df = train_test_split(data, test_size=0.2, stratify=data["label"], random_state=42)

def build_prompt(row):
    parts = []
    if isinstance(row.get("description_ar"), str) and row["description_ar"].strip():
        parts.append(f"الوصف: {row['description_ar']}")
    if isinstance(row.get("indicators_ar"), str) and row["indicators_ar"].strip():
        parts.append(f"مؤشرات: {row['indicators_ar']}")
    return "\n".join(parts)

def build_response(row):
    steps = []
    if isinstance(row.get("response_ar"), str) and row["response_ar"].strip():
        steps.append(row["response_ar"])
    if isinstance(row.get("mitigation_ar"), str) and row["mitigation_ar"].strip():
        steps.append("وقاية لاحقة: " + row["mitigation_ar"])
    return " | ".join(steps)

gen = pd.DataFrame({
    "prompt": df.apply(build_prompt, axis=1),
    "response": df.apply(build_response, axis=1)
})
gen = gen[(gen["prompt"].str.strip()!="") & (gen["response"].str.strip()!="")].reset_index(drop=True)

gen_train, gen_valid = train_test_split(gen, test_size=0.2, random_state=42)

train_df.to_json("clf_train_ar.jsonl", orient="records", force_ascii=False, lines=True)
valid_df.to_json("clf_valid_ar.jsonl", orient="records", force_ascii=False, lines=True)
gen_train.to_json("gen_train_ar.jsonl", orient="records", force_ascii=False, lines=True)
gen_valid.to_json("gen_valid_ar.jsonl", orient="records", force_ascii=False, lines=True)

print("✅ جهّزنا: clf_train_ar.jsonl / clf_valid_ar.jsonl / gen_train_ar.jsonl / gen_valid_ar.jsonl")
