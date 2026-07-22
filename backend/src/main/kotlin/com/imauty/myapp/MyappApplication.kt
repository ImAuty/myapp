package com.imauty.myapp

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
open class MyappApplication

fun main(args: Array<String>) {
	runApplication<MyappApplication>(*args)
}
