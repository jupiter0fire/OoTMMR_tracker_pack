VARIANT = Tracker.ActiveVariantUID
HAS_KEYS = VARIANT:find("keysanity")
HAS_ER = VARIANT:find("er")
PACK_READY = false


ACCESS_LEVEL = {
  [0] = AccessibilityLevel.None,
  [1] = AccessibilityLevel.Partial,
  [3] = AccessibilityLevel.Inspect,
  [5] = AccessibilityLevel.SequenceBreak,
  [6] = AccessibilityLevel.Normal,
  [7] = AccessibilityLevel.Cleared,
  [AccessibilityLevel.None] = 0,
  [AccessibilityLevel.Partial] = 1,
  [AccessibilityLevel.Inspect] = 3,
  [AccessibilityLevel.SequenceBreak] = 5,
  [AccessibilityLevel.Normal] = 6,
  [AccessibilityLevel.Cleared] = 7
}
