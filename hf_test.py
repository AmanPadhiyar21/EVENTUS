import requests

HF_MODEL = "deepseek-ai/DeepSeek-V3.1-Base"  # must be a model with Inference API
HF_API_TOKEN = "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"

headers = {"Authorization": f"Bearer {HF_API_TOKEN}"}
data = {"inputs": "Hello, how are you?"}

response = requests.post(
    f"https://api-inference.huggingface.co/models/{HF_MODEL}",
    headers=headers,
    json=data,
    timeout=30
)

print(response.status_code)
print(response.text)  # use .text instead of .json() to avoid JSONDecodeError
