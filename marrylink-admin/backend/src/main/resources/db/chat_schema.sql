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

-- ============================================================
-- 以下为可选的演示数据 (Optional Demo Data)
-- 说明: 仅用于开发和测试环境, 生产环境请勿执行
-- ============================================================

-- ------------------------------------------------------------
-- 演示会话数据 (3组新人-主持人会话)
-- ------------------------------------------------------------
INSERT INTO `chat_conversation` (`id`, `customer_id`, `host_id`, `last_message`, `last_message_time`, `customer_unread`, `host_unread`, `status`)
VALUES
  (1, 1001, 1, '好的，我们婚礼当天见！', '2026-04-15 10:30:00', 0, 0, 1),
  (2, 1002, 1, '请问您那天有档期吗？',   '2026-04-15 11:00:00', 0, 1, 1),
  (3, 1003, 2, '收到，我看一下流程表。',  '2026-04-14 18:45:00', 1, 0, 1);

-- ------------------------------------------------------------
-- 演示消息数据 - 会话1: 新人(1001) 与 主持人(1) 的对话
-- ------------------------------------------------------------
INSERT INTO `chat_message` (`conversation_id`, `sender_id`, `sender_type`, `sender_name`, `content`, `msg_type`, `is_read`, `create_time`)
VALUES
  (1, 1001, 'CUSTOMER', '张先生', '你好，我想咨询一下婚礼主持的事情。', 'text', 1, '2026-04-15 10:00:00'),
  (1, 1,    'HOST',     '李主持', '你好！很高兴为您服务，请问婚礼是什么时候呢？', 'text', 1, '2026-04-15 10:05:00'),
  (1, 1001, 'CUSTOMER', '张先生', '计划在6月18号，户外草坪婚礼。', 'text', 1, '2026-04-15 10:10:00'),
  (1, 1,    'HOST',     '李主持', '好的，6月18号我有档期。我给您发一下之前的案例照片。', 'text', 1, '2026-04-15 10:15:00'),
  (1, 1,    'HOST',     '李主持', 'https://marrylink.oss.example.com/demo/wedding_case_01.jpg', 'image', 1, '2026-04-15 10:16:00'),
  (1, 1001, 'CUSTOMER', '张先生', '看起来很不错！那我们定下来吧。', 'text', 1, '2026-04-15 10:25:00'),
  (1, 1,    'HOST',     '李主持', '好的，我们婚礼当天见！', 'text', 1, '2026-04-15 10:30:00');

-- ------------------------------------------------------------
-- 演示消息数据 - 会话2: 新人(1002) 与 主持人(1) 的对话
-- ------------------------------------------------------------
INSERT INTO `chat_message` (`conversation_id`, `sender_id`, `sender_type`, `sender_name`, `content`, `msg_type`, `is_read`, `create_time`)
VALUES
  (2, 1002, 'CUSTOMER', '王女士', '您好，看了您的主持视频觉得很好！', 'text', 1, '2026-04-15 10:45:00'),
  (2, 1,    'HOST',     '李主持', '谢谢夸奖！请问有什么可以帮您的？', 'text', 1, '2026-04-15 10:50:00'),
  (2, 1002, 'CUSTOMER', '王女士', '请问您那天有档期吗？', 'text', 0, '2026-04-15 11:00:00');

-- ------------------------------------------------------------
-- 演示消息数据 - 会话3: 新人(1003) 与 主持人(2) 的对话
-- ------------------------------------------------------------
INSERT INTO `chat_message` (`conversation_id`, `sender_id`, `sender_type`, `sender_name`, `content`, `msg_type`, `is_read`, `create_time`)
VALUES
  (3, 1003, 'CUSTOMER', '刘先生', '主持人您好，我们的婚礼流程可以调整一下吗？', 'text', 1, '2026-04-14 18:00:00'),
  (3, 2,    'HOST',     '赵主持', '当然可以，您想怎么调整呢？', 'text', 1, '2026-04-14 18:10:00'),
  (3, 1003, 'CUSTOMER', '刘先生', '我们想把游戏环节提前，放在敬酒之前。', 'text', 1, '2026-04-14 18:20:00'),
  (3, 2,    'HOST',     '赵主持', '收到，我看一下流程表。', 'text', 0, '2026-04-14 18:45:00');
