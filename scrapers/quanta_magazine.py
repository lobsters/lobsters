import requests
from datetime import datetime
import json

def scrape_quanta_magazine():
    url = 'https://www.quantamagazine.org/graphql'
    headers = {
        'Content-Type': 'application/json',
        'Referer': 'https://www.quantamagazine.org/search?q[s]=quantum&q[sort]=newest'
    }
    query = {
        "operationName": "getSearch",
        "variables": {
            "args": "?q[s]=quantum&q[sort]=newest&page=1"
        },
        "query": """
        query getSearch($args: String) {
            response: getSearch(args: $args) {
                data {
                    ... on Post {
                        title
                        link
                        date
                    }
                }
            }
        }
        """
    }

    response = requests.post(url, headers=headers, data=json.dumps(query))

    if response.status_code != 200:
        print("Failed to retrieve the website")
        return []

    data = response.json()
    today = datetime.now().strftime("%Y-%m-%d")
    links = []

    for item in data['data']['response']['data']:
        if 'date' in item and item['date'].startswith(today):
            if 'link' in item:
                links.append(item['link'])

    return links