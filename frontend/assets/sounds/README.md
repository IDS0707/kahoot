# Sound effects

Drop short `.mp3` files here with these exact names. The app will pick them
up automatically — until then `SoundFx` falls back to a platform `SystemSound`
click/alert (so the UX still feels responsive).

| File              | Where it plays                               | Length     |
|-------------------|----------------------------------------------|------------|
| `click.mp3`       | Generic button taps                          | < 80 ms    |
| `hover.mp3`       | Web hover on answer cards                    | < 60 ms    |
| `submit.mp3`      | Locking in an answer                         | 100–200 ms |
| `correct.mp3`     | Correct answer reveal                        | 300–600 ms |
| `wrong.mp3`       | Wrong answer reveal                          | 300–500 ms |
| `tick.mp3`        | Each of the final 5 timer seconds            | < 80 ms    |
| `buzzer.mp3`      | Time runs out                                | 200–400 ms |
| `reveal.mp3`      | Question card slide-in                       | 200–400 ms |
| `combo.mp3`       | Streak ≥ 3 combo trigger                     | 300–600 ms |
| `rank_up.mp3`     | Player moves up a rank                       | 200–400 ms |
| `victory.mp3`     | Game over / podium reveal                    | 1–2 s      |
| `join.mp3`        | New player joins lobby                       | < 200 ms   |

After adding files, register them in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/sounds/
```

(The folder is already wired in pubspec — just rebuild after dropping files in.)

Recommended royalty-free sources:
- https://pixabay.com/sound-effects/
- https://freesound.org/
