package com.imauty.myapp

import tools.jackson.databind.ObjectMapper
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.eq
import org.mockito.BDDMockito.given
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.context.bean.override.mockito.MockitoBean
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status

@WebMvcTest(TodoController::class)
class TodoControllerTest {
    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @MockitoBean
    lateinit var repository: TodoRepository

    @Test
    fun `GET returns all todos`() {
        given(repository.findAll()).willReturn(listOf(Todo(id = 1, title = "test", done = false)))

        mockMvc.perform(get("/api/todos"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$[0].title").value("test"))
    }

    @Test
    fun `POST with blank title is rejected`() {
        mockMvc.perform(
            post("/api/todos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(mapOf("title" to "")))
        ).andExpect(status().isBadRequest)

        verify(repository, never()).save(any())
    }

    @Test
    fun `POST with a title over 255 chars is rejected`() {
        // Todo.title is an unannotated String column, so Hibernate defaults it to varchar(255).
        // This must stay in sync with TodoRequest's @Size(max=...) or an over-limit title passes
        // validation and then blows up as a 500 on insert instead of a clean 400.
        mockMvc.perform(
            post("/api/todos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(mapOf("title" to "a".repeat(256))))
        ).andExpect(status().isBadRequest)

        verify(repository, never()).save(any())
    }

    @Test
    fun `POST with valid title creates a todo`() {
        given(repository.save(any())).willReturn(Todo(id = 1, title = "buy milk", done = false))

        mockMvc.perform(
            post("/api/todos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(mapOf("title" to "buy milk")))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.title").value("buy milk"))
    }

    @Test
    fun `DELETE of a missing id returns 404`() {
        given(repository.existsById(eq(999L))).willReturn(false)

        mockMvc.perform(delete("/api/todos/999"))
            .andExpect(status().isNotFound)

        verify(repository, never()).deleteById(eq(999L))
    }

    @Test
    fun `DELETE of an existing id returns 200`() {
        given(repository.existsById(eq(1L))).willReturn(true)

        mockMvc.perform(delete("/api/todos/1"))
            .andExpect(status().isOk)

        verify(repository).deleteById(eq(1L))
    }
}
