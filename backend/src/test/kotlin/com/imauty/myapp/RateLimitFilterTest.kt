package com.imauty.myapp

import org.junit.jupiter.api.Test
import org.springframework.mock.web.MockFilterChain
import org.springframework.mock.web.MockHttpServletRequest
import org.springframework.mock.web.MockHttpServletResponse
import kotlin.test.assertEquals

class RateLimitFilterTest {
    @Test
    fun `allows requests under the limit`() {
        val filter = RateLimitFilter(windowMillis = 10_000, maxRequestsPerWindow = 3)

        repeat(3) {
            val request = MockHttpServletRequest("GET", "/api/todos").apply { remoteAddr = "1.2.3.4" }
            val response = MockHttpServletResponse()
            filter.doFilter(request, response, MockFilterChain())
            assertEquals(200, response.status)
        }
    }

    @Test
    fun `blocks requests over the limit with 429`() {
        val filter = RateLimitFilter(windowMillis = 10_000, maxRequestsPerWindow = 3)

        repeat(3) {
            val request = MockHttpServletRequest("GET", "/api/todos").apply { remoteAddr = "5.6.7.8" }
            filter.doFilter(request, MockHttpServletResponse(), MockFilterChain())
        }

        val request = MockHttpServletRequest("GET", "/api/todos").apply { remoteAddr = "5.6.7.8" }
        val response = MockHttpServletResponse()
        filter.doFilter(request, response, MockFilterChain())

        assertEquals(429, response.status)
    }

    @Test
    fun `tracks different IPs independently`() {
        val filter = RateLimitFilter(windowMillis = 10_000, maxRequestsPerWindow = 1)

        val first = MockHttpServletRequest("GET", "/api/todos").apply { remoteAddr = "1.1.1.1" }
        val firstResponse = MockHttpServletResponse()
        filter.doFilter(first, firstResponse, MockFilterChain())

        val second = MockHttpServletRequest("GET", "/api/todos").apply { remoteAddr = "2.2.2.2" }
        val secondResponse = MockHttpServletResponse()
        filter.doFilter(second, secondResponse, MockFilterChain())

        assertEquals(200, firstResponse.status)
        assertEquals(200, secondResponse.status)
    }

    @Test
    fun `uses the first address in X-Forwarded-For when present`() {
        val filter = RateLimitFilter(windowMillis = 10_000, maxRequestsPerWindow = 1)

        val first = MockHttpServletRequest("GET", "/api/todos").apply {
            remoteAddr = "10.0.0.1" // ALB's address
            addHeader("X-Forwarded-For", "9.9.9.9, 10.0.0.1")
        }
        filter.doFilter(first, MockHttpServletResponse(), MockFilterChain())

        val second = MockHttpServletRequest("GET", "/api/todos").apply {
            remoteAddr = "10.0.0.1" // same ALB, different real client would differ, but reuse to hit the limit
            addHeader("X-Forwarded-For", "9.9.9.9, 10.0.0.1")
        }
        val secondResponse = MockHttpServletResponse()
        filter.doFilter(second, secondResponse, MockFilterChain())

        assertEquals(429, secondResponse.status)
    }
}
