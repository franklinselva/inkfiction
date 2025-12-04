//
//  AIError.swift
//  InkFiction
//
//  Error types for AI services
//

import Foundation

// MARK: - AI Error

/// Comprehensive error type for AI operations
enum AIError: LocalizedError {
    // Network errors
    case networkError(underlying: Error)
    case timeout
    case noConnection

    // API errors
    case invalidResponse
    case serverError(code: Int, message: String)
    case rateLimited(retryAfter: TimeInterval?)
    case quotaExceeded
    case invalidAPIKey

    // Request errors
    case invalidRequest(reason: String)
    case contentTooLong(max: Int, actual: Int)
    case missingRequiredField(field: String)

    // Response errors
    case parsingError(underlying: Error)
    case emptyResponse
    case unexpectedFormat(expected: String)

    // Image errors
    case imageGenerationFailed(reason: String)
    case invalidImageData
    case imageTooLarge(max: Int, actual: Int)

    // Subscription errors
    case subscriptionRequired(feature: String)
    case dailyLimitReached(feature: String, limit: Int)

    // Generic
    case unknown(message: String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out. Please try again."
        case .noConnection:
            return "No internet connection. Please check your network."

        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds."
            }
            return "Too many requests. Please try again later."
        case .quotaExceeded:
            return "AI quota exceeded. Please upgrade your subscription."
        case .invalidAPIKey:
            return "Invalid API configuration."

        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .contentTooLong(let max, let actual):
            return "Content too long (\(actual) characters). Maximum is \(max)."
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"

        case .parsingError:
            return "Failed to process server response."
        case .emptyResponse:
            return "Empty response from server."
        case .unexpectedFormat(let expected):
            return "Unexpected response format. Expected: \(expected)"

        case .imageGenerationFailed(let reason):
            return "Image generation failed: \(reason)"
        case .invalidImageData:
            return "Invalid image data received."
        case .imageTooLarge(let max, let actual):
            return "Image too large (\(actual) bytes). Maximum is \(max) bytes."

        case .subscriptionRequired(let feature):
            return "\(feature) requires a subscription."
        case .dailyLimitReached(let feature, let limit):
            return "Daily limit reached for \(feature) (\(limit)/day)."

        case .unknown(let message):
            return message
        case .cancelled:
            return "Operation was cancelled."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .serverError:
            return true
        case .rateLimited:
            return true
        case .noConnection, .quotaExceeded, .subscriptionRequired, .dailyLimitReached:
            return false
        case .invalidRequest, .contentTooLong, .missingRequiredField:
            return false
        case .parsingError, .emptyResponse, .unexpectedFormat:
            return false
        case .imageGenerationFailed, .invalidImageData, .imageTooLarge:
            return true
        case .invalidAPIKey, .invalidResponse:
            return false
        case .unknown:
            return false
        case .cancelled:
            return false
        }
    }

    var shouldShowAlert: Bool {
        switch self {
        case .cancelled:
            return false
        case .rateLimited:
            return true
        default:
            return true
        }
    }
}

// MARK: - Error Conversion

extension AIError {
    /// Create from API error response
    static func from(response: AIErrorResponse) -> AIError {
        switch response.code {
        case "RATE_LIMITED":
            return .rateLimited(retryAfter: nil)
        case "QUOTA_EXCEEDED":
            return .quotaExceeded
        case "INVALID_API_KEY":
            return .invalidAPIKey
        case "INVALID_REQUEST":
            return .invalidRequest(reason: response.message)
        case "CONTENT_TOO_LONG":
            return .contentTooLong(max: 0, actual: 0)
        case "IMAGE_GENERATION_FAILED":
            return .imageGenerationFailed(reason: response.message)
        case "SUBSCRIPTION_REQUIRED":
            return .subscriptionRequired(feature: response.message)
        default:
            return .unknown(message: response.message)
        }
    }

    /// Create from HTTP status code
    static func from(statusCode: Int, message: String? = nil) -> AIError {
        switch statusCode {
        case 400:
            return .invalidRequest(reason: message ?? "Bad request")
        case 401:
            return .invalidAPIKey
        case 403:
            return .subscriptionRequired(feature: message ?? "This feature")
        case 404:
            return .invalidRequest(reason: "Endpoint not found")
        case 429:
            return .rateLimited(retryAfter: nil)
        case 500...599:
            return .serverError(code: statusCode, message: message ?? "Internal server error")
        default:
            return .unknown(message: message ?? "Unknown error (code: \(statusCode))")
        }
    }
}
