import sqlite3

DB_PATH = "papers.db"

# Connect and create table
conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("""
    CREATE TABLE IF NOT EXISTS papers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        url TEXT,
        path TEXT,
        abstract TEXT
    )
""")

# Insert sample rows
sample_papers = [
    ("Attention Is All You Need", "https://arxiv.org/pdf/1706.03762.pdf", "downloads/attention_is_all_you_need.pdf", "Transformer model for sequence transduction."),
    ("BERT: Pre-training of Deep Bidirectional Transformers", "https://arxiv.org/pdf/1810.04805.pdf", "downloads/bert.pdf", "Language model pre-training for NLP tasks."),
    ("GPT-3: Language Models are Few-Shot Learners", "https://arxiv.org/pdf/2005.14165.pdf", "downloads/gpt3.pdf", "175B parameter model for NLP few-shot learning.")
]

cur.executemany("INSERT INTO papers (title, url, path, abstract) VALUES (?,?,?,?)", sample_papers)

conn.commit()
conn.close()

print("Sample papers.db created with 3 records.")