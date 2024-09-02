#!/usr/bin/env python3

import json
import re
import requests
import time
from lxml import objectify
from lxml.html import fromstring

def search_comments(comment):
  return re.findall(r'\[url(?:\]|=)(.*?)(?:\]|\[\/url\])', str(comment))

def get_games(url):

  while True:
      r = requests.get(url)
      if r.status_code == 202:
        # Wait and try again later.
        time.sleep(3)
      else:
        break
    # Parse the xml into a python object.
    # We need to replace the 'encoding' declaration specified in the xml because lxml hates it.
  return objectify.fromstring(r.text.replace('encoding="utf-8" ', ''))


def lambda_handler(event, context):
  
  username = event['queryStringParameters']['username']

  usergames_url = "https://boardgamegeek.com/xmlapi/collection/%s?own=1" % username
  mygames = get_games(usergames_url)

  # TODO: verify we have a good result in mygames

  game_ids = []

  for game in mygames.item:
    game_ids.append(game.attrib['objectid'])

  geeklist_url = "http://boardgamegeek.com/xmlapi/geeklist/186909?comments=1"
  printable_games = get_games(geeklist_url)

  matching_games = [ game_list for game_list in printable_games.item if game_list.attrib['objectid'] in game_ids ]

  match_count = len(matching_games)

  matching_games.sort(key=lambda x: x.attrib['objectname'], reverse=False)

  results = {
    'username': username,
    'match_count': match_count,
    'games': []
  }

  final_list = []
  for game in matching_games:
    urls = []

    game_entry = {}
    game_entry['url'] = "https://boardgamegeek.com/geeklist/186909/item/%s#item%s" % (game.attrib['id'], game.attrib['id'])
    game_entry['name'] = game.attrib['objectname']
    game_entry['postdate'] = game.attrib['postdate']
    game_entry['entries'] = []

    comments = game.getchildren()
    for comment in comments:

      urls.extend(search_comments(comment))

    game_entry['entries'] = list(set(urls))
    final_list.append(game_entry)

  results['games'] = final_list
  return json.dumps(results, indent=2)

if __name__ == "__main__":
  event = {
    "queryStringParameters": {
      "username": "tofarley"
    }
  }

  output = lambda_handler(event, "context")
  print(output)