import { chatGet, chatPost } from '@/utils/chat-request'

// 获取会话列表
export function getConversations() {
  return chatGet('/chat/conversations')
}

// 获取会话消息历史 (分页)
export function getMessages(conversationId, params) {
  return chatGet(`/chat/conversations/${conversationId}/messages`, params)
}

// 创建或获取会话
export function createConversation(data) {
  return chatPost('/chat/conversations', data)
}

// 发送消息
export function sendChatMessage(data) {
  return chatPost('/chat/messages', data)
}

// 标记会话消息为已读
export function markConversationRead(conversationId) {
  return chatPost(`/chat/conversations/${conversationId}/read`)
}

// 获取未读消息数
export function getChatUnreadCount() {
  return chatGet('/chat/unread-count')
}
