import Score

let authGuard = HTTPMiddleware { request, next in
    guard request.headers["authorization"] != nil else {
        throw AuthError.unauthorized
    }
    return try await next(request)
}

enum AuthError: Error {
    case unauthorized
}
