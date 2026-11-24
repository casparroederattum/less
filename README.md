# Less

A Mac app that looks at the technology in your life and tells you, what you could
turn down or let go of, and what to do instead. Everything stays on your Mac.

> **This is more a thought I had than an app you can really use.** Each app we download is meant to
> make life a little better, yet we are bad at knowing what actually makes us happier. Less is how I
> worked through that idea: life can be much, much better if you delete stuff from it. It runs on
> my Mac, but it is a sketch, not a finished product, but if you want to read my thoughts on this, go for it.

## What you need

- A Mac with Apple Silicon and macOS 14 (Sonoma) or newer.
- Apple's Command Line Tools (the Swift compiler). Check with `swift --version` in Terminal.
  If that fails, run `xcode-select --install` and follow the dialog. Full Xcode is not needed.

## Build and run

In Terminal:

```bash
git clone https://github.com/casparroederattum/less.git
cd less
chmod +x build.sh        # only the first time
./build.sh --run
```

This compiles the app, puts it together as `build/Less.app`, signs it for this Mac only, and opens it.
Everything the build prints is also saved in `build.log`.

To try the screens with made-up data and no permissions at all: `./build.sh --demo`.

## Permissions

Each one is optional. Less asks one at a time and works with whatever you allow.

| What | How it's granted |
|---|---|
| Your apps | Nothing to grant. |
| Time spent in apps, Safari websites | **Full Disk Access**: System Settings → Privacy & Security → Full Disk Access → switch on Less (or click + and pick `build/Less.app`). Then quit and reopen Less. |
| Chrome websites | Nothing to grant. |
| What starts on its own | macOS asks once whether Less may use System Events. |
| Notifications | Nothing to grant. |
| Bluetooth devices | macOS asks once. |
| Devices at home | macOS asks once about Local Network. |

Take any of them back in the same places. In the app, "What Less knows" shows exactly what was read
and has a button that deletes the one data file:
`~/Library/Application Support/Less/less.json`.

**After a rebuild**, macOS sees a new app and may forget Full Disk Access. Switch Less off and on
again in that list (or remove it with − and add it again).

### Honest limits

- **Screen Time on a Mac has no public interface.** Less reads the older `knowledgeC.db` database.
  Recent macOS versions write some of this elsewhere, in a private format; if so, the card says that
  app time was left out, and the scan works on everything else.
- **Notification settings** come from an undocumented preferences file. Less only reads whether an
  app can pop up on screen (banners or alerts).
- **Subscriptions, your phone and things you wear** can't be seen from a Mac. Add them with one tap
  under "What this Mac can't see".

## Optional: nicer wording with Ollama

If [Ollama](https://ollama.com) is running on this Mac, Less asks a small local model to reword the
two sentences on each card. The verdicts don't change; the rules decide those. Every answer is checked
for length and wording, and anything that fails falls back to the built-in sentence.

```bash
brew install ollama        # or download the app from ollama.com
ollama pull llama3.2:3b
ollama serve               # leave running, then scan again in Less
```

Less only talks to `127.0.0.1` (this Mac). Without Ollama, Less works exactly the same.

## How it's built

Swift and SwiftUI, no third-party code, one file per job:

```
Sources/Less/
  App/       LessApp (window), AppModel (all state and the scan flow)
  Model/     DataSource (the seven permission cards), Item, Store (the one JSON file)
  Rules/     Categories (lookup tables), VerdictRules (the points), Phrases (built-in sentences),
             Words (banned words and the 20-word limit)
  Scanners/  one file per source, plus Shell and SQLiteCopy helpers and a StubScanner for --demo
  Local/     Permissions (System Settings links, Bluetooth prompt), LocalWords (optional Ollama)
  Views/     Welcome, Permission, Scanning, Results, WhyLess, Knows, Theme
```

The verdict rules are in `Rules/VerdictRules.swift`, with a worked example at the top.

## Later, not now

- A local home camera, looked at on a home server.
- An iPhone companion app (Screen Time on iOS through Apple's Family Controls / DeviceActivity APIs).
- Payments, accounts, sync.
- A version for employers who want healthier teams, and paid human coaching.
