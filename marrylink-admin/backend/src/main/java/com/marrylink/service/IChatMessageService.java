package com.marrylink.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.marrylink.entity.ChatMessage;

public interface IChatMessageService extends IService<ChatMessage> {

    /**
     * 发送消息并更新会话
     */
    ChatMessage sendMessage(Long conversationId, Long senderId, String senderType, String senderName, String content, String msgType);

    /**
     * 标记会话中的消息为已读
     */
    void markAsRead(Long conversationId, Long readerId, String readerType);
}
