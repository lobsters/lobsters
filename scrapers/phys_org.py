import requests
from bs4 import BeautifulSoup

url = 'https://phys.org/tags/quantum+computing/sort/date/1d/'
headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-DE,en;q=0.9,ar-BH;q=0.8,ar;q=0.7,de-DE;q=0.6,de;q=0.5,en-US;q=0.4',
    # Add other headers as necessary
}

def scrape_phys_org():
    response = requests.get(url, headers=headers)
    
    # Check if the request was successful
    if response.status_code != 200:
        print("Failed to retrieve the website")
        return []

    # Parse the HTML content of the page
    soup = BeautifulSoup(response.text, 'html.parser')

    # List to store the extracted links
    links = []

    # Find the sorted-news-list and process each article
    news_list = soup.find('div', class_='sorted-news-list')
    if news_list:
        sorted_articles = news_list.find_all('article', class_='sorted-article')
        for article in sorted_articles:
            title_element = article.find('h3')
            link_element = title_element.find('a') if title_element else None
            if link_element:
                links.append(link_element.get('href'))

    # Return the list of unique links
    unique_links = list(set(links))
    return unique_links