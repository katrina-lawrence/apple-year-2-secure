Analyze the following dental note and return structured note details plus followups.
It is valid to return zero followups.

Respond as JSON object:
{
  "summary": "string",
  "balanceDueAmount": 120.5,
  "balanceDueCurrency": "USD",
  "categories": ["Payment", "Insurance", "Appointment"],
  "appointmentTiming": "next Tuesday morning",
  "followups": [
    {
      "descriptionText": "string",
      "category": "Payment",
      "confidence": 0.0,
      "scheduleType": "relative or absolute",
      "offsetValue": 1,
      "offsetUnit": "days|months|years",
      "absoluteAtISO8601UTC": "2026-10-10T09:30:00Z"
    }
  ]
}

Rules:
- summary: brief, plain-language, factual summary of the note
- balanceDueAmount: number only when a balance due is explicitly present, otherwise null
- balanceDueCurrency: 3-letter ISO code when present (e.g. USD), otherwise null
- categories: array of applicable categories found in the note (e.g. Payment, Insurance, Appointment); empty array if none
- appointmentTiming: only when timing is mentioned (general day/time/month/year text is acceptable), otherwise null
- confidence is [0, 1]
- include only high-confidence followups
- each followup must include a concise category
- scheduleType is "relative" or "absolute"
- use "relative" for in X days/months/years
- use "absolute" only when a specific date is clearly present or strongly implied
- if relative, absoluteAtISO8601UTC should be null
- if absolute, offsetValue and offsetUnit should be null

Reference date (note created date): {{referenceISO}}

Note:
{{noteText}}
