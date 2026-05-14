# Scripted-playback rigor level

Status: scaffolding only (P1.1). Awaits game binary (P2-P4).

Intent: frame-accurate test scenarios with exact expected output
at specific frames. Highest rigor; used for regression detection
on subtle changes.

Pattern: per-scenario script defines (input sequence) and
(expected state at each frame). The harness fails on any
deviation.

Implementation will land during P4 (integration + content).
