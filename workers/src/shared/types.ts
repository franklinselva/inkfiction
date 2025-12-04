// Shared type definitions for Cloudflare Workers

// ============================================================================
// Text Generation Types
// ============================================================================

export interface GeminiContent {
  role?: string;
  parts: Array<{
    text?: string;
    inlineData?: {
      mimeType: string;
      data: string;
    };
  }>;
}

export interface GenerationConfig {
  temperature?: number;
  topK?: number;
  topP?: number;
  maxOutputTokens?: number;
  stopSequences?: string[];
  responseMimeType?: string;
}

export interface TextGenerationRequest {
  contents: GeminiContent[];
  generationConfig?: GenerationConfig;
  operation?: string;
}

// ============================================================================
// Image Generation Types
// ============================================================================

export interface ImageGenerationInput {
  prompt: string;
  aspect_ratio?: string;
  style_type?: string;
  style_reference_images?: string[];
  magic_prompt?: boolean;
}

export interface ImageGenerationRequest {
  version?: string;
  input: ImageGenerationInput;
  operation?: string;
}

export interface ImageGenerationResponse {
  id: string;
  model: string;
  version: string;
  input: ImageGenerationInput;
  status: 'succeeded' | 'failed';
  output: string;
  logs: string;
  error: string | null;
  metrics: {
    predict_time: number;
    total_time: number;
  };
  created_at: string;
  started_at: string;
  completed_at: string;
}

// ============================================================================
// Error Types
// ============================================================================

export interface ErrorResponse {
  error: {
    type: string;
    message: string;
    code: number;
    timestamp: string;
    retryable?: boolean;
    suggestion?: string;
    [key: string]: unknown;
  };
}

// ============================================================================
// Worker Environment
// ============================================================================

export interface Env {
  GEMINI_API_KEY: string;
}
