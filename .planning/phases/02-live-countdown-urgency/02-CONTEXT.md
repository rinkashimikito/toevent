# Phase 2: Live Countdown + Urgency - Context

**Gathered:** 2026-01-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Real-time countdown display in the menu bar with color-coded urgency indicators as events approach. Timer updates dynamically, visual feedback escalates based on time remaining. Configuration options for timer format and battery modes are out of scope (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Timer Format
- Hybrid format as default: simple display when far out, precise when close
  - Example: "2h 15m" → "59m" → "5m 23s" (seconds appear based on proximity)
- Show "Now" for 1 minute after event starts, then switch to next event
- Default format is fixed in Phase 2 (configurability comes in Phase 4)

### Color Transitions
- macOS system colors for urgency: yellow (1h), orange (30m), red (15m)
- System default color (white/black) for events >1 hour away
- Brief fade transition (0.3-0.5s) when crossing thresholds, not instant
- Text with subtle icon tint (text changes boldly, icon gets subtle color tint)

### Icon Behavior
- Calendar icon in menu bar
- Icon style changes with urgency: outline when distant, filled when urgent
- Icon left, text right - standard menu bar pattern: [📅 5m 23s]

### Update Frequency
- Adaptive with seconds threshold:
  - 1-second updates only when seconds precision is shown
  - 1-minute updates when showing minutes/hours only
- Pause updates when screen locked, resume when unlocked
- Optimize for smoothness by default (frequent updates for good UX)
- Phase 2 establishes default behavior (battery-saving options in Phase 4)

### Claude's Discretion
- Exact threshold for when seconds precision appears in hybrid format
- Icon transition threshold (when outline becomes filled)
- Exact fade animation duration within 0.3-0.5s range
- Implementation details of pause/resume logic

</decisions>

<specifics>
## Specific Ideas

No specific product references provided - open to standard macOS menu bar approaches.

</specifics>

<deferred>
## Deferred Ideas

- Timer format configurability (countdown vs absolute vs natural language) - Phase 4 (CUST-02, CUST-03)
- Battery-saving mode toggle for reduced update frequency - Phase 4 (SYST-05)
- Customizable color thresholds - Phase 4 (CUST-01)

</deferred>

---

*Phase: 02-live-countdown-urgency*
*Context gathered: 2026-01-24*
