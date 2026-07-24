package com.imauty.myapp

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.boot.web.servlet.FilterRegistrationBean
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.filter.OncePerRequestFilter
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

class RateLimitFilter(
    private val windowMillis: Long = 10_000,
    private val maxRequestsPerWindow: Int = 20,
) : OncePerRequestFilter() {
    private class Window(@Volatile var start: Long, val count: AtomicInteger)

    private val windows = ConcurrentHashMap<String, Window>()

    override fun doFilterInternal(request: HttpServletRequest, response: HttpServletResponse, filterChain: FilterChain) {
        val clientIp = request.getHeader("X-Forwarded-For")?.substringBefore(",")?.trim() ?: request.remoteAddr
        val now = System.currentTimeMillis()
        val window = windows.computeIfAbsent(clientIp) { Window(now, AtomicInteger(0)) }

        val count = synchronized(window) {
            if (now - window.start >= windowMillis) {
                window.start = now
                window.count.set(0)
            }
            window.count.incrementAndGet()
        }

        if (count > maxRequestsPerWindow) {
            response.status = 429 // Too Many Requests
            response.contentType = "application/json"
            response.writer.write("""{"error":"Too many requests, please slow down."}""")
            return
        }

        filterChain.doFilter(request, response)
    }
}

@Configuration
open class RateLimitFilterConfig {
    @Bean
    open fun rateLimitFilterRegistration(): FilterRegistrationBean<RateLimitFilter> {
        val registration = FilterRegistrationBean(RateLimitFilter())
        registration.urlPatterns = listOf("/api/*")
        return registration
    }
}
