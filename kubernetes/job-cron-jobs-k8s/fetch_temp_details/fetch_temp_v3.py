import os
import requests
import json

# Function to get wind speed data from StormGlass API
def get_wind_speed_data(lat, lng):
    # Fetch API key from environment variable
    api_key = os.getenv("STORMGLASS_API_KEY")
    
    if not api_key:
        print("Error: API key not found in environment variables.")
        return None

    url = f"https://api.stormglass.io/v2/weather/point?lat={lat}&lng={lng}&params=windSpeed"
    headers = {
        "Authorization": api_key  # Use the API key from the environment variable
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
        
        # Append the data to wind_speeds list
        wind_speeds.append({
            'time': time,
            'noaa': noaa_speed,
            'sg': sg_speed,
            'smhi': smhi_speed
        })
    
    return wind_speeds

# Function to find the maximum wind speed
def find_max_wind_speed(wind_speeds):
    max_wind_speed = {
        'noaa': 0,
        'sg': 0,
        'smhi': 0,
        'time': ""
    }
    
    # Iterate through the data to find the maximum wind speed for each source
    for wind_data in wind_speeds:
        for source in ['noaa', 'sg', 'smhi']:
            wind_value = wind_data[source]
            if wind_value != 'N/A' and wind_value > max_wind_speed[source]:
                max_wind_speed[source] = wind_value
                max_wind_speed['time'] = wind_data['time']
    
    return max_wind_speed

# Function to display wind speed data
def display_wind_speed_data(wind_speeds):
    if not wind_speeds:
        print("No wind speed data to display.")
        return
    
    print("Wind Speed Data:")
    for wind_data in wind_speeds:
        print(f"Time: {wind_data['time']}")
        print(f"NOAA Wind Speed: {wind_data['noaa']} m/s")
        print(f"SG Wind Speed: {wind_data['sg']} m/s")
        print(f"SMHI Wind Speed: {wind_data['smhi']} m/s")
        print("-" * 30)

# Function to display maximum wind speed
def display_max_wind_speed(max_wind_speed):
    if max_wind_speed['noaa'] == 0 and max_wind_speed['sg'] == 0 and max_wind_speed['smhi'] == 0:
        print("No valid wind speed data to calculate maximum.")
        return
    
    print("\nMaximum Wind Speed Data:")
    print(f"Time: {max_wind_speed['time']}")
    print(f"Maximum NOAA Wind Speed: {max_wind_speed['noaa']} m/s")
    print(f"Maximum SG Wind Speed: {max_wind_speed['sg']} m/s")
    print(f"Maximum SMHI Wind Speed: {max_wind_speed['smhi']} m/s")
    print("-" * 30)

# Fetch latitude and longitude from environment variables
latitude = float(os.getenv("LATITUDE"))
longitude = float(os.getenv("LONGITUDE"))

# Fetch and parse the wind speed data
data = get_wind_speed_data(latitude, longitude)
if data:
    wind_speeds = parse_wind_speed_data(data)
    display_wind_speed_data(wind_speeds)
    
    # Find the maximum wind speed
    max_wind_speed = find_max_wind_speed(wind_speeds)
    display_max_wind_speed(max_wind_speed)

