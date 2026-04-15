<template>
  <div class="chat-container">
    <!-- LEFT PANEL: Conversation List -->
    <div class="chat-sidebar">
      <div class="sidebar-header">
        <h3 class="sidebar-title">消息</h3>
        <el-badge :value="totalUnread" :hidden="totalUnread === 0" :max="99" class="unread-badge">
          <el-icon :size="18"><ChatDotRound /></el-icon>
        </el-badge>
      </div>
      <div class="sidebar-search">
        <el-input v-model="searchKeyword" placeholder="搜索会话" prefix-icon="Search" clearable />
      </div>
      <el-scrollbar class="conversation-list">
        <div
          v-for="conv in filteredConversations"
          :key="conv.id"
          class="conversation-item"
          :class="{ active: currentConversation?.id === conv.id }"
          @click="selectConversation(conv)"
        >
          <el-avatar :size="44" :src="conv.avatar" class="conv-avatar">
            {{ conv.name?.charAt(0) || '?' }}
          </el-avatar>
          <div class="conv-info">
            <div class="conv-top-row">
              <span class="conv-name">{{ conv.name }}</span>
              <span class="conv-time">{{ formatTime(conv.lastMessageTime) }}</span>
            </div>
            <div class="conv-bottom-row">
              <span class="conv-preview">{{ conv.lastMessage || '暂无消息' }}</span>
              <el-badge v-if="conv.unreadCount > 0" :value="conv.unreadCount" :max="99" class="conv-unread" />
            </div>
          </div>
        </div>
        <div v-if="filteredConversations.length === 0" class="no-conversations">
          暂无会话
        </div>
      </el-scrollbar>
    </div>

    <!-- RIGHT PANEL: Chat Window -->
    <div class="chat-main">
      <!-- placeholder: empty / active chat -->
      <template v-if="!currentConversation">
        <div class="chat-empty">
          <el-empty description="选择一个会话开始聊天" />
        </div>
      </template>
      <template v-else>
        <!-- Chat Header -->
        <div class="chat-header">
          <div class="chat-header-info">
            <span class="chat-header-name">{{ currentConversation.name }}</span>
            <span class="online-dot" :class="currentConversation.online ? 'is-online' : 'is-offline'" />
            <span class="online-text">{{ currentConversation.online ? '在线' : '离线' }}</span>
          </div>
        </div>

        <!-- Message Area -->
        <el-scrollbar ref="messageScrollbar" class="chat-messages" @scroll="handleScroll">
          <div ref="messageListRef" class="message-list">
            <div v-if="loadingMore" class="loading-more">加载中...</div>
            <div
              v-for="msg in messages"
              :key="msg.id"
              class="message-row"
              :class="msg.senderId === currentUserId ? 'is-self' : 'is-other'"
            >
              <el-avatar :size="36" :src="msg.senderAvatar" class="msg-avatar">
                {{ msg.senderName?.charAt(0) || '?' }}
              </el-avatar>
              <div class="msg-body">
                <div v-if="msg.type === 'image'" class="msg-bubble msg-image">
                  <el-image
                    :src="msg.content"
                    :preview-src-list="[msg.content]"
                    fit="cover"
                    class="chat-image-thumb"
                    :z-index="3000"
                  />
                </div>
                <div v-else class="msg-bubble msg-text">{{ msg.content }}</div>
                <span class="msg-time">{{ formatMessageTime(msg.createdAt) }}</span>
              </div>
            </div>
            <div v-if="peerTyping" class="typing-indicator">
              <span>对方正在输入</span>
              <span class="typing-dots"><i /><i /><i /></span>
            </div>
          </div>
        </el-scrollbar>

        <!-- Input Area -->
        <div class="chat-input-area">
          <div class="input-toolbar">
            <el-upload
              :show-file-list="false"
              :before-upload="handleBeforeUpload"
              :http-request="handleImageUpload"
              accept="image/*"
            >
              <el-button :icon="Picture" circle size="small" title="发送图片" />
            </el-upload>
          </div>
          <div class="input-row">
            <el-input
              v-model="inputMessage"
              type="textarea"
              :autosize="{ minRows: 1, maxRows: 4 }"
              placeholder="输入消息..."
              resize="none"
              @keydown="handleInputKeydown as any"
            />
            <el-button type="primary" :disabled="!inputMessage.trim()" @click="sendMessage" class="send-btn">
              发送
            </el-button>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted, onUnmounted, nextTick } from "vue";
