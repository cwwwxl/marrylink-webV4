import request from "@/utils/request";

/**
 * 聊天API - 使用主后端 API (通过 Vite 代理 /dev-api)
 */

/** 获取会话列表 */
export function getConversations() {
  return request({ url: "/chat/conversations", method: "get" });
}

/** 获取会话消息历史 (分页) */
export function getMessages(
  conversationId: string | number,
  params?: { current?: number; size?: number }
) {
  return request({
    url: `/chat/conversations/${conversationId}/messages`,
    method: "get",
    params,
  });
}

/** 创建或获取会话 */
export function createConversation(data: {
  targetId: number;
  targetType: string;
}) {
  return request({ url: "/chat/conversations", method: "post", data });
}

/** 发送消息 */
export function sendChatMessage(data: {
  conversationId: number;
  content: string;
  msgType?: string;
}) {
  return request({ url: "/chat/messages", method: "post", data });
}

/** 标记会话消息为已读 */
export function markConversationRead(conversationId: number | string) {
  return request({
    url: `/chat/conversations/${conversationId}/read`,
    method: "post",
  });
}

/** 上传聊天图片 */
export function uploadChatImage(formData: FormData) {
  return request({
    url: "/chat/upload",
    method: "post",
    data: formData,
    headers: { "Content-Type": "multipart/form-data" },
  });
}

/** 获取未读消息总数 */
export function getUnreadCount() {
  return request({ url: "/chat/unread-count", method: "get" });
}
