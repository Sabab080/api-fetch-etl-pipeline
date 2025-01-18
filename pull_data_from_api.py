import requests
import pandas as pd
import pendulum
import sys

# Define the API URL
url = ''

# Define the access token
access_token = ''

# Define the request headers
headers = {
    'token': f'{access_token}',
    'Content-Type': 'application/json'
}

# Parse command-line arguments
def get_dates():
    # Check if start_date and end_date were provided as arguments
    if len(sys.argv) >= 3:
        start_date = sys.argv[1]
        end_date = sys.argv[2]
    else:
        # Default to Date-2 for start_date and Date-1 for end_date
        start_date = pendulum.now("Asia/Dhaka").subtract(days=2).strftime('%Y-%m-%d')
        end_date = pendulum.now("Asia/Dhaka").subtract(days=1).strftime('%Y-%m-%d')

    return start_date, end_date

# Define the data-fetching function
def fetch_data(start_date, end_date):
    # Define the request payload
    payload = {
        "startDate": start_date,
        "endDate": end_date
    }

    # Make the POST request
    response = requests.post(url, headers=headers, json=payload)

    # Check if the request was successful
    if response.status_code == 200:
        data = response.json().get('data')

        if data:
            # Convert data to DataFrame
            df = pd.DataFrame(data)

            # Save to CSV
            file_name = f"/commerce/data/ticket_{end_date}.csv"
            df.to_csv(file_name, index=False)
            print(f"Data successfully saved to {file_name}")
        else:
            print("No data found for the specified date range.")
    else:
        # Handle request failure
        print(f"Request failed with status code {response.status_code}")
        print('Response:', response.text)

if __name__ == "__main__":
    start_date, end_date = get_dates()
    fetch_data(start_date, end_date)