import { ChatDotRound, Picture, Search } from "@element-plus/icons-vue";
import { ElMessage } from "element-plus";
import { useUserStore } from "@/store/modules/user";
import { TOKEN_KEY } from "@/enums/CacheEnum";
import {
  getConversations,
  getMessages,
  sendChatMessage,
  markConversationRead,
  uploadChatImage,
  getUnreadCount,
} from "@/api/chat";

// ─── Types ───────────────────────────────────────────────────────────────────
interface Conversation {
  id: string;
  name: string;
  avatar: string;
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
  online: boolean;
}

interface Message {
  id: string;
  conversationId: string;
  senderId: number;
  senderName: string;
  senderAvatar: string;
  content: string;
  type: "text" | "image";
  createdAt: string;
}

// ─── Store & User ────────────────────────────────────────────────────────────
const userStore = useUserStore();
const currentUserId = computed(() => userStore.user.refId ?? userStore.user.accountId ?? 0);

// ─── State ───────────────────────────────────────────────────────────────────
const searchKeyword = ref("");
const conversations = ref<Conversation[]>([]);
const currentConversation = ref<Conversation | null>(null);
const messages = ref<Message[]>([]);
const inputMessage = ref("");
const peerTyping = ref(false);
const loadingMore = ref(false);
const currentPage = ref(1);
const hasMore = ref(true);
const totalUnread = ref(0);

// Refs for scroll
const messageScrollbar = ref<any>(null);
const messageListRef = ref<HTMLDivElement | null>(null);

// WebSocket
let ws: WebSocket | null = null;
let reconnectTimer: ReturnType<typeof setTimeout> | null = null;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 10;
let typingTimer: ReturnType<typeof setTimeout> | null = null;
let peerTypingTimer: ReturnType<typeof setTimeout> | null = null;

// ─── Computed ────────────────────────────────────────────────────────────────
const filteredConversations = computed(() => {
  if (!searchKeyword.value.trim()) return conversations.value;
  const kw = searchKeyword.value.toLowerCase();
  return conversations.value.filter((c) =>
    c.name.toLowerCase().includes(kw)
  );
});

// ─── Time Formatting ─────────────────────────────────────────────────────────
function formatTime(dateStr: string): string {
  if (!dateStr) return "";
  const date = new Date(dateStr);
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today.getTime() - 86400000);
  const msgDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());

  if (msgDay.getTime() === today.getTime()) {
    return `${padZero(date.getHours())}:${padZero(date.getMinutes())}`;
  }
  if (msgDay.getTime() === yesterday.getTime()) {
    return "昨天";
  }
  return `${date.getMonth() + 1}/${date.getDate()}`;
}

function formatMessageTime(dateStr: string): string {
  if (!dateStr) return "";
  const date = new Date(dateStr);
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const yesterday = new Date(today.getTime() - 86400000);
  const msgDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());

  const time = `${padZero(date.getHours())}:${padZero(date.getMinutes())}`;
  if (msgDay.getTime() === today.getTime()) return `今天 ${time}`;
  if (msgDay.getTime() === yesterday.getTime()) return `昨天 ${time}`;
  return `${date.getMonth() + 1}月${date.getDate()}日 ${time}`;
}

