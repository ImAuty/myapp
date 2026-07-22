const API_BASE = (typeof window === "undefined")
    ? process.env.API_BASE_URL_INTERNAL
    : process.env.NEXT_PUBLIC_API_BASE_URL;

export type Todo = {
    id: number;
    title: string;
    done: boolean;
};

export async function fetchTodos(): Promise<Todo[]> {
    const res = await fetch(`${API_BASE}/api/todos`, {cache: "no-store"});
    return res.json();
}

export async function createTodo(title: string): Promise<Todo> {
    const res = await fetch(`${API_BASE}/api/todos`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({title}),
    });
    return res.json();
}

export async function deleteTodo(id: number): Promise<void> {
    await fetch(`${API_BASE}/api/todos/${id}`, {method: "DELETE"});
}