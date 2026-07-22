"use client";

import {useState} from "react";
import {createTodo, deleteTodo, Todo} from "@/lib/api";

export default function TodoList({initialTodos}: { initialTodos: Todo[] }) {
    const [todos, setTodos] = useState(initialTodos);
    const [title, setTitle] = useState("");

    const handleAdd = async () => {
        if (!title.trim()) return;
        const newTodo = await createTodo(title);
        setTodos([...todos, newTodo]);
        setTitle("");
    };

    const handleDelete = async (id: number) => {
        await deleteTodo(id);
        setTodos(todos.filter((t) => t.id !== id));
    };

    return (
        <div>
            <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Todo"/>
            <button onClick={handleAdd}>追加</button>
            <ul>
                {todos.map((todo) => (
                    <li key={todo.id}>
                        {todo.title}
                        <button onClick={() => handleDelete(todo.id)}>削除</button>
                    </li>
                ))}
            </ul>
        </div>
    );
}