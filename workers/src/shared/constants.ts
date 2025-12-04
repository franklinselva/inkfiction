// Shared constants for Cloudflare Workers

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

// Text generation operations
export const TEXT_OPERATIONS = [
  'journal_processing',
  'weekly_monthly_summary',
  'persona_creation',
  'chat',
] as const;

// Image generation operations
export const IMAGE_OPERATIONS = [
  'journal_image',
  'persona_avatar',
] as const;

// Aspect ratio mapping
export const ASPECT_RATIO_MAP: Record<string, string> = {
  '1:1': '1:1',
  '16:9': '16:9',
  '9:16': '9:16',
  '3:2': '3:2',
  '2:3': '2:3',
  '4:3': '4:3',
  '3:4': '3:4',
  '4:5': '4:5',
  '5:4': '5:4',
  '21:9': '21:9',
};

export const DEFAULT_ASPECT_RATIO = '16:9';

// Style prompts for image enhancement
export const STYLE_PROMPTS: Record<string, string> = {
  'realistic': 'photorealistic, high detail, professional photography',
  'design': 'illustration, design-focused, clean aesthetic',
  'anime': 'anime style, vibrant colors, stylized',
};

// Max reference images for image-to-image
export const MAX_REFERENCE_IMAGES = 3;

// Models
export const TEXT_MODEL = 'gemini-2.5-flash';
export const IMAGE_MODEL = 'gemini-2.5-flash-preview-05-20';
