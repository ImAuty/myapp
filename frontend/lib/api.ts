const API_BASE = (typeof window === "undefined")
    ? process.env.API_BASE_URL_INTERNAL
    : process.env.NEXT_PUBLIC_API_BASE_URL;

export type Todo = {
    id: number;
    title: string;
    done: boolean;
};

async function handleResponse<T>(res: Response): Promise<T> {
    if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.error ?? `リクエストに失敗しました (${res.status})`);
    }
    return res.json();
}

export async function fetchTodos(): Promise<Todo[]> {
    const res = await fetch(`${API_BASE}/api/todos`, {cache: "no-store"});
    return handleResponse<Todo[]>(res);
}

export async function createTodo(title: string): Promise<Todo> {
    const res = await fetch(`${API_BASE}/api/todos`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({title}),
    });
    return handleResponse<Todo>(res);
}

export async function deleteTodo(id: number): Promise<void> {
    const res = await fetch(`${API_BASE}/api/todos/${id}`, {method: "DELETE"});
    if (!res.ok) {
        const body = await res.json().catch(() => null);
        throw new Error(body?.error ?? `リクエストに失敗しました (${res.status})`);
    }
}
