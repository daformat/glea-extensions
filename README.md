# Glea Clipper

Browser extensions that collect from Chrome, Edge, Arc, Brave, Firefox and Safari into [Glea](https://github.com/daformat/glea)'s journal and notes. They work like Obsidian's Web Clipper: the extension turns the page into Markdown and hands it to the app through a URL, and Glea writes the file.

## Install

- **Firefox:** [Glea Clipper on Firefox Add-ons](https://addons.mozilla.org/addon/glea-clipper/).
- **Safari:** comes with Glea: once Glea has run, enable *Glea Clipper* in *Safari ▸ Settings ▸ Extensions*.
- **Chrome / Edge / Arc / Brave:** build it and load it unpacked (below).

Outside Safari, Glea may not be on the Mac yet: installing the extension opens a welcome page with a link to download it, and the popup offers the link too when Glea doesn't open after a capture.

## What it collects

- **Point and shoot**, as in Glea: hold **⌥ Option** on a page and a spotlight morphs onto the block under the pointer. **Click** to collect it, or **drag** to collect an area as a screenshot. With text selected, ⌥ collects the selection at once. Hold ⌥⌘ to collect posts and videos as text. The capture goes where the popup's *Into* says (a new note is named after the page), and opens Glea if *Open Glea afterwards* is on. ⌥ does nothing while you're typing in a field, so it still types characters there.
- **Toolbar popup** (⌥⇧G): the *selection*, the page's main content as an *article*, or just its *link*. It goes into *Today*'s journal, a *new note* (named after the page by default) or *Choose in Glea*, which opens Glea's capture picker. *Open Glea afterwards* shows where it went. Otherwise Glea hands focus back to the browser. Both are kept as you set them, for everything below too.
- **Context menu:** *Collect Selection / Image / Link / Page to Glea* and *Clip Article to Glea*. These follow the popup's *Into* and *Open Glea afterwards*.
- **Shortcut** ⌥⇧S: collects the selection, or the page's link when nothing is selected.

Captures look like Glea's own point-and-shoot captures: a quote with a link back to the page, an image credited below it, or `- [Title](url)` for a link. Images are downloaded into `assets/`. An article becomes the note's body under a link to its source.

## How it reaches Glea

The extension opens a `glea://capture` URL by navigating the current tab to it. The browser hands it to Glea (and asks the first time) and the page stays where it is. If Glea isn't running, macOS launches it.

```
glea://capture?kind=selection&url=…&title=…&markdown=…&to=journal
```

| Parameter | |
| --- | --- |
| `kind` | `selection`, `article`, `image`, `element` or `page` |
| `url`, `title` | the source page (only `http`/`https` sources are accepted) |
| `markdown` | the content (not needed for `page`) |
| `clipboard=1` | the content is on the clipboard instead: used above ~1.5 MB, where browsers drop URLs |
| `text` | plain-text preview for the picker |
| `to` | `journal` (default), `note` with `note=<name>` (created if missing), or `ask` |
| `open=1` | show the note afterwards |

The app side is `glea/src/app/ExternalCapture.swift`. Any web page can open a `glea://` URL too (the browser asks first), so Glea only ever appends captures, never replaces or deletes anything.

## Layout

```
src/                 the extension (Manifest V3), shared by every browser
  manifest.json        Chrome's manifest; the build adapts it for Firefox and Safari
  background.js        context menu, shortcut, screenshots, sends glea:// URLs
  pns-driver.js        point and shoot: the ⌥ key and the link to the background
  vendor/glea-content-script.js   Glea's own point-and-shoot script, unchanged (built in Glea with @daformat/point-and-shoot)
  capture.js           injected on demand: selection / article / image → Markdown
  popup.html/css/js    toolbar popup
  welcome.html/css     opened on install (not in Safari): Glea is needed, and where to get it
scripts/build.sh     builds dist/ and the Safari Xcode project
```

Point and shoot runs Glea's own `content-script.js`, which Glea builds from its `src/pns/glea-pns.ts` and the [@daformat/point-and-shoot](https://github.com/daformat/point-and-shoot) library. `pns-driver.js` plays the app's part around it: it turns the mode on while ⌥ is held, and passes captures to the background script through `__gleaNative.post()`. The background script sends them to Glea, then answers so the page can let go of the shot. For a dragged area, it takes the screenshot with `tabs.captureVisibleTab`, crops it and sends it as a data URL, which Glea saves into `assets/`. `scripts/build.sh` copies the latest `content-script.js` from `../glea` when the checkout is there. `capture.js` (popup and context menu) has its own copy of the HTML → Markdown converter, so keep that in sync by hand.

Point and shoot has to be in every page before you hold ⌥, so the extension asks for access to all sites (`<all_urls>`). The page script only reads the page when you collect. Without that permission, the popup and context menu still work through `activeTab`.

## Build and install

```bash
scripts/build.sh
```

- **Chrome / Edge / Arc / Brave:** open `chrome://extensions`, turn on *Developer mode*, then *Load unpacked* and pick `dist/chrome`. `dist/glea-clipper-chrome-<version>.zip` is the Web Store upload.
- **Firefox:** to try a build, open `about:debugging#/runtime/this-firefox` and choose *Load Temporary Add-on…*, then pick `dist/firefox/manifest.json`. The `.zip` is the addons.mozilla.org upload.
- **Safari:** Glea Clipper for Safari ships inside Glea (`Glea.app/Contents/PlugIns/Glea Clipper.appex`): once Glea has run, enable *Glea Clipper* in *Safari ▸ Settings ▸ Extensions*. Glea's repo bundles `dist/safari` with `scripts/sync_clipper.sh` (which runs `scripts/build.sh safari-files`); run it after changing the extension, and the next Glea release carries it. For a stand-alone app instead, `scripts/build.sh safari` generates `safari/Glea Clipper/Glea Clipper.xcodeproj` with Xcode's `safari-web-extension-converter`. Unsigned builds need *Develop ▸ Developer Settings ▸ Allow unsigned extensions*.

Glea must be a build that registers the `glea` URL scheme (with `ExternalCapture.swift`). Launch it once so macOS knows about it.

## Known limitations

- Chrome asks *Open Glea?* for each site until you tick *Always allow*.
- Article extraction is a heuristic: the densest block of paragraphs, widened to the `<article>` around it, minus navigation, share bars, comments and the like. It isn't Readability or Defuddle, so some layouts will need the selection instead.
- Pages the browser doesn't let extensions script (its stores, settings pages, built-in PDF viewer) can only be collected as a link.

## License

Glea Clipper is source available under the [PolyForm Strict License 1.0.0](LICENSE.md), like [Glea](https://github.com/daformat/glea): you may read, build and use it for noncommercial purposes, but not change or redistribute it. For commercial use, contact the author.
