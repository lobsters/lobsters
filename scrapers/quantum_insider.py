import requests
from bs4 import BeautifulSoup
from datetime import datetime

url = 'https://thequantuminsider.com/category/daily/'
headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-DE,en;q=0.9,ar-BH;q=0.8,ar;q=0.7,de-DE;q=0.6,de;q=0.5,en-US;q=0.4',
    # Add other headers as necessary
}

def scrape_quantum_insider():
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"Failed to retrieve the website, status code: {response.status_code}")
        return []

    soup = BeautifulSoup(response.text, 'html.parser')
    today = datetime.now().strftime("%B %d, %Y")
    links = []

    date_elements = soup.find_all('span', class_='elementor-post-date')
    for date_element in date_elements:
        date_text = date_element.get_text().strip()
        if date_text == today:
            article = date_element.find_parent('article')
            if article:
                link = article.find('a')
                if link:
                    links.append(link.get('href'))

    # Remove duplicates by converting to a set and back to a list
    unique_links = list(set(links))

    return unique_links