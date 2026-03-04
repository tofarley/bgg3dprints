# BGG 3D Prints

A small Flask web app that cross-references a BoardGameGeek user's game collection against the community-maintained [3D Prints for Board Games](https://boardgamegeek.com/geeklist/186909) GeekList, showing which of their games have fan-designed, 3D-printable components available.

## How it works

1. The user enters a BGG username.
2. The app fetches that user's owned game collection via the BGG XML API.
3. It fetches the *3D Prints for Board Games* GeekList (ID: 186909), including all comments.
4. It cross-references the two lists and displays matching games, along with any relevant links extracted from the GeekList comments.

Links are cleaned up automatically — image files and malformed URLs from BGG's community markup are filtered out.

## Setup

```bash
pip install -r requirements.txt
flask run
```

The app runs on `http://127.0.0.1:5000` by default. For production, use a WSGI server like Gunicorn:

```bash
gunicorn app:app
```

## BGG API token

The BGG XML API requires an authorization token for certain requests. You can request one here: https://boardgamegeek.com/using_the_xml_api#toc2

Once you have a token, pass it via the `BGG_TOKEN` environment variable:

```bash
BGG_TOKEN=your-token-here flask run
```

If `BGG_TOKEN` is not set, the app falls back to a hardcoded default token in `app.py`. For any kind of shared or production deployment, set the environment variable rather than leaving the token in source code.
