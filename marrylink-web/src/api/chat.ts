import axios from "axios";
import { TOKEN_KEY } from "@/enums/CacheEnum";

// Create a separate axios instance for chat server (runs on port 3001)
const chatService = axios.create({
  baseURL: "http://localhost:3001/api/v1",
  timeout: 30000,
  headers: { "Content-Type": "application/json" },
});

chatService.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = token;
  }
  return config;
});

chatService.interceptors.response.use(
  (response) => response.data,
  (error) => {
    console.error("[ChatAPI Error]", error);
    return Promise.reject(error);
  }
);

/** Get conversation list */
export function getConversations() {
  return chatService({ url: "/chat/conversations", method: "get" });
}

/** Get messages for a conversation (with pagination) */
export function getMessages(
  conversationId: string,
  params?: { page?: number; size?: number }
) {
  return chatService({
    url: `/chat/conversations/${conversationId}/messages`,
    method: "get",
    params,
  });
}

/** Create or get conversation */
export function createConversation(data: {
  targetId: number;
  targetType: string;
}) {
  return chatService({ url: "/chat/conversations", method: "post", data });
}

/** Upload chat image */
export function uploadChatImage(formData: FormData) {
  return chatService({
    url: "/chat/upload",
    method: "post",
    data: formData,
    headers: { "Content-Type": "multipart/form-data" },
  });
}

/** Get unread count */
export function getUnreadCount() {
  return chatService({ url: "/chat/unread-count", method: "get" });
}
