import requests
import json

# Function to get wind speed data from StormGlass API
def get_wind_speed_data(lat, lng):
    url = f"https://api.stormglass.io/v2/weather/point?lat={lat}&lng={lng}&params=windSpeed"
    headers = {
        "Authorization": "86703978-c366-11ef-9159-0242ac130003-867039d2-c366-11ef-9159-0242ac130003"  # Your API key
    }
    
    # Send request to StormGlass API
    response = requests.get(url, headers=headers)
    
    # Check for errors in the response
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}")
        return None

# Function to parse wind speed data
def parse_wind_speed_data(data):
    if not data or "hours" not in data:
        print("No data available to parse.")
        return []
    
    wind_speeds = []
    for hour_data in data['hours']:
        time = hour_data['time']
        wind_speed = hour_data['windSpeed']
        # Extract wind speed from different sources (noaa, sg, smhi)
        noaa_speed = wind_speed.get('noaa', 'N/A')
        sg_speed = wind_speed.get('sg', 'N/A')
        smhi_speed = wind_speed.get('smhi', 'N/A')
        
        # Print or save the extracted data
        wind_speeds.append({
            'time': time,
            'noaa': noaa_speed,
            'sg': sg_speed,
            'smhi': smhi_speed
        })
    
    return wind_speeds

# Function to display or use the wind speed data
def display_wind_speed_data(wind_speeds):
    if not wind_speeds:
        print("No wind speed data to display.")
        return
    
    for wind_data in wind_speeds:
        print(f"Time: {wind_data['time']}")
        print(f"NOAA Wind Speed: {wind_data['noaa']} m/s")
        print(f"SG Wind Speed: {wind_data['sg']} m/s")
        print(f"SMHI Wind Speed: {wind_data['smhi']} m/s")
        print("-" * 30)

# Example coordinates for location (latitude, longitude)
latitude = 58.7984
longitude = 17.8081

# Fetch and parse the wind speed data
data = get_wind_speed_data(latitude, longitude)
if data:
    wind_speeds = parse_wind_speed_data(data)
    display_wind_speed_data(wind_speeds)
