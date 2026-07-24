"use client";

import {useState} from "react";
import {createTodo, deleteTodo, Todo} from "@/lib/api";

export default function TodoList({initialTodos}: { initialTodos: Todo[] }) {
    const [todos, setTodos] = useState(initialTodos);
    const [title, setTitle] = useState("");
    const [error, setError] = useState<string | null>(null);

    const handleAdd = async () => {
        if (!title.trim()) return;
        setError(null);
        try {
            const newTodo = await createTodo(title);
            setTodos([...todos, newTodo]);
            setTitle("");
        } catch (e) {
            setError(e instanceof Error ? e.message : "追加に失敗しました");
        }
    };

    const handleDelete = async (id: number) => {
        setError(null);
        try {
            await deleteTodo(id);
            setTodos(todos.filter((t) => t.id !== id));
        } catch (e) {
            setError(e instanceof Error ? e.message : "削除に失敗しました");
        }
    };

    return (
        <div>
            <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Todo"/>
            <button onClick={handleAdd}>追加</button>
            {error && <p style={{color: "red"}}>{error}</p>}
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
