package com.imauty.myapp

import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/todos")
class TodoController(private val repository: TodoRepository) {
    @GetMapping
    fun getAll(): List<Todo> {
        return repository.findAll()
    }
    @PostMapping
    fun create(@RequestBody request: TodoRequest): Todo {
        val todoTitle = request.title
        val entity = Todo(title = todoTitle)
        return repository.save(entity)
    }
    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: Long) {
        repository.deleteById(id)
    }
}