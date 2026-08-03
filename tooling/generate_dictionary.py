import json
import pathlib
import re


# SOURCE: bir markdown tablosu formatında ("| n | [kelime](...) | ...") ham kelime listesi.
SOURCE = pathlib.Path(r"source_wordlist.txt")
DEST = pathlib.Path(__file__).resolve().parent.parent / "assets" / "words" / "turkish_dictionary.json"

PATTERN = re.compile(r"^\|\s*\d+\s*\|\s*\[([^\]]+)\]\(")
VALID = re.compile(r"^[abcçdefgğhıijklmnoöprsştuüvyz]+$")
STOP = {
    "için",
    "gibi",
    "kadar",
    "sadece",
    "çünkü",
    "fakat",
    "ancak",
    "veya",
    "ile",
    "değil",
    "evet",
    "hayır",
    "şey",
    "biri",
    "bana",
    "sana",
    "beni",
    "seni",
    "benim",
    "senin",
    "onun",
    "bunu",
    "onu",
    "şunu",
    "böyle",
    "şöyle",
    "daha",
    "bile",
    "yine",
    "hala",
    "artık",
    "sonra",
    "önce",
    "zaten",
    "lütfen",
    "tamam",
    "belki",
    "nasıl",
    "neden",
    "niye",
    "kimse",
}


def normalize(word: str) -> str:
    return word.strip().lower()


def main() -> None:
    lines = SOURCE.read_text(encoding="utf-8", errors="ignore").splitlines()
    words: list[str] = []

    for line in lines:
        match = PATTERN.match(line)
        if not match:
            continue
        word = normalize(match.group(1))
        if "'" in word or "-" in word or " " in word:
            continue
        if not VALID.match(word):
            continue
        if len(word) < 3 or len(word) > 9:
            continue
        if word in STOP:
            continue
        words.append(word)

    seen: set[str] = set()
    unique: list[str] = []
    for word in words:
        if word in seen:
            continue
        seen.add(word)
        unique.append(word)

    out = {"words": unique[:2600]}
    DEST.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"written {len(out['words'])} words to {DEST}")


if __name__ == "__main__":
    main()
