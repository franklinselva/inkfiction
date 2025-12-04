// AI Image Generation Worker
// Purpose: Secure proxy for Gemini API image generation
// Mirrors: supabase/functions/gemini-image-generation

import { GoogleGenAI } from '@google/genai';
import {
  corsHeaders,
  IMAGE_MODEL,
  IMAGE_OPERATIONS,
  ASPECT_RATIO_MAP,
  DEFAULT_ASPECT_RATIO,
  STYLE_PROMPTS,
  MAX_REFERENCE_IMAGES,
} from '../shared/constants';
import {
  ValidationError,
  GeminiAPIError,
  GeminiContentBlockedError,
  ConfigurationError,
  parseGeminiError,
  buildErrorResponse,
} from '../shared/errors';
import type { Env, ImageGenerationRequest, ImageGenerationInput, ImageGenerationResponse } from '../shared/types';

/**
 * Validate incoming request
 */
function validateRequest(body: unknown): ImageGenerationRequest {
  if (!body || typeof body !== 'object') {
    throw new ValidationError('request', 'Request body must be a JSON object');
  }

  const request = body as ImageGenerationRequest;

  if (!request.input) {
    throw new ValidationError('input', 'Input object is required');
  }

  if (!request.input.prompt || typeof request.input.prompt !== 'string') {
    throw new ValidationError('input.prompt', 'Prompt string is required');
  }

  if (request.input.prompt.length < 3) {
    throw new ValidationError('input.prompt', 'Prompt must be at least 3 characters');
  }

  // Validate operation if provided
  const operation = request.operation || 'journal_image';
  if (!IMAGE_OPERATIONS.includes(operation as typeof IMAGE_OPERATIONS[number])) {
    console.warn(`[AI-Image] Unknown operation: ${operation}, proceeding anyway`);
  }

  return request;
}

/**
 * Build SDK-compatible request format
 */
function buildSDKRequest(input: ImageGenerationInput): {
  model: string;
  contents: Array<{ text?: string; inlineData?: { mimeType: string; data: string } }>;
  config: { responseModalities: string[] };
} {
  // Build prompt with style enhancement
  let enhancedPrompt = input.prompt;
  if (input.style_type && STYLE_PROMPTS[input.style_type]) {
    enhancedPrompt = `${input.prompt}, ${STYLE_PROMPTS[input.style_type]}`;
  }

  // Build parts array - start with text prompt
  const parts: Array<{ text?: string; inlineData?: { mimeType: string; data: string } }> = [
    { text: enhancedPrompt }
  ];

  // Add reference images if provided (up to 3) - supports image-to-image
  if (input.style_reference_images && input.style_reference_images.length > 0) {
    console.log(`[AI-Image] Adding ${input.style_reference_images.length} reference image(s) for image-to-image`);

    for (const imageDataUrl of input.style_reference_images.slice(0, MAX_REFERENCE_IMAGES)) {
      // Extract base64 data and mime type from data URL
      // Format: data:image/jpeg;base64,<data>
      const matches = imageDataUrl.match(/^data:([^;]+);base64,(.+)$/);
      if (matches) {
        const [, mimeType, base64Data] = matches;
        parts.push({
          inlineData: {
            mimeType: mimeType,
            data: base64Data
          }
        });
      }
    }
  }

  return {
    model: IMAGE_MODEL,
    contents: parts,
    config: {
      responseModalities: ['Text', 'Image'],
    }
  };
}

/**
 * Extract base64 image data from SDK response
 */
function extractImageData(response: unknown): { base64Data: string; mimeType: string } {
  console.log('[AI-Image] Parsing response...');

  const resp = response as {
    candidates?: Array<{
      content?: {
        parts?: Array<{
          inlineData?: { data: string; mimeType?: string };
          inline_data?: { data: string; mime_type?: string };
        }>;
      };
    }>;
  };

  const candidates = resp.candidates;
  if (!candidates || candidates.length === 0) {
    console.error('[AI-Image] No candidates in response');
    throw new GeminiAPIError('No candidates in response', 500);
  }

  const parts = candidates[0].content?.parts;
  if (!parts || parts.length === 0) {
    console.error('[AI-Image] No parts in candidate');
    throw new GeminiAPIError('No parts in candidate', 500);
  }

  // Check for image data - SDK returns camelCase (inlineData)
  for (const part of parts) {
    // Primary: camelCase for SDK responses
    if (part.inlineData) {
      const base64Data = part.inlineData.data;
      const mimeType = part.inlineData.mimeType || 'image/png';
      console.log(`[AI-Image] Found image data: ${mimeType}, ${base64Data.length} bytes`);
      return { base64Data, mimeType };
    }
    // Fallback: snake_case for REST API responses
    if (part.inline_data) {
      const base64Data = part.inline_data.data;
      const mimeType = part.inline_data.mime_type || 'image/png';
      console.log(`[AI-Image] Found image data (snake_case): ${mimeType}, ${base64Data.length} bytes`);
      return { base64Data, mimeType };
    }
  }

  console.error('[AI-Image] No image data found in parts');
  throw new GeminiAPIError('No image data found in response', 500);
}

