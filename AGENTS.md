# Agent instructions — leon-bus-live

## Repository-specific deterministic quality contract (2026-10-26)

**Project:** Swift iOS 26 app displaying León public transit.

**Engineering requirements:** Preserve offline/mock schedule data behavior, MapKit locations, privacy controls and Swift strict concurrency. Build on a runner with the iOS 26 SDK.

**Verification commands:** xcodebuild -project LeonBusLive.xcodeproj -scheme LeonBusLive -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build.

Do not assert any test passed without actual output. Add tests for changed behavior, malformed input and regressions. Never remove/weaken tests, reduce thresholds, suppress errors, or change CI merely to produce a green result. Require review of `QUALITY_GATES.md`, workflow and contract edits. Make the `quality` check required via branch protection. Native tooling blockers must be reported explicitly; preserve existing agent instructions.
