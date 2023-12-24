import json
from pathlib import Path

import typer

app = typer.Typer()


@app.command()
def hello():
    print("Hello World")


@app.command()
def sortjson(path: Path):
    sorted_json = ""
    with open(path, mode="r") as file:
        contents = file.read()
        json_data = json.loads(contents)
        sorted_json = json.dumps(json_data, indent=4, sort_keys=True)
    with open(path, mode="w") as file:
        file.write(sorted_json)


def main():
    app()


if __name__ == "__main__":
    main()
