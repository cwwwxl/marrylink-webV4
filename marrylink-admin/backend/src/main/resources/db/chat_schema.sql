-- ============================================================
-- MarryLink 聊天功能数据库表结构
-- 数据库: marrylink (MySQL 8.0)
-- 创建日期: 2026-04-15
-- 说明: 包含聊天会话表和聊天消息表
-- ============================================================

USE `marrylink`;

-- ------------------------------------------------------------
-- 1. 聊天会话表 (chat_conversation)
-- 说明: 记录新人用户与主持人之间的聊天会话
--       每对新人-主持人之间只能有一个会话 (唯一约束)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `chat_conversation` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  `customer_id`       BIGINT       NOT NULL               COMMENT '新人用户ID (user表的id)',
  `host_id`           BIGINT       NOT NULL               COMMENT '主持人ID (host表的id)',
  `last_message`      VARCHAR(500) DEFAULT ''              COMMENT '最后一条消息内容预览',
  `last_message_time` DATETIME     DEFAULT NULL            COMMENT '最后消息时间',
  `customer_unread`   INT          DEFAULT 0               COMMENT '新人未读消息数',
  `host_unread`       INT          DEFAULT 0               COMMENT '主持人未读消息数',
  `status`            TINYINT      DEFAULT 1               COMMENT '会话状态: 1=正常, 0=关闭',
  `create_time`       DATETIME     DEFAULT CURRENT_TIMESTAMP                          COMMENT '创建时间',
  `update_time`       DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted`        TINYINT      DEFAULT 0               COMMENT '逻辑删除: 0=未删除, 1=已删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_customer_host` (`customer_id`, `host_id`),
  KEY `idx_customer_id` (`customer_id`),
  KEY `idx_host_id` (`host_id`),
  KEY `idx_last_message_time` (`last_message_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天会话表';

-- ------------------------------------------------------------
-- 2. 聊天消息表 (chat_message)
-- 说明: 记录每条聊天消息的详细信息
--       sender_type 区分发送者是新人(CUSTOMER)还是主持人(HOST)
--       msg_type 支持文字(text)和图片(image)两种消息类型
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `chat_message` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `conversation_id` BIGINT       NOT NULL               COMMENT '会话ID',
  `sender_id`       BIGINT       NOT NULL               COMMENT '发送者ID (refId)',
  `sender_type`     VARCHAR(20)  NOT NULL               COMMENT '发送者类型: CUSTOMER/HOST',
  `sender_name`     VARCHAR(100) DEFAULT ''              COMMENT '发送者名称',
  `content`         TEXT         NOT NULL               COMMENT '消息内容(文字或图片URL)',
  `msg_type`        VARCHAR(20)  DEFAULT 'text'          COMMENT '消息类型: text=文字, image=图片',
  `is_read`         TINYINT      DEFAULT 0               COMMENT '是否已读: 0=未读, 1=已读',
  `create_time`     DATETIME     DEFAULT CURRENT_TIMESTAMP                          COMMENT '创建时间',
  `update_time`     DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted`      TINYINT      DEFAULT 0               COMMENT '逻辑删除: 0=未删除, 1=已删除',
  PRIMARY KEY (`id`),
  KEY `idx_conversation_id` (`conversation_id`),
  KEY `idx_sender` (`sender_id`, `sender_type`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天消息表';

