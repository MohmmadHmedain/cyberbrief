# baseline_clf_ar.py
import json, pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report
import joblib

def load_jsonl(path):
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            rows.append(json.loads(line))
    return pd.DataFrame(rows)

train = load_jsonl("clf_train_ar.jsonl")
valid = load_jsonl("clf_valid_ar.jsonl")

pipe = Pipeline([
    ("tfidf", TfidfVectorizer(ngram_range=(1,2), min_df=2, max_features=50000)),
    ("clf", LogisticRegression(max_iter=1000))
])

pipe.fit(train["text"], train["label"])
pred = pipe.predict(valid["text"])

print("✅ تقرير التقييم:")
print(classification_report(valid["label"], pred, digits=3))

joblib.dump(pipe, "baseline_clf_ar.joblib")
print("💾 تم الحفظ: baseline_clf_ar.joblib")