function padZero(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

// ─── API Calls ───────────────────────────────────────────────────────────────
async function loadConversations() {
  try {
    const res: any = await getConversations();
    const list = Array.isArray(res) ? res : res?.data ?? res?.list ?? [];
    // 将后端返回的数据映射为前端 Conversation 格式
    conversations.value = list.map((item: any) => ({
      id: String(item.id),
      name: item.targetName || item.name || "未知",
      avatar: item.targetAvatar || item.avatar || "",
      lastMessage: item.lastMessage || "",
      lastMessageTime: item.lastMessageTime || "",
      unreadCount: item.unreadCount || 0,
      online: false,
    }));
  } catch (e) {
    console.error("Failed to load conversations", e);
  }
}

async function loadMessages(conversationId: string, page = 1) {
  try {
    loadingMore.value = true;
    const res: any = await getMessages(conversationId, { current: page, size: 30 });
    // Spring Boot PageResult: { records: [], total, current, size }
    const rawList = res?.records ?? res?.data?.records ?? res?.data ?? [];
    // 映射为前端 Message 格式
    const list: Message[] = rawList.map((item: any) => ({
      id: String(item.id),
      conversationId: String(item.conversationId),
      senderId: item.senderId,
      senderName: item.senderName || "",
      senderAvatar: "",
      content: item.content,
      type: item.msgType || "text",
      createdAt: item.createTime || "",
    }));
    // 消息按时间倒序返回，翻转为正序
    list.reverse();
    hasMore.value = rawList.length >= 30;
    if (page === 1) {
      messages.value = list;
      await nextTick();
      scrollToBottom();
    } else {
      // Prepend older messages
      const oldHeight = messageListRef.value?.scrollHeight ?? 0;
      messages.value = [...list, ...messages.value];
      await nextTick();
      // Maintain scroll position
      const newHeight = messageListRef.value?.scrollHeight ?? 0;
      if (messageScrollbar.value) {
        messageScrollbar.value.setScrollTop(newHeight - oldHeight);
      }
    }
  } catch (e) {
    console.error("Failed to load messages", e);
  } finally {
    loadingMore.value = false;
  }
}

async function loadUnreadCount() {
  try {
    const res: any = await getUnreadCount();
    totalUnread.value = res?.totalUnread ?? res?.count ?? 0;
  } catch {
    // ignore
  }
}

// ─── Conversation Selection ──────────────────────────────────────────────────
function selectConversation(conv: Conversation) {
  if (currentConversation.value?.id === conv.id) return;
  currentConversation.value = conv;
  currentPage.value = 1;
  hasMore.value = true;
  messages.value = [];
  loadMessages(conv.id, 1);

  // 标记已读 (REST API + WebSocket)
  markConversationRead(conv.id).catch(() => {});
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type: "read", conversationId: conv.id }));
  }
  conv.unreadCount = 0;
  recalcUnread();
}

function recalcUnread() {
  totalUnread.value = conversations.value.reduce((s, c) => s + (c.unreadCount || 0), 0);
}

// ─── Scroll ──────────────────────────────────────────────────────────────────
function scrollToBottom() {
  nextTick(() => {
    if (messageScrollbar.value) {
      const el = messageListRef.value;
      if (el) {
        messageScrollbar.value.setScrollTop(el.scrollHeight);
      }
    }
  });
}

function handleScroll({ scrollTop }: { scrollTop: number }) {
  if (scrollTop < 50 && !loadingMore.value && hasMore.value && currentConversation.value) {
    currentPage.value++;
    loadMessages(currentConversation.value.id, currentPage.value);
  }
}

// ─── Send Message ────────────────────────────────────────────────────────────
async function sendMessage() {
  const text = inputMessage.value.trim();
  if (!text || !currentConversation.value) return;
  inputMessage.value = "";
  await doSendMessage(text, "text");
}

