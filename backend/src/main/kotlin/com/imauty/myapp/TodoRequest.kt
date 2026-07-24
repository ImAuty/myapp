package com.imauty.myapp

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class TodoRequest(
    @field:NotBlank
    @field:Size(max = 255) // must match Todo.title's column length (Hibernate default for an unannotated String)
    val title: String
)
