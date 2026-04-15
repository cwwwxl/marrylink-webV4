package com.marrylink.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.marrylink.common.PageResult;
import com.marrylink.common.Result;
import com.marrylink.entity.ChatConversation;
import com.marrylink.entity.ChatMessage;
import com.marrylink.service.IChatConversationService;
import com.marrylink.service.IChatMessageService;
import com.marrylink.utils.SecurityUtils;
import com.marrylink.websocket.ChatWebSocketHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import java.io.File;
import java.io.IOException;
import java.util.*;

@Slf4j
@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatController {

    @Resource
    private IChatConversationService conversationService;

    @Resource
    private IChatMessageService messageService;

    @Resource
    private ChatWebSocketHandler webSocketHandler;

    /**
     * 获取当前用户的会话列表
     */
    @GetMapping("/conversations")
    public Result<List<Map<String, Object>>> getConversations() {
        Long refId = SecurityUtils.getCurrentRefId();
        String userType = SecurityUtils.getCurrentUserType().getCode();
        List<Map<String, Object>> list = conversationService.getConversationList(refId, userType);
        return Result.ok(list);
    }

    /**
     * 获取会话的消息历史 (分页)
     */
    @GetMapping("/conversations/{conversationId}/messages")
    public Result<PageResult<ChatMessage>> getMessages(
            @PathVariable Long conversationId,
            @RequestParam(defaultValue = "1") Integer current,
            @RequestParam(defaultValue = "20") Integer size) {

        // Verify the user is a participant
        Long refId = SecurityUtils.getCurrentRefId();
        String userType = SecurityUtils.getCurrentUserType().getCode();
        ChatConversation conv = conversationService.getById(conversationId);
        if (conv == null) {
            return Result.error("B0001", "会话不存在");
        }
        boolean isParticipant = (refId.equals(conv.getCustomerId()) && "CUSTOMER".equals(userType))
                || (refId.equals(conv.getHostId()) && !"CUSTOMER".equals(userType));
        if (!isParticipant) {
            return Result.error("B0001", "无权访问此会话");
        }

        Page<ChatMessage> page = new Page<>(current, size);
        LambdaQueryWrapper<ChatMessage> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ChatMessage::getConversationId, conversationId)
               .orderByDesc(ChatMessage::getCreateTime);
        messageService.page(page, wrapper);

        return Result.ok(PageResult.of(page));
    }

    /**
     * 创建或获取会话
     * Body: { "targetId": 123, "targetType": "HOST" }
     */
    @PostMapping("/conversations")
    public Result<ChatConversation> createConversation(@RequestBody Map<String, Object> body) {
        Long targetId = Long.valueOf(body.get("targetId").toString());
        String targetType = body.get("targetType").toString();

        Long refId = SecurityUtils.getCurrentRefId();
        String userType = SecurityUtils.getCurrentUserType().getCode();

        Long customerId, hostId;
        if ("CUSTOMER".equals(userType)) {
            customerId = refId;
            hostId = targetId;
        } else {
            customerId = targetId;
            hostId = refId;
        }

        ChatConversation conversation = conversationService.getOrCreateConversation(customerId, hostId);
        return Result.ok(conversation);
    }

    /**
     * 发送消息
     * Body: { "conversationId": 1, "content": "hello", "msgType": "text" }
     */
    @PostMapping("/messages")
    public Result<ChatMessage> sendMessage(@RequestBody Map<String, Object> body) {
        Long conversationId = Long.valueOf(body.get("conversationId").toString());
        String content = body.get("content").toString();
        String msgType = body.getOrDefault("msgType", "text").toString();

        Long refId = SecurityUtils.getCurrentRefId();
        String userType = SecurityUtils.getCurrentUserType().getCode();
        String realName = SecurityUtils.getCurrentRealName();

        // Verify participant
        ChatConversation conv = conversationService.getById(conversationId);
        if (conv == null) {
            return Result.error("B0001", "会话不存在");
        }

        ChatMessage message = messageService.sendMessage(conversationId, refId, userType, realName, content, msgType);

        // Notify via WebSocket
        try {
            Long recipientId;
            String recipientType;
            if ("CUSTOMER".equals(userType)) {
                recipientId = conv.getHostId();
                recipientType = "HOST";
            } else {
                recipientId = conv.getCustomerId();
                recipientType = "CUSTOMER";
            }
            webSocketHandler.sendToUser(recipientId, recipientType, message);
        } catch (Exception e) {
            log.warn("WebSocket通知失败: {}", e.getMessage());
        }

        return Result.ok(message);
    }

    /**
     * 标记会话消息为已读
     */
    @PostMapping("/conversations/{conversationId}/read")
    public Result<Void> markAsRead(@PathVariable Long conversationId) {
        Long refId = SecurityUtils.getCurrentRefId();
        String userType = SecurityUtils.getCurrentUserType().getCode();
        messageService.markAsRead(conversationId, refId, userType);
        return Result.ok();
    }

    /**
     * 获取未读消息总数
     */
    @GetMapping("/unread-count")
    public Result<Map<String, Object>> getUnreadCount() {
        Long refId = SecurityUtils.getCurrentRefId();
        String userType = SecurityUtils.getCurrentUserType().getCode();
        int count = conversationService.getTotalUnreadCount(refId, userType);
        Map<String, Object> data = new HashMap<>();
        data.put("totalUnread", count);
        return Result.ok(data);
    }

    /**
     * 上传聊天图片
     */
    @PostMapping("/upload")
    public Result<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            return Result.error("B0001", "文件不能为空");
        }

        String originalFilename = file.getOriginalFilename();
        String ext = originalFilename != null && originalFilename.contains(".")
                ? originalFilename.substring(originalFilename.lastIndexOf("."))
                : ".jpg";
        String filename = UUID.randomUUID().toString() + ext;

        String uploadDir = System.getProperty("user.dir") + "/marrylink-admin/uploads/chat/";
        File dir = new File(uploadDir);
        if (!dir.exists()) {
            dir.mkdirs();
        }

        File dest = new File(uploadDir + filename);
        file.transferTo(dest);

        Map<String, String> data = new HashMap<>();
        data.put("url", "/uploads/chat/" + filename);
        return Result.ok(data);
    }
}
