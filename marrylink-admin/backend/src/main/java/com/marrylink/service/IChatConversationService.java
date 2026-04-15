package com.marrylink.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.marrylink.entity.ChatConversation;

import java.util.List;
import java.util.Map;

public interface IChatConversationService extends IService<ChatConversation> {

    /**
     * 获取当前用户的会话列表
     */
    List<Map<String, Object>> getConversationList(Long refId, String userType);

    /**
     * 创建或获取已有会话
     */
    ChatConversation getOrCreateConversation(Long customerId, Long hostId);

    /**
     * 获取当前用户的总未读数
     */
    int getTotalUnreadCount(Long refId, String userType);
}
