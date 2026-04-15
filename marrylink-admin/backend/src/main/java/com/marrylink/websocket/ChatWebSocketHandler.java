package com.marrylink.websocket;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.marrylink.entity.ChatMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    // Key: "userType:refId" e.g. "HOST:100" or "CUSTOMER:200"
    private static final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Map<String, Object> attrs = session.getAttributes();
        Long refId = (Long) attrs.get("refId");
        String userType = (String) attrs.get("userType");

        if (refId != null && userType != null) {
            String key = userType + ":" + refId;
            // Close old session if exists
            WebSocketSession oldSession = sessions.put(key, session);
            if (oldSession != null && oldSession.isOpen()) {
                try { oldSession.close(); } catch (Exception ignored) {}
            }
            log.info("[WebSocket] 用户连接: {} (sessionId={})", key, session.getId());
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        Map<String, Object> attrs = session.getAttributes();
        Long refId = (Long) attrs.get("refId");
        String userType = (String) attrs.get("userType");

        try {
            JSONObject json = JSONUtil.parseObj(message.getPayload());
            String type = json.getStr("type");

            if ("ping".equals(type)) {
                session.sendMessage(new TextMessage("{\"type\":\"pong\"}"));
                return;
            }

            if ("typing".equals(type)) {
                Long conversationId = json.getLong("conversationId");
                // Forward typing indicator to the other party
                JSONObject typingMsg = new JSONObject();
                typingMsg.set("type", "typing");
                typingMsg.set("conversationId", conversationId);
                typingMsg.set("senderId", refId);
                typingMsg.set("senderType", userType);
                broadcastToConversationPartner(session, conversationId, typingMsg.toString());
            }

            if ("read".equals(type)) {
                Long conversationId = json.getLong("conversationId");
                JSONObject readMsg = new JSONObject();
                readMsg.set("type", "messages_read");
                readMsg.set("conversationId", conversationId);
                readMsg.set("readerId", refId);
                readMsg.set("readerType", userType);
                broadcastToConversationPartner(session, conversationId, readMsg.toString());
            }
        } catch (Exception e) {
            log.error("[WebSocket] 处理消息错误: {}", e.getMessage());
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Map<String, Object> attrs = session.getAttributes();
        Long refId = (Long) attrs.get("refId");
        String userType = (String) attrs.get("userType");

        if (refId != null && userType != null) {
            String key = userType + ":" + refId;
            sessions.remove(key, session);
            log.info("[WebSocket] 用户断开: {} (sessionId={})", key, session.getId());
        }
    }

    /**
     * Send a message to a specific user
     */
    public void sendToUser(Long refId, String userType, ChatMessage chatMessage) {
        String key = userType + ":" + refId;
        WebSocketSession session = sessions.get(key);
        if (session != null && session.isOpen()) {
            try {
                JSONObject json = new JSONObject();
                json.set("type", "new_message");
                JSONObject data = new JSONObject();
                data.set("id", chatMessage.getId());
                data.set("conversationId", chatMessage.getConversationId());
                data.set("senderId", chatMessage.getSenderId());
                data.set("senderType", chatMessage.getSenderType());
                data.set("senderName", chatMessage.getSenderName());
                data.set("content", chatMessage.getContent());
                data.set("msgType", chatMessage.getMsgType());
                data.set("createTime", chatMessage.getCreateTime() != null ? chatMessage.getCreateTime().toString() : null);
                json.set("data", data);

                session.sendMessage(new TextMessage(json.toString()));
                log.info("[WebSocket] 发送消息给 {}: msgId={}", key, chatMessage.getId());
            } catch (IOException e) {
                log.error("[WebSocket] 发送消息失败: {}", e.getMessage());
            }
        } else {
            log.debug("[WebSocket] 用户 {} 不在线，消息将通过拉取获取", key);
        }
    }

    /**
     * Broadcast to conversation partner (for typing/read notifications)
     */
    private void broadcastToConversationPartner(WebSocketSession senderSession, Long conversationId, String message) {
        Map<String, Object> senderAttrs = senderSession.getAttributes();
        String senderKey = senderAttrs.get("userType") + ":" + senderAttrs.get("refId");

        // Find the partner session - iterate and check
        for (Map.Entry<String, WebSocketSession> entry : sessions.entrySet()) {
            if (!entry.getKey().equals(senderKey) && entry.getValue().isOpen()) {
                try {
                    entry.getValue().sendMessage(new TextMessage(message));
                } catch (IOException e) {
                    log.error("[WebSocket] 广播消息失败: {}", e.getMessage());
                }
            }
        }
    }
}
