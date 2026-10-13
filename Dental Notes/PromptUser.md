Analyze the following dental note and propose followups only when confidence is high.
It is valid to return zero followups.

Respond as JSON object:
{
  "followups": [
    {
      "descriptionText": "string",
      "confidence": 0.0,
      "scheduleType": "relative or absolute",
      "offsetValue": 1,
      "offsetUnit": "days|months|years",
      "absoluteAtISO8601UTC": "2026-10-10T09:30:00Z"
    }
  ]
}

Rules:
- confidence is [0, 1]
- include only high-confidence followups
- scheduleType is "relative" or "absolute"
- use "relative" for in X days/months/years
- use "absolute" only when a specific date is clearly present or strongly implied
- if relative, absoluteAtISO8601UTC should be null
- if absolute, offsetValue and offsetUnit should be null

Reference date (note created date): {{referenceISO}}

Note:
{{noteText}}
