import os
import tweepy
import feedparser
import time
import logging
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Twitter API credentials
consumer_key = os.environ.get('TWITTER_CONSUMER_KEY')
consumer_secret = os.environ.get('TWITTER_CONSUMER_SECRET')
access_token = os.environ.get('TWITTER_ACCESS_TOKEN')
access_token_secret = os.environ.get('TWITTER_ACCESS_TOKEN_SECRET')

# Reading post delay duration from environment variables
post_delay_minutes = int(os.environ.get('POST_DELAY_MINUTES', '3'))

# RSS feed URL and other configurations
rss_url = 'https://news.aqora.io/rss'

# Initialize Twitter API client
client = tweepy.Client(
    consumer_key=consumer_key, consumer_secret=consumer_secret,
    access_token=access_token, access_token_secret=access_token_secret
)

def post_tweet_and_reply(entry):
    try:
        # Post the tweet with the article link
        tweet = client.create_tweet(text=f"{entry.title} {entry.link}")
        logging.info(f"Tweet posted for: {entry.title}")

        # Post a reply with the discussion link
        reply_text = f"Feel free to discuss here, or join on Quantum News: {entry.comments}"
        client.create_tweet(text=reply_text, in_reply_to_tweet_id=tweet.data['id'])
    except Exception as e:
        logging.error(f"Error posting tweet: {e}")

def main():
    threshold_time = datetime.now() - timedelta(minutes=post_delay_minutes)
    feed = feedparser.parse(rss_url)

    for entry in reversed(feed.entries):
        entry_time = datetime(*entry.published_parsed[:6])
        if entry_time >= threshold_time:
            post_tweet_and_reply(entry)
            time.sleep(10)  # Sleep to avoid hitting rate limits

if __name__ == "__main__":
    main()
