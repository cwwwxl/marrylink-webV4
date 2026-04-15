package com.marrylink.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 聊天会话实体
 */
@Data
@TableName("chat_conversation")
public class ChatConversation {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 新人用户ID */
    private Long customerId;

    /** 主持人ID */
    private Long hostId;

    /** 最后一条消息内容预览 */
    private String lastMessage;

    /** 最后消息时间 */
    private LocalDateTime lastMessageTime;

    /** 新人未读消息数 */
    private Integer customerUnread;

    /** 主持人未读消息数 */
    private Integer hostUnread;

    /** 会话状态: 1=正常, 0=关闭 */
    private Integer status;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    @TableLogic
    private Integer isDeleted;
}
