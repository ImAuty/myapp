package com.imauty.myapp

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class TodoRequest(
    @field:NotBlank
    @field:Size(max = 500)
    val title: String
)
