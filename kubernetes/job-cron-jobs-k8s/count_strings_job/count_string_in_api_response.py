import requests
import logging
import sys

# Configure logging
logging.basicConfig(level=logging.INFO)

def fetch_data_from_api(url):
    """Fetch data from a given API URL."""
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise error for bad status codes (4xx, 5xx)
        return response.json()  # Return JSON response
    except requests.exceptions.RequestException as e:
        logging.error(f"Error fetching data from API: {e}")
        sys.exit(1)

def count_occurrences_in_data(data, field_name, search_string):
    """Counts occurrences of search_string in a specific field of JSON data."""
    count = 0
    for item in data:
        field_value = item.get(field_name, "")
        count += field_value.lower().count(search_string.lower())  # Case-insensitive count
    return count

def main():
    if len(sys.argv) != 4:
        logging.error("Usage: python count_string_in_api_response.py <api_url> <field_name> <search_string>")
        sys.exit(1)

    api_url = sys.argv[1]
    field_name = sys.argv[2]
    search_string = sys.argv[3]

    logging.info("Fetching data from API...")
    data = fetch_data_from_api(api_url)

    logging.info(f"Counting occurrences of '{search_string}' in field '{field_name}'...")
    count = count_occurrences_in_data(data, field_name, search_string)

    logging.info(f"The string '{search_string}' appears {count} times in the '{field_name}' field.")

if __name__ == "__main__":
    main()

