# InkFiction Cloudflare Workers

AI services for InkFiction iOS app, powered by Gemini 2.5 Flash.

## Workers

| Worker | Port | Purpose |
|--------|------|---------|
| `ai-text` | 8787 | Text generation (journal processing, summaries, persona creation) |
| `ai-image` | 8788 | Image generation (journal images, persona avatars) |

## Setup

```bash
# Install dependencies
npm install

# Copy environment variables
cp .dev.vars.example .dev.vars

# Edit .dev.vars and add your Gemini API key
```

## Local Development

```bash
# Run text worker (port 8787)
npm run dev:text

# Run image worker (port 8788)
npm run dev:image
```

## Testing

### Text Generation

```bash
curl -X POST http://localhost:8787 \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [
      {
        "parts": [{ "text": "Hello, how are you?" }]
      }
    ],
    "operation": "chat"
  }'
```

### Image Generation

```bash
curl -X POST http://localhost:8788 \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "prompt": "A peaceful mountain landscape at sunset"
    },
    "operation": "journal_image"
  }'
```

## Deployment

```bash
# Set production secret
npx wrangler secret put GEMINI_API_KEY --config wrangler.text.toml
npx wrangler secret put GEMINI_API_KEY --config wrangler.image.toml

# Deploy workers
npm run deploy:text
npm run deploy:image

# Or deploy all
npm run deploy:all
```

## API Reference

### POST /ai-text

Request body:
```json
{
  "contents": [
    {
      "role": "user",
      "parts": [{ "text": "Your prompt here" }]
    }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 1024
  },
  "operation": "journal_processing"
}
```

Operations: `journal_processing`, `weekly_monthly_summary`, `persona_creation`, `chat`

### POST /ai-image

Request body:
```json
{
  "input": {
    "prompt": "Image description",
    "aspect_ratio": "16:9",
    "style_type": "realistic"
  },
  "operation": "journal_image"
}
```

Operations: `journal_image`, `persona_avatar`

Aspect ratios: `1:1`, `16:9`, `9:16`, `3:2`, `2:3`, `4:3`, `3:4`, `4:5`, `5:4`, `21:9`

Style types: `realistic`, `design`, `anime`
