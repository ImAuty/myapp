import { fetchTodos } from "@/lib/api";
import TodoList from "./TodoList";

export default async function Home() {
  const todos = await fetchTodos();
  return (
      <main style={{ padding: "2rem" }}>
        <h1>Todoリスト</h1>
        <TodoList initialTodos={todos} />
      </main>
  );
}