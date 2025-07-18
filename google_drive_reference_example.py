# Google Drive File Reference Examples
# For Plus Paid Analytics Code Library

import pandas as pd
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import io
import os

# Example 1: Direct Google Drive API Access
def access_google_drive_file(file_id):
    """
    Access a specific file from Google Drive using its file ID
    """
    SCOPES = ['https://www.googleapis.com/auth/drive.readonly']
    
    creds = None
    # Load credentials from token.json if it exists
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    
    # If no valid credentials, authenticate
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save credentials for next run
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
    
    service = build('drive', 'v3', credentials=creds)
    
    # Download file content
    request = service.files().get_media(fileId=file_id)
    fh = io.BytesIO()
    downloader = MediaIoBaseDownload(fh, request)
    done = False
    while done is False:
        status, done = downloader.next_chunk()
        print(f"Download {int(status.progress() * 100)}%")
    
    return fh.getvalue()

# Example 2: Using gdown for public files
def download_public_google_drive_file(file_id, output_path):
    """
    Download public Google Drive files using gdown
    Install with: pip install gdown
    """
    import gdown
    
    url = f"https://drive.google.com/uc?id={file_id}"
    gdown.download(url, output_path, quiet=False)

# Example 3: Reference Google Drive files in documentation
def create_drive_reference_markdown():
    """
    Create markdown documentation with Google Drive references
    """
    drive_references = {
        "WBR Data Sources": {
            "description": "Weekly Business Review data files",
            "drive_link": "https://drive.google.com/drive/folders/YOUR_FOLDER_ID",
            "file_ids": {
                "revenue_data": "YOUR_FILE_ID_1",
                "lead_data": "YOUR_FILE_ID_2"
            }
        },
        "QBR Templates": {
            "description": "Quarterly Business Review templates",
            "drive_link": "https://drive.google.com/drive/folders/YOUR_FOLDER_ID",
            "file_ids": {
                "template": "YOUR_FILE_ID_3"
            }
        }
    }
    
    return drive_references

# Example 4: Load CSV from Google Drive into pandas
def load_csv_from_drive(file_id):
    """
    Load a CSV file directly from Google Drive into pandas DataFrame
    """
    file_content = access_google_drive_file(file_id)
    df = pd.read_csv(io.BytesIO(file_content))
    return df

# Example 5: Reference in SQL comments
sql_example = """
-- Data source: Google Drive file
-- File ID: YOUR_FILE_ID_HERE
-- Drive Link: https://drive.google.com/file/d/YOUR_FILE_ID_HERE/view
-- Last updated: 2024-01-15

SELECT * FROM `shopify-dw.sales.sales_leads`
WHERE created_date >= '2024-01-01'
-- Additional logic here
"""

if __name__ == "__main__":
    # Example usage
    print("Google Drive Reference Examples for Plus Paid Analytics")
    print("=" * 50)
    
    # Example file IDs (replace with actual IDs)
    example_files = {
        "WBR_Revenue_Data": "1ABC123DEF456GHI789JKL",
        "QBR_Template": "2XYZ789ABC123DEF456GHI",
        "DLV_Reference": "3DEF456GHI789JKL123ABC"
    }
    
    print("Common file references:")
    for name, file_id in example_files.items():
        print(f"- {name}: {file_id}")
        print(f"  Drive Link: https://drive.google.com/file/d/{file_id}/view") 