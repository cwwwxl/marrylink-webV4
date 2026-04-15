package com.marrylink.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.marrylink.entity.ChatConversation;
import com.marrylink.entity.ChatMessage;
import com.marrylink.mapper.ChatMessageMapper;
import com.marrylink.service.IChatConversationService;
import com.marrylink.service.IChatMessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatMessageServiceImpl extends ServiceImpl<ChatMessageMapper, ChatMessage> implements IChatMessageService {

    @Resource
    private IChatConversationService conversationService;

    @Override
    @Transactional
    public ChatMessage sendMessage(Long conversationId, Long senderId, String senderType, String senderName, String content, String msgType) {
        // 1. Save message
        ChatMessage message = new ChatMessage();
        message.setConversationId(conversationId);
        message.setSenderId(senderId);
        message.setSenderType(senderType);
        message.setSenderName(senderName);
        message.setContent(content);
        message.setMsgType(msgType != null ? msgType : "text");
        message.setIsRead(0);
        this.save(message);

        // 2. Update conversation
        ChatConversation conversation = conversationService.getById(conversationId);
        if (conversation != null) {
            String preview = "image".equals(msgType) ? "[图片]" :
                (content.length() > 50 ? content.substring(0, 50) + "..." : content);
            conversation.setLastMessage(preview);
            conversation.setLastMessageTime(LocalDateTime.now());

            // Increment unread count for the OTHER party
            if ("CUSTOMER".equals(senderType)) {
                conversation.setHostUnread(
                    (conversation.getHostUnread() != null ? conversation.getHostUnread() : 0) + 1
                );
            } else {
                conversation.setCustomerUnread(
                    (conversation.getCustomerUnread() != null ? conversation.getCustomerUnread() : 0) + 1
                );
            }
            conversationService.updateById(conversation);
        }

        return message;
    }

    @Override
    @Transactional
    public void markAsRead(Long conversationId, Long readerId, String readerType) {
        // 1. Mark all unread messages in this conversation as read (messages sent by the OTHER party)
        LambdaUpdateWrapper<ChatMessage> msgWrapper = new LambdaUpdateWrapper<>();
        msgWrapper.eq(ChatMessage::getConversationId, conversationId)
                  .ne(ChatMessage::getSenderType, readerType)
                  .eq(ChatMessage::getIsRead, 0)
                  .set(ChatMessage::getIsRead, 1);
        this.update(msgWrapper);

        // 2. Reset unread count for this user in conversation
        ChatConversation conversation = conversationService.getById(conversationId);
        if (conversation != null) {
            if ("CUSTOMER".equals(readerType)) {
                conversation.setCustomerUnread(0);
            } else {
                conversation.setHostUnread(0);
            }
            conversationService.updateById(conversation);
        }
    }
}
