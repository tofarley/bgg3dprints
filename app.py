import os
import re
import time
import unicodedata
from urllib.parse import urlparse

import requests
from flask import Flask, render_template, request
from lxml import objectify
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

BGG_TOKEN = os.environ.get("BGG_TOKEN", "not-a-real-token")
GEEKLIST_ID = "186909"


def remove_accents(input_str):
    nfkd_form = unicodedata.normalize("NFKD", input_str)
    return nfkd_form.encode("ASCII", "ignore").decode("utf-8")


def fetch_xml(url, headers):
    """Fetch a BGG API URL, retrying on 202 (queued) responses."""
    while True:
        r = requests.get(url, headers=headers)
        if r.status_code == 202:
            time.sleep(5)
        else:
            r.raise_for_status()
            return r


def get_user_game_ids(username, headers):
    r = fetch_xml(
        f"https://boardgamegeek.com/xmlapi/collection/{username}?own=1",
        headers,
    )
    collection = objectify.fromstring(r.text.replace('encoding="utf-8" ', ""))
    game_ids = [item.attrib["objectid"] for item in collection.item]
    total = collection.countchildren()
    return game_ids, total


def get_printable_games(headers):
    r = fetch_xml(
        f"https://boardgamegeek.com/xmlapi/geeklist/{GEEKLIST_ID}?comments=1",
        headers,
    )
    return objectify.fromstring(r.text.replace('encoding="utf-8" ', ""))


def extract_urls(game):
    urls = []
    for comment in game.getchildren():
        urls += re.findall(
            r"http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\), ]|(?:%[0-9a-fA-F][0-9a-fA-F]))+",
            str(comment),
        )
    IMAGE_EXTENSIONS = (".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".svg")

    # Truncate at any '[' (strips BBCode tags like [/img, [/url], [/q, [ImageID=...])
    # then drop bare image URLs
    cleaned = set()
    for url in urls:
        url = re.split(r"[\[\]()\s]", url)[0]
        if url and not urlparse(url).path.lower().rstrip("/").endswith(IMAGE_EXTENSIONS):
            cleaned.add(url)
    return sorted(cleaned)


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")


@app.route("/results", methods=["POST"])
def results():
    username = request.form.get("username", "").strip()
    if not username:
        return render_template("index.html", error="Please enter a BGG username.")

    headers = {"Authorization": f"Bearer {BGG_TOKEN}"}

    try:
        game_ids, total_games = get_user_game_ids(username, headers)
    except Exception:
        return render_template(
            "index.html",
            error=f'User "{username}" was not found or BGG is unavailable.',
        )

    try:
        printable_games = get_printable_games(headers)
    except Exception:
        return render_template(
            "index.html", error="Could not fetch the 3D Prints GeekList from BGG."
        )

    matching = [
        g for g in printable_games.item if g.attrib["objectid"] in game_ids
    ]
    matching.sort(key=lambda g: g.attrib["objectname"])

    games = []
    for game in matching:
        games.append(
            {
                "name": remove_accents(game.attrib["objectname"]),
                "id": game.attrib["id"],
                "postdate": game.attrib["postdate"],
                "urls": extract_urls(game),
            }
        )

    return render_template(
        "results.html",
        username=username,
        total_games=total_games,
        geeklist_id=GEEKLIST_ID,
        games=games,
    )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