async function doSendMessage(content: string, msgType: "text" | "image") {
  if (!currentConversation.value) return;

  // 乐观添加消息到 UI
  const tempMsg: Message = {
    id: `temp-${Date.now()}`,
    conversationId: currentConversation.value.id,
    senderId: currentUserId.value,
    senderName: userStore.user.realName || "我",
    senderAvatar: userStore.user.avatar || "",
    content,
    type: msgType,
    createdAt: new Date().toISOString(),
  };
  messages.value.push(tempMsg);
  updateConversationPreview(tempMsg);
  scrollToBottom();

  try {
    // 通过 REST API 发送消息 (后端会通过 WebSocket 推送给对方)
    const res: any = await sendChatMessage({
      conversationId: Number(currentConversation.value.id),
      content,
      msgType,
    });
    // 用服务端返回的真实消息替换临时消息
    if (res?.id) {
      const idx = messages.value.findIndex((m) => m.id === tempMsg.id);
      if (idx !== -1) {
        messages.value[idx] = {
          ...tempMsg,
          id: String(res.id),
          createdAt: res.createTime || tempMsg.createdAt,
        };
      }
    }
  } catch (e) {
    ElMessage.error("发送失败，请重试");
    const idx = messages.value.findIndex((m) => m.id === tempMsg.id);
    if (idx !== -1) messages.value.splice(idx, 1);
  }
}

function updateConversationPreview(msg: Message) {
  const conv = conversations.value.find((c) => c.id === msg.conversationId);
  if (conv) {
    conv.lastMessage = msg.type === "image" ? "[图片]" : msg.content;
    conv.lastMessageTime = msg.createdAt;
    // Move to top
    const idx = conversations.value.indexOf(conv);
    if (idx > 0) {
      conversations.value.splice(idx, 1);
      conversations.value.unshift(conv);
    }
  }
}

// ─── Keyboard ────────────────────────────────────────────────────────────────
function handleInputKeydown(e: KeyboardEvent) {
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    sendMessage();
  }
  // Typing indicator
  sendTypingIndicator();
}

function sendTypingIndicator() {
  if (!ws || ws.readyState !== WebSocket.OPEN || !currentConversation.value) return;
  if (typingTimer) return; // throttle
  ws.send(
    JSON.stringify({ type: "typing", conversationId: currentConversation.value.id })
  );
  typingTimer = setTimeout(() => {
    typingTimer = null;
  }, 3000);
}

// ─── Image Upload ────────────────────────────────────────────────────────────
function handleBeforeUpload(file: File): boolean {
  const isImage = file.type.startsWith("image/");
  if (!isImage) {
    ElMessage.error("只能上传图片文件");
    return false;
  }
  if (file.size > 10 * 1024 * 1024) {
    ElMessage.error("图片大小不能超过 10MB");
    return false;
  }
  return true;
}

async function handleImageUpload({ file }: { file: File }) {
  try {
    const fd = new FormData();
    fd.append("file", file);
    const res: any = await uploadChatImage(fd);
    const url = res?.url ?? res?.data?.url ?? res;
    if (typeof url === "string" && url) {
      await doSendMessage(url, "image");
    } else {
      ElMessage.error("上传失败");
    }
  } catch {
    ElMessage.error("图片上传失败");
  }
}

// ─── WebSocket ───────────────────────────────────────────────────────────────
function connectWebSocket() {
  const raw = localStorage.getItem(TOKEN_KEY) || "";
  const token = raw.startsWith("Bearer ") ? raw.slice(7) : raw;
  if (!token) return;

  const wsUrl = `ws://${window.location.hostname}:8080/api/v1/ws/chat?token=${encodeURIComponent(token)}`;
  ws = new WebSocket(wsUrl);

  ws.onopen = () => {
    console.log("[Chat WS] Connected");
    reconnectAttempts = 0;
  };

  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      handleWsMessage(data);
    } catch (e) {
      console.warn("[Chat WS] Parse error", e);
    }
  };

  ws.onclose = () => {
    console.log("[Chat WS] Disconnected");
    scheduleReconnect();
  };

  ws.onerror = (err) => {
    console.error("[Chat WS] Error", err);
  };
}

