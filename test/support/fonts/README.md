# test/support/fonts

Real fonts for tests that check text metrics. The default `FlutterTest`
font draws every glyph as a full 1 em square (about twice Roboto's average
advance), so it cannot answer "does this string fit in N lines".

| File | Source | License |
|------|--------|---------|
| `Roboto-Regular.ttf` | Roboto 2.137 (2017), Google | Apache License 2.0 (embedded in the font's name table; http://www.apache.org/licenses/LICENSE-2.0) |

Roboto is the Material default family on Android, so `Typography` already
asks for `Roboto`: loading it with `FontLoader('Roboto')` makes default
text in that test file use real metrics. Load it only in the test that
needs it, after any layout test that relies on the `FlutterTest` font.
Test-only: never bundled into the app.
