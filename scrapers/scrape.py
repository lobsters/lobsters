import os
import sys
from quantum_news_poster import QuantumNewsPoster

from quantum_insider import scrape_quantum_insider
from hpc_wire import scrape_hpcwire
from quanta_magazine import scrape_quanta_magazine

def main():
    if len(sys.argv) < 5:
        print("Usage: python3 scrape.py [scraper_names/all] [username] [password] [tag]")
        return

    scraper_names_input = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    tag = sys.argv[4]

    aqora_host = os.getenv('AQORA_HOST', 'https://app-staging.aqora-internal.io')
    news_host = os.getenv('NEWS_HOST', 'https://news.aqora-internal.io')

    poster = QuantumNewsPoster(aqora_host, news_host)
    poster.login_user(username, password)

    # List of all scrapers and their corresponding functions
    all_scrapers = {
        "quantum-insider": scrape_quantum_insider,
        "hpc-wire": scrape_hpcwire,
        "quanta-magazine": scrape_quanta_magazine
        # Add more scrapers here as needed
    }

    scraper_names = scraper_names_input.split(',') if scraper_names_input != 'all' else all_scrapers.keys()

    for scraper_name in scraper_names:
        scraper_function = all_scrapers.get(scraper_name)
        if scraper_function:
            links = scraper_function()
            for link in links:
                poster.post_story(link, tag)
        else:
            print(f"Unknown scraper: {scraper_name}")

if __name__ == "__main__":
    main()
