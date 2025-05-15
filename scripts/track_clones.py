import os
import requests
import json
from datetime import datetime
from dotenv import load_dotenv  # Only for local runs

# --- Configuration ---
REPO_OWNER = "avantonder"  # Update this!
REPO_NAME = "assembleBAC-ONT"         # Update this!
LOG_FILE = "clone_log.json"          # Output file

# --- Load GitHub Token Securely ---
# Method 1: GitHub Actions Secret (priority)
token = os.environ.get("GITHUB_TOKEN")

# Method 2: Fallback to .env file (for local testing)
if not token:
    load_dotenv()  # Load from .env file
    token = os.environ.get("GITHUB_TOKEN")

if not token:
    raise ValueError(
        "GitHub token not found! "
        "Set it as a GitHub Actions secret or in a .env file."
    )

# --- Fetch Clone Data ---
url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/traffic/clones"
headers = {
    "Authorization": f"token {token}",
    "Accept": "application/vnd.github.v3+json"
}

try:
    response = requests.get(url, headers=headers)
    response.raise_for_status()  # Raise error for bad status codes
    data = response.json()
except requests.exceptions.RequestException as e:
    print(f"API request failed: {e}")
    exit(1)

# --- Update Log File ---
try:
    with open(LOG_FILE, "r") as f:
        log = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    log = []

log.append({
    "timestamp": datetime.now().isoformat(),
    "total_clones": data.get("count", 0),
    "unique_cloners": data.get("uniques", 0),
    "daily_data": data.get("clones", [])
})

with open(LOG_FILE, "w") as f:
    json.dump(log, f, indent=2)

print(f"Logged {data.get('count', 0)} clones ({data.get('uniques', 0)} unique cloners).")
