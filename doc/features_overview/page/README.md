# Inventory page

Builds the published overview artifact from `../inventory.yaml`.

    python3 doc/features_overview/page/build.py

Writes `ramses-inventory.html` next to `build.py`; publish that file to the
existing artifact (do not create a new one, the review flags live in its
database):

    https://claude.ai/code/artifact/7a60996f-061d-413d-8c52-6d6bd650195b

- `head.part` / `tail.part`  the page either side of the embedded data
- `questions.json`           the review-question register; questions persist
                             here until answered, they are never dropped
- flags and notes left on the page are stored in the artifact's own database
  (`review` collection), not in this repo -- read them before assuming a
  question is unanswered
