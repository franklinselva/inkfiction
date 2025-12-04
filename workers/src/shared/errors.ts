// Centralized error handling for Cloudflare Workers

import { corsHeaders } from './constants';

export class AppError extends Error {
  constructor(
    public override message: string,
    public code: number,
    public metadata?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export class ValidationError extends AppError {
  constructor(field: string, issue: string, constraint?: unknown) {
    super(
      `Invalid ${field}: ${issue}`,
      400,
      {
        field,
        issue,
        constraint,
        retryable: false,
      }
    );
    this.name = 'ValidationError';
  }
}

export class GeminiAPIError extends AppError {
  constructor(message: string, httpStatus: number, details?: unknown) {
    super(
      message || 'Gemini API error',
      httpStatus,
      {
        details,
        retryable: httpStatus >= 500 || httpStatus === 429,
        suggestion: httpStatus === 429
          ? 'Rate limit exceeded. Please try again later'
          : httpStatus >= 500
          ? 'Service temporarily unavailable. Please try again'
          : 'Please check your input and try again',
      }
    );
    this.name = 'GeminiAPIError';
  }
}

export class GeminiContentBlockedError extends AppError {
  constructor(safetyRatings: unknown[]) {
    super(
      'Content blocked by safety filters',
      400,
      {
        safetyRatings,
        retryable: false,
        suggestion: 'Please modify your prompt to avoid potentially unsafe content',
      }
    );
    this.name = 'GeminiContentBlockedError';
  }
}

export class ConfigurationError extends AppError {
  constructor(missing: string) {
    super(
      `Configuration error: ${missing} not set`,
      500,
      {
        missing,
        retryable: false,
        suggestion: 'Please contact support',
      }
    );
    this.name = 'ConfigurationError';
  }
}

/**
 * Parse Gemini API error response and return appropriate error class
 */
export function parseGeminiError(
  errorData: { error?: { message?: string; code?: number }; message?: string; status?: number },
  httpStatus: number
): AppError {
  const message = errorData?.error?.message || errorData?.message || 'Generation failed';
  const code = errorData?.error?.code || httpStatus;

  // Rate limiting
  if (httpStatus === 429) {
    return new GeminiAPIError('Rate limit exceeded', 429, errorData);
  }

  // Quota exceeded
  if (message.toLowerCase().includes('quota')) {
    return new GeminiAPIError('API quota exceeded', 429, errorData);
  }

  // Authentication errors
  if (httpStatus === 401 || httpStatus === 403) {
    return new ConfigurationError('API key invalid or unauthorized');
  }

  // Server errors
  if (httpStatus >= 500) {
    return new GeminiAPIError('Gemini service temporarily unavailable', httpStatus, errorData);
  }

  // Client errors
  if (httpStatus >= 400 && httpStatus < 500) {
    return new GeminiAPIError(message, httpStatus, errorData);
  }

  return new GeminiAPIError(message, code, errorData);
}

/**
 * Build standardized error response
 */
export function buildErrorResponse(error: Error | AppError): Response {
  const timestamp = new Date().toISOString();

  if (error instanceof AppError) {
    console.error(`[Error] ${error.name}:`, error.message, error.metadata);

    return new Response(
      JSON.stringify({
        error: {
          type: error.name,
          message: error.message,
          code: error.code,
          timestamp,
          ...error.metadata
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: error.code,
      }
    );
  }

  // Unexpected errors
  console.error('[Error] Unexpected:', error);
  return new Response(
    JSON.stringify({
      error: {
        type: 'UnexpectedError',
        message: error.message || 'Internal server error',
        code: 500,
        timestamp,
        retryable: true,
      },
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    }
  );
}
