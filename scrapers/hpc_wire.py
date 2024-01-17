import requests
from bs4 import BeautifulSoup
from datetime import datetime

url = 'https://www.hpcwire.com/qcwire/'
headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-DE,en;q=0.9,ar-BH;q=0.8,ar;q=0.7,de-DE;q=0.6,de;q=0.5,en-US;q=0.4',
    # Add other headers as necessary
}

def scrape_hpcwire():
    response = requests.get(url, headers=headers)
    
    # Check if the request was successful
    if response.status_code != 200:
        print("Failed to retrieve the website")
        return []

    # Parse the HTML content of the page
    soup = BeautifulSoup(response.text, 'html.parser')

    # Get the current date
    today = datetime.now().strftime("%B %d, %Y").strip()

    # List to store the extracted links
    links = []

    # Find all article entries
    entries = soup.find_all('div', class_='row entry')
    for entry in entries:
        date_element = entry.find('p', class_='date text-right')
        if date_element and date_element.get_text().strip() == today:
            link_element = entry.find('a')
            if link_element and link_element.get('href'):
                links.append(link_element.get('href'))

    # Find and process the "Off the Wire" section
    date_sections = soup.find_all('h4', class_='sidebar-title')
    for date_section in date_sections:
        date_text = date_section.get_text().strip()
        if date_text == today:
            ul = date_section.find_next_sibling('ul', class_='triangle')
            if ul:
                for li in ul.find_all('li'):
                    link_element = li.find('a')
                    if link_element and link_element.get('href'):
                        links.append(link_element.get('href'))

    # Return the list of unique links
    unique_links = list(set(links))

    return unique_links