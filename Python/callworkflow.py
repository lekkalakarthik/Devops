import requests

# Replace these with your details
# = ""   # GitHub Personal Access Token with repo/workflow scope
OWNER = "lekkalakarthik"
REPO = "Devops"
WORKFLOW_FILE = "sample.yaml"   # name of your workflow yaml in .github/workflows/
REF = "master"   # branch name

# Inputs to pass
inputs = {
    "name": "Karthik",
    "city": "Hyderabad"
}

# GitHub API endpoint
url = f"https://api.github.com/repos/{OWNER}/{REPO}/actions/workflows/{WORKFLOW_FILE}/dispatches"

headers = {
    "Accept": "application/vnd.github+json",
    "Authorization": f"Bearer {GITHUB_TOKEN}"
}

payload = {
    "ref": REF,
    "inputs": inputs
}

response = requests.post(url, headers=headers, json=payload)

if response.status_code == 204:
    print("✅ Workflow triggered successfully!")
else:
    print(f"❌ Failed to trigger workflow: {response.status_code}")
    print(response.text)
