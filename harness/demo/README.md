# Demo-loop rigor level

Status: scaffolding only (P1.1). Awaits game binary (P2-P4).

Intent: automated playback through known game paths. Validates
that the engine progresses correctly without hanging or crashing
across longer-duration runs.

Pattern: a scripted input sequence drives the game through a
pre-recorded path; the harness verifies expected PC visits,
memory state checkpoints, and screen contents at key frames.

Implementation will land during P4 (integration + content).