function handleWsMessage(data: any) {
  switch (data.type) {
    case "new_message": {
      const d = data.data || data;
      const msg: Message = {
        id: String(d.id || `ws-${Date.now()}`),
        conversationId: String(d.conversationId),
        senderId: d.senderId,
        senderName: d.senderName || "",
        senderAvatar: "",
        content: d.content,
        type: d.msgType || "text",
        createdAt: d.createTime || new Date().toISOString(),
      };

      // If it belongs to the current open conversation
      if (currentConversation.value?.id === msg.conversationId) {
        // Avoid duplicate from optimistic add
        if (msg.senderId !== currentUserId.value) {
          messages.value.push(msg);
          scrollToBottom();
          // Auto mark read
          if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: "read", conversationId: msg.conversationId }));
          }
        }
      } else {
        // Increment unread for that conversation
        const conv = conversations.value.find((c) => c.id === msg.conversationId);
        if (conv) {
          conv.unreadCount = (conv.unreadCount || 0) + 1;
        }
      }
      updateConversationPreview(msg);
      recalcUnread();
      peerTyping.value = false;
      break;
    }
    case "typing": {
      if (
        data.conversationId === currentConversation.value?.id &&
        data.senderId !== currentUserId.value
      ) {
        peerTyping.value = true;
        if (peerTypingTimer) clearTimeout(peerTypingTimer);
        peerTypingTimer = setTimeout(() => {
          peerTyping.value = false;
        }, 4000);
      }
      break;
    }
    case "messages_read":
    case "read": {
      // Could update message read status here
      break;
    }
    case "online_status": {
      const conv = conversations.value.find((c) => c.id === data.conversationId);
      if (conv) conv.online = !!data.online;
      if (currentConversation.value && currentConversation.value.id === data.conversationId) {
        (currentConversation.value as any).online = !!data.online;
      }
      break;
    }
    default:
      break;
  }
}

function scheduleReconnect() {
  if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    console.warn("[Chat WS] Max reconnect attempts reached");
    return;
  }
  const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 30000);
  reconnectAttempts++;
  reconnectTimer = setTimeout(() => {
    connectWebSocket();
  }, delay);
}

function disconnectWebSocket() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
  reconnectAttempts = MAX_RECONNECT_ATTEMPTS; // prevent reconnect
  if (ws) {
    ws.onclose = null;
    ws.close();
    ws = null;
  }
}

// ─── Lifecycle ───────────────────────────────────────────────────────────────
onMounted(() => {
  loadConversations();
  loadUnreadCount();
  connectWebSocket();
});

onUnmounted(() => {
  disconnectWebSocket();
  if (typingTimer) clearTimeout(typingTimer);
  if (peerTypingTimer) clearTimeout(peerTypingTimer);
});
</script>

<style scoped>
/* ─── Layout ─────────────────────────────────────────────────────────────── */
.chat-container {
  display: flex;
  height: calc(100vh - 120px);
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
  overflow: hidden;
}

/* ─── Sidebar ────────────────────────────────────────────────────────────── */
.chat-sidebar {
  width: 300px;
  min-width: 300px;
  border-right: 1px solid #e8eaed;
  display: flex;
  flex-direction: column;
  background: #fafbfc;
}

.sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px 12px;
  border-bottom: 1px solid #e8eaed;
}

.sidebar-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #1a1a1a;
}

.unread-badge {
  line-height: 1;
}

.sidebar-search {
  padding: 12px 16px;
}

.conversation-list {
  flex: 1;
  overflow: hidden;
}

.conversation-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  cursor: pointer;
  transition: background 0.2s;
  border-bottom: 1px solid #f0f1f3;
}

.conversation-item:hover {
  background: #edf2fe;
}

.conversation-item.active {
  background: #e0e9fd;
}

.conv-avatar {
  flex-shrink: 0;
  margin-right: 12px;
  background: #1d4ed8;
  color: #fff;
  font-size: 16px;
}

.conv-info {
  flex: 1;
  min-width: 0;
}

.conv-top-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.conv-name {
  font-size: 14px;
  font-weight: 500;
  color: #1a1a1a;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.conv-time {
  font-size: 12px;
  color: #999;
  flex-shrink: 0;
  margin-left: 8px;
}

.conv-bottom-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.conv-preview {
  font-size: 13px;
  color: #888;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  flex: 1;
}

.conv-unread {
  flex-shrink: 0;
  margin-left: 8px;
}

.no-conversations {
  text-align: center;
  padding: 40px 16px;
  color: #aaa;
  font-size: 14px;
}

