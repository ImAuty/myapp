import { fetchTodos } from "@/lib/api";
import TodoList from "./TodoList";

export default async function Home() {
  try {
    const todos = await fetchTodos();
    return (
        <main style={{ padding: "2rem" }}>
          <h1>Todoリスト</h1>
          <TodoList initialTodos={todos} />
        </main>
    );
  } catch {
    return (
        <main style={{ padding: "2rem" }}>
          <h1>Todoリスト</h1>
          <p style={{ color: "red" }}>Todoの読み込みに失敗しました。しばらくしてから再度お試しください。</p>
        </main>
    );
  }
}
