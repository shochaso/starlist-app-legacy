# STARLIST Intake Pipeline

YouTube watch history OCR intake system with caching and performance optimization.

## Overview

The intake pipeline processes OCR text from YouTube watch history screenshots and returns structured video metadata.

```
OCR Text → Groq AI → Parsed Items → YouTube API → Enriched Items → Response
```

## Required Environment Variables

### Next.js (Development)
```bash
GROQ_API_KEY=your_groq_api_key
YOUTUBE_API_KEY=your_youtube_api_key
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Supabase Edge Functions (Production)
```bash
# Set these in Supabase Dashboard → Edge Functions → Environment Variables
GROQ_API_KEY=your_groq_api_key
YOUTUBE_API_KEY=your_youtube_api_key
```

## API Endpoints

### Production (Recommended): Supabase Edge Function
```bash
POST https://your-project.supabase.co/functions/v1/intake
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
Content-Type: application/json

{
  "ocrText": "Your OCR text from YouTube watch history..."
}
```

**Example curl:**
```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/intake' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"ocrText": "Sample OCR text with YouTube video titles and channels"}'
```

### Development: Next.js API (Deprecated)
```bash
POST /api/youtube-intake
Content-Type: application/json

{
  "ocrText": "Your OCR text..."
}
```

## Response Format

```typescript
interface IntakeResponse {
  items: IntakeItem[];
}

interface IntakeItem {
  title: string;
  channel: string;
  time: string | null;  // e.g., "13:07"
  videoId: string;      // YouTube video ID
  duration: string;     // e.g., "10:30"
  thumbnails: Record<string, unknown>; // YouTube thumbnail URLs
}
```

## Caching Strategy

- **YouTube Videos**: 24 hours TTL
- **Groq Responses**: 6 hours TTL
- **Cache Keys**: `yt:video:{videoId}`, `groq:{sha256(prompt)}`

## Performance Goals

- 100 items intake: < 0.1 seconds (cached)
- Cache hit rate: > 95% for repeat requests
- Fallback graceful on API failures

## Error Handling

All errors return JSON format:
```json
{
  "error": true,
  "message": "Error description",
  "raw": "Optional raw error details"
}
```

## Development

```bash
# Run tests
npm test

# Run with coverage
npm run test:coverage

# Development server
npm run dev
```

## Architecture

- **Type Safety**: TypeScript strict mode
- **Caching**: globalThis (dev) + Supabase KV (prod)
- **Error Resilience**: Graceful fallbacks on API failures
- **Logging**: Minimal, no secrets exposure






