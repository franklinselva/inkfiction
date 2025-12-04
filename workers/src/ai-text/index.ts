// AI Text Generation Worker
// Purpose: Secure proxy for Gemini API text generation
// Mirrors: supabase/functions/gemini-text-generation

import { GoogleGenAI } from '@google/genai';
import { corsHeaders, TEXT_MODEL, TEXT_OPERATIONS } from '../shared/constants';
import {
  ValidationError,
  GeminiAPIError,
  ConfigurationError,
  parseGeminiError,
  buildErrorResponse,
} from '../shared/errors';
import type { Env, TextGenerationRequest, GeminiContent, GenerationConfig } from '../shared/types';

/**
 * Validate incoming request
 */
function validateRequest(body: unknown): TextGenerationRequest {
  if (!body || typeof body !== 'object') {
    throw new ValidationError('request', 'Request body must be a JSON object');
  }

  const request = body as TextGenerationRequest;

  if (!request.contents || !Array.isArray(request.contents)) {
    throw new ValidationError('contents', 'Must be an array of content objects');
  }

  if (request.contents.length === 0) {
    throw new ValidationError('contents', 'Must contain at least one content object');
  }

  // Validate each content has parts
  for (const content of request.contents) {
    if (!content.parts || !Array.isArray(content.parts) || content.parts.length === 0) {
      throw new ValidationError('contents.parts', 'Each content must have at least one part');
    }
  }

  // Validate operation if provided
  if (request.operation && !TEXT_OPERATIONS.includes(request.operation as typeof TEXT_OPERATIONS[number])) {
    console.warn(`[AI-Text] Unknown operation: ${request.operation}, proceeding anyway`);
  }

  return request;
}

/**
 * Generate content via Gemini API
 */
async function generateContent(
  ai: GoogleGenAI,
  contents: GeminiContent[],
  generationConfig?: GenerationConfig
): Promise<unknown> {
  console.log('[AI-Text] Calling Gemini API...');
  console.log(`[AI-Text] Config: maxOutputTokens=${generationConfig?.maxOutputTokens}, responseMimeType=${generationConfig?.responseMimeType}`);

  // Build config with explicit maxOutputTokens - try both property names for SDK compatibility
  const config = {
    ...generationConfig,
    maxOutputTokens: generationConfig?.maxOutputTokens ?? 2048,
  };

  try {
    // Try using generationConfig property (older SDK style)
    const response = await ai.models.generateContent({
      model: TEXT_MODEL,
      contents: contents,
      generationConfig: config,  // Use generationConfig instead of config
    });

    // Log token usage for analytics
    if (response.usageMetadata) {
      const promptTokens = response.usageMetadata.promptTokenCount || 0;
      const responseTokens = response.usageMetadata.candidatesTokenCount || 0;
      const totalTokens = response.usageMetadata.totalTokenCount || (promptTokens + responseTokens);

      console.log(
        `[AI-Text] Token usage - Prompt: ${promptTokens}, ` +
        `Response: ${responseTokens}, ` +
        `Total: ${totalTokens}`
      );
    }

    console.log('[AI-Text] Request successful');
    return response;
  } catch (error) {
    console.error('[AI-Text] SDK error:', error);

    const err = error as { message?: string; status?: number };
    if (err?.message) {
      throw parseGeminiError(err, err?.status || 500);
    }

    throw new GeminiAPIError(
      err?.message || 'Text generation failed',
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
      const { contents, generationConfig, operation } = validateRequest(body);

      console.log(`[AI-Text] Operation: ${operation || 'default'}`);

      // ========================================================================
      // Step 3: Initialize Gemini Client
      // ========================================================================
      const ai = new GoogleGenAI({ apiKey: env.GEMINI_API_KEY });

      // ========================================================================
      // Step 4: Generate Content via Gemini API
      // ========================================================================
      const response = await generateContent(ai, contents, generationConfig);

      // ========================================================================
      // Step 5: Return Gemini Response (Unchanged)
      // ========================================================================
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