/* ─── Main Chat Area ─────────────────────────────────────────────────────── */
.chat-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  background: #f7f8fa;
}

.chat-empty {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ─── Chat Header ────────────────────────────────────────────────────────── */
.chat-header {
  padding: 14px 24px;
  background: #fff;
  border-bottom: 1px solid #e8eaed;
  display: flex;
  align-items: center;
}

.chat-header-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.chat-header-name {
  font-size: 16px;
  font-weight: 600;
  color: #1a1a1a;
}

.online-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

.online-dot.is-online {
  background: #22c55e;
  box-shadow: 0 0 4px rgba(34, 197, 94, 0.5);
}

.online-dot.is-offline {
  background: #ccc;
}

.online-text {
  font-size: 12px;
  color: #888;
}

/* ─── Messages ───────────────────────────────────────────────────────────── */
.chat-messages {
  flex: 1;
  overflow: hidden;
}

.message-list {
  padding: 16px 24px;
  min-height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
}

.loading-more {
  text-align: center;
  padding: 12px 0;
  color: #aaa;
  font-size: 13px;
}

.message-row {
  display: flex;
  align-items: flex-start;
  margin-bottom: 16px;
  max-width: 80%;
}

.message-row.is-other {
  align-self: flex-start;
}

.message-row.is-self {
  align-self: flex-end;
  flex-direction: row-reverse;
}

.msg-avatar {
  flex-shrink: 0;
  background: #1d4ed8;
  color: #fff;
  font-size: 14px;
}

.is-other .msg-avatar {
  margin-right: 10px;
}

.is-self .msg-avatar {
  margin-left: 10px;
}

.msg-body {
  display: flex;
  flex-direction: column;
}

.is-self .msg-body {
  align-items: flex-end;
}

.msg-bubble {
  padding: 10px 14px;
  border-radius: 12px;
  font-size: 14px;
  line-height: 1.6;
  word-break: break-word;
  max-width: 400px;
}

.is-other .msg-bubble.msg-text {
  background: #fff;
  color: #1a1a1a;
  border: 1px solid #e8eaed;
  border-top-left-radius: 2px;
}

.is-self .msg-bubble.msg-text {
  background: #1d4ed8;
  color: #fff;
  border-top-right-radius: 2px;
}

.msg-image {
  padding: 4px;
  background: #fff;
  border: 1px solid #e8eaed;
}

.chat-image-thumb {
  width: 200px;
  max-height: 200px;
  border-radius: 8px;
  cursor: pointer;
  display: block;
}

.msg-time {
  font-size: 11px;
  color: #aaa;
  margin-top: 4px;
}

/* ─── Typing Indicator ───────────────────────────────────────────────────── */
.typing-indicator {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 0;
  color: #888;
  font-size: 13px;
}

.typing-dots {
  display: inline-flex;
  gap: 3px;
}

.typing-dots i {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #aaa;
  display: inline-block;
  animation: typingBounce 1.4s infinite ease-in-out both;
}

.typing-dots i:nth-child(1) { animation-delay: 0s; }
.typing-dots i:nth-child(2) { animation-delay: 0.2s; }
.typing-dots i:nth-child(3) { animation-delay: 0.4s; }

@keyframes typingBounce {
  0%, 80%, 100% { transform: scale(0.6); opacity: 0.4; }
  40% { transform: scale(1); opacity: 1; }
}

/* ─── Input Area ─────────────────────────────────────────────────────────── */
.chat-input-area {
  background: #fff;
  border-top: 1px solid #e8eaed;
  padding: 12px 24px 16px;
}

.input-toolbar {
  margin-bottom: 8px;
}

.input-row {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}

.input-row :deep(.el-textarea__inner) {
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 14px;
  box-shadow: none;
}

.send-btn {
  height: 36px;
  min-width: 72px;
  border-radius: 8px;
  background: #1d4ed8;
  border-color: #1d4ed8;
  font-weight: 500;
}

.send-btn:hover {
  background: #1e40af;
  border-color: #1e40af;
}
</style>
