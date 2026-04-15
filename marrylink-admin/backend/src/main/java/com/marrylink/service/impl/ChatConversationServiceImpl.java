package com.marrylink.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.marrylink.entity.ChatConversation;
import com.marrylink.entity.Host;
import com.marrylink.entity.User;
import com.marrylink.mapper.ChatConversationMapper;
import com.marrylink.mapper.HostMapper;
import com.marrylink.mapper.UserMapper;
import com.marrylink.service.IChatConversationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatConversationServiceImpl extends ServiceImpl<ChatConversationMapper, ChatConversation> implements IChatConversationService {

    @Resource
    private UserMapper userMapper;

    @Resource
    private HostMapper hostMapper;

    @Override
    public List<Map<String, Object>> getConversationList(Long refId, String userType) {
        LambdaQueryWrapper<ChatConversation> wrapper = new LambdaQueryWrapper<>();
        if ("CUSTOMER".equals(userType)) {
            wrapper.eq(ChatConversation::getCustomerId, refId);
        } else {
            wrapper.eq(ChatConversation::getHostId, refId);
        }
        wrapper.eq(ChatConversation::getStatus, 1)
               .orderByDesc(ChatConversation::getLastMessageTime);

        List<ChatConversation> conversations = this.list(wrapper);
        List<Map<String, Object>> result = new ArrayList<>();

        for (ChatConversation conv : conversations) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", conv.getId());
            item.put("lastMessage", conv.getLastMessage());
            item.put("lastMessageTime", conv.getLastMessageTime());

            if ("CUSTOMER".equals(userType)) {
                // Customer sees host info
                item.put("unreadCount", conv.getCustomerUnread());
                Host host = hostMapper.selectById(conv.getHostId());
                if (host != null) {
                    item.put("targetName", host.getName());
                    item.put("targetAvatar", host.getAvatar());
                    item.put("targetId", host.getId());
                    item.put("targetType", "HOST");
                } else {
                    item.put("targetName", "未知主持人");
                    item.put("targetAvatar", "");
                    item.put("targetId", conv.getHostId());
                    item.put("targetType", "HOST");
                }
            } else {
                // Host sees customer info
                item.put("unreadCount", conv.getHostUnread());
                User user = userMapper.selectById(conv.getCustomerId());
                if (user != null) {
                    item.put("targetName", user.getBrideName() + " & " + user.getGroomName());
                    item.put("targetAvatar", user.getAvatar());
                    item.put("targetId", user.getId());
                    item.put("targetType", "CUSTOMER");
                } else {
                    item.put("targetName", "未知用户");
                    item.put("targetAvatar", "");
                    item.put("targetId", conv.getCustomerId());
                    item.put("targetType", "CUSTOMER");
                }
            }
            result.add(item);
        }
        return result;
    }

    @Override
    public ChatConversation getOrCreateConversation(Long customerId, Long hostId) {
        LambdaQueryWrapper<ChatConversation> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ChatConversation::getCustomerId, customerId)
               .eq(ChatConversation::getHostId, hostId)
               .eq(ChatConversation::getIsDeleted, 0);

        ChatConversation conversation = this.getOne(wrapper);
        if (conversation == null) {
            conversation = new ChatConversation();
            conversation.setCustomerId(customerId);
            conversation.setHostId(hostId);
            conversation.setCustomerUnread(0);
            conversation.setHostUnread(0);
            conversation.setStatus(1);
            conversation.setLastMessage("");
            this.save(conversation);
        }
        return conversation;
    }

    @Override
    public int getTotalUnreadCount(Long refId, String userType) {
        LambdaQueryWrapper<ChatConversation> wrapper = new LambdaQueryWrapper<>();
        if ("CUSTOMER".equals(userType)) {
            wrapper.eq(ChatConversation::getCustomerId, refId);
        } else {
            wrapper.eq(ChatConversation::getHostId, refId);
        }
        wrapper.eq(ChatConversation::getStatus, 1);

        List<ChatConversation> conversations = this.list(wrapper);
        int total = 0;
        for (ChatConversation conv : conversations) {
            if ("CUSTOMER".equals(userType)) {
                total += (conv.getCustomerUnread() != null ? conv.getCustomerUnread() : 0);
            } else {
                total += (conv.getHostUnread() != null ? conv.getHostUnread() : 0);
            }
        }
        return total;
    }
}