/**
 * Generate image via Gemini API
 */
async function generateImage(
  ai: GoogleGenAI,
  input: ImageGenerationInput,
  operation: string
): Promise<{ base64Data: string; mimeType: string }> {
  const sdkRequest = buildSDKRequest(input);

  console.log(`[AI-Image] Calling Gemini API...`);

  try {
    const response = await ai.models.generateContent(sdkRequest);

    // Check for safety filter blocks (ONLY for journal_image operations)
    if (operation === 'journal_image') {
      const resp = response as {
        candidates?: Array<{
          finishReason?: string;
          safetyRatings?: unknown[];
        }>;
      };
      const finishReason = resp.candidates?.[0]?.finishReason;

      if (finishReason === 'SAFETY') {
        const safetyRatings = resp.candidates?.[0]?.safetyRatings || [];
        console.error('[AI-Image] Content blocked by safety filters:', safetyRatings);
        throw new GeminiContentBlockedError(safetyRatings);
      }
    }

    // Extract base64 image from response
    const { base64Data, mimeType } = extractImageData(response);

    console.log(`[AI-Image] Image generated successfully, size: ${base64Data.length} bytes`);

    // Log usage metadata if available
    const resp = response as {
      usageMetadata?: {
        promptTokenCount?: number;
        candidatesTokenCount?: number;
        totalTokenCount?: number;
      };
    };
    if (resp.usageMetadata) {
      const promptTokens = resp.usageMetadata.promptTokenCount || 0;
      const responseTokens = resp.usageMetadata.candidatesTokenCount || 0;
      const totalTokens = resp.usageMetadata.totalTokenCount || (promptTokens + responseTokens);

      console.log(
        `[AI-Image] Token usage - Prompt: ${promptTokens}, ` +
        `Response: ${responseTokens}, ` +
        `Total: ${totalTokens}`
      );
    }

    return { base64Data, mimeType };
  } catch (error) {
    // Re-throw GeminiContentBlockedError as-is
    if (error instanceof GeminiContentBlockedError) {
      throw error;
    }

    console.error('[AI-Image] SDK error:', error);

    const err = error as { message?: string; status?: number };
    if (err?.message) {
      throw parseGeminiError(err, err?.status || 500);
    }

    throw new GeminiAPIError(
      err?.message || 'Image generation failed',
      err?.status || 500,
      error
    );
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders });
    }

    const startTime = Date.now();

    try {
      // ========================================================================
      // Step 1: Validate API Key Configuration
      // ========================================================================
      if (!env.GEMINI_API_KEY) {
        throw new ConfigurationError('GEMINI_API_KEY');
      }

      // ========================================================================
      // Step 2: Parse and Validate Request
      // ========================================================================
      const body = await request.json();
      const { version, input, operation = 'journal_image' } = validateRequest(body);

      console.log(`[AI-Image] Operation: ${operation}, Prompt: ${input.prompt.substring(0, 50)}...`);

      // ========================================================================
      // Step 3: Initialize Gemini Client
      // ========================================================================
      const ai = new GoogleGenAI({ apiKey: env.GEMINI_API_KEY });

      // ========================================================================
      // Step 4: Generate Image via Gemini API
      // ========================================================================
      const { base64Data, mimeType } = await generateImage(ai, input, operation);

      // ========================================================================
      // Step 5: Return Response with Base64 Image Data
      // ========================================================================
      const totalTime = (Date.now() - startTime) / 1000;
      const predictionId = crypto.randomUUID();

      const response: ImageGenerationResponse = {
        id: predictionId,
        model: 'gemini-2.5-flash-image',
        version: version || 'gemini-2.5-flash',
        input: input,
        status: 'succeeded',
        output: `data:${mimeType};base64,${base64Data}`,
        logs: '',
        error: null,
        metrics: {
          predict_time: totalTime,
          total_time: totalTime,
        },
        created_at: new Date(startTime).toISOString(),
        started_at: new Date(startTime).toISOString(),
        completed_at: new Date().toISOString(),
      };

      console.log(`[AI-Image] Generation complete in ${totalTime.toFixed(2)}s`);

      return new Response(
        JSON.stringify(response),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );

    } catch (error) {
      return buildErrorResponse(error as Error);
    }
  },
};
