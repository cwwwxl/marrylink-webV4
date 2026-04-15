/*
 Navicat Premium Data Transfer

 Source Server         : ce
 Source Server Type    : MySQL
 Source Server Version : 80041
 Source Host           : localhost:3306
 Source Schema         : marrylink

 Target Server Type    : MySQL
 Target Server Version : 80041
 File Encoding         : 65001

 Date: 15/04/2026 10:58:44
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for account_mapping
-- ----------------------------
DROP TABLE IF EXISTS `account_mapping`;
CREATE TABLE `account_mapping`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID（权限表ID）',
  `account_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '统一账号ID（手机号/邮箱）',
  `user_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户类型: CUSTOMER/HOST/ADMIN',
  `ref_id` bigint NOT NULL COMMENT '关联表ID（user.id/host.id/sys_admin.id）',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '加密密码',
  `status` tinyint NULL DEFAULT 1 COMMENT '状态: 0-禁用 1-正常',
  `last_login_time` datetime NULL DEFAULT NULL COMMENT '最后登录时间',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_account_type`(`account_id` ASC, `user_type` ASC) USING BTREE,
  INDEX `idx_ref_id`(`ref_id` ASC) USING BTREE,
  INDEX `idx_user_type`(`user_type` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '统一账号映射表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of account_mapping
-- ----------------------------
INSERT INTO `account_mapping` VALUES (1, 'admin', 'ADMIN', 1, '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', 1, NULL, '2026-01-08 11:25:24', '2026-02-24 15:24:19', 0);
INSERT INTO `account_mapping` VALUES (2, '13900139000', 'HOST', 16, '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', 1, NULL, '2026-01-08 11:25:24', '2026-01-08 11:25:24', 0);
INSERT INTO `account_mapping` VALUES (3, '13800138000', 'CUSTOMER', 1, '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', 1, NULL, '2026-01-08 11:25:24', '2026-01-08 14:12:20', 0);
INSERT INTO `account_mapping` VALUES (4, '17382739238', 'HOST', 19, '$2a$10$mr0CPl6yUSXzlNWQRnY5E.C8yl3xMw5viWA/iKhfNDxFkfx6zfX0W', 1, NULL, '2026-01-22 10:26:00', '2026-01-22 10:26:00', 0);
INSERT INTO `account_mapping` VALUES (5, '17382928273', 'CUSTOMER', 2, '$2a$10$dbFN5itNlI.Dpju.OhGRJu7zNB.1YibXdsEmwu.qlgckQM4h//4Ny', 1, NULL, '2026-01-22 10:30:53', '2026-01-22 10:30:53', 0);
INSERT INTO `account_mapping` VALUES (6, '111', 'HOST', 20, '$2a$10$O6qiKcUpFe6AK8.6w0e6qOjUsQjaOO/hXq/e/Ol4Ep4ZwiUhlFkQ.', 1, NULL, '2026-02-10 17:19:56', '2026-02-10 17:19:56', 0);
INSERT INTO `account_mapping` VALUES (9, '111111', 'HOST', 23, '$2a$10$hLAd5S9yJpVFX9ziionUXOxCEo6cdjgmuI2.NJK9ehr66/31lMtji', 1, NULL, '2026-02-10 17:28:00', '2026-02-10 17:28:00', 0);
INSERT INTO `account_mapping` VALUES (10, '17382391555', 'CUSTOMER', 3, '$2a$10$KeXelQ1aFQtd42/DZU/WB.MKqMMIo8cKvkMR6BmN7zs8EXfX7t.W.', 1, NULL, '2026-02-25 19:57:41', '2026-02-25 19:57:41', 0);
INSERT INTO `account_mapping` VALUES (11, '17381927230', 'HOST', 24, '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', 1, NULL, '2026-03-02 20:30:18', '2026-03-11 20:42:01', 0);

-- ----------------------------
-- Table structure for host
-- ----------------------------
DROP TABLE IF EXISTS `host`;
CREATE TABLE `host`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `host_code` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '主持人编号如MC0001',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `stage_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '艺名',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `price` decimal(10, 2) NULL DEFAULT NULL COMMENT '服务价格/场',
  `service_areas` json NULL COMMENT '服务地区',
  `status` tinyint NULL DEFAULT 1 COMMENT '1:正常 2:待审核 0:禁用',
  `rating` decimal(2, 1) NULL DEFAULT 5.0,
  `order_count` int NULL DEFAULT 0,
  `join_time` date NULL DEFAULT NULL,
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  `tag` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '主持人标签',
  `user_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'HOST' COMMENT '用户类型: HOST',
  `account_status` tinyint NULL DEFAULT 1 COMMENT '账号状态: 0-禁用 1-正常',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `host_code`(`host_code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 24 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of host
-- ----------------------------
INSERT INTO `host` VALUES (16, 'MC0001', '张主持', '婚礼达人', '13900139000', 'host@example.com', '/uploads/avatars/host2.jpg', 2999.00, NULL, 1, 4.0, 0, '2020-01-08', '2026-01-07 10:25:14', '2026-03-11 21:11:18', 0, NULL, 'HOST', 1, '婚礼专家，专业婚礼主持人，为您打造完美婚礼');
INSERT INTO `host` VALUES (19, NULL, '昭流', '', '17382739238', '', '/uploads/avatars/host1.jpg', 55550.00, NULL, 1, 5.0, 0, '2023-05-26', '2026-01-22 10:26:00', '2026-03-11 21:23:22', 0, NULL, 'HOST', 1, NULL);
INSERT INTO `host` VALUES (20, NULL, '测试', '测试', '111', '2025/4/4', '/uploads/avatars/host1.jpg', 500000.00, NULL, 1, 5.0, 0, '2026-02-10', '2026-02-10 17:19:56', '2026-03-11 21:23:25', 1, NULL, 'HOST', 1, '测试');
INSERT INTO `host` VALUES (23, NULL, '测试', '测试', '111111', '39299', '/uploads/avatars/host1.jpg', 500000.00, NULL, 1, 5.0, 0, '2025-04-04', '2026-02-10 17:28:00', '2026-03-02 20:35:35', 1, NULL, 'HOST', 1, '测试');
INSERT INTO `host` VALUES (24, NULL, '例是', '', '17381927230', '', '/uploads/avatars/defAvatar.png', 5000.00, NULL, 1, 5.0, 0, '2023-10-18', '2026-03-02 20:30:18', '2026-03-02 20:30:18', 0, NULL, 'HOST', 1, '这个是一个很牛的主持人');

-- ----------------------------
-- Table structure for host_tag
-- ----------------------------
DROP TABLE IF EXISTS `host_tag`;
CREATE TABLE `host_tag`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `host_id` bigint NOT NULL,
  `tag_id` bigint NULL DEFAULT NULL,
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `tag_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_host_tag`(`host_id` ASC, `tag_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 56 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of host_tag
-- ----------------------------
INSERT INTO `host_tag` VALUES (51, 16, NULL, '2026-03-02 20:54:48', '01');
INSERT INTO `host_tag` VALUES (52, 16, NULL, '2026-03-02 20:54:48', '05');
INSERT INTO `host_tag` VALUES (53, 19, NULL, '2026-03-02 20:58:58', '01');
INSERT INTO `host_tag` VALUES (54, 19, NULL, '2026-03-02 20:58:58', '05');
INSERT INTO `host_tag` VALUES (55, 24, NULL, '2026-03-02 20:59:07', '04');
INSERT INTO `host_tag` VALUES (56, 24, NULL, '2026-03-02 20:59:07', '05');

-- ----------------------------
-- Table structure for message
-- ----------------------------
DROP TABLE IF EXISTS `message`;
CREATE TABLE `message`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息内容',
  `host_id` bigint NULL DEFAULT NULL COMMENT '关联主持人ID',
  `admin_id` bigint NULL DEFAULT NULL COMMENT '关联管理员ID',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '消息状态：1-未读，2-已读',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `is_deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
  `user_id` bigint NULL DEFAULT NULL COMMENT '关联用户id',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_host_id`(`host_id` ASC) USING BTREE,
  INDEX `idx_admin_id`(`admin_id` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '消息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of message
-- ----------------------------
INSERT INTO `message` VALUES (1, '李小美&王大明 2026-01-23 的订单已创建，请与新人进行沟通', 16, NULL, 2, '2026-01-21 16:21:18', '2026-01-22 11:01:14', 0, NULL);
INSERT INTO `message` VALUES (2, '李小&王明 2026-01-23 的订单已创建，请与新人进行沟通', 16, NULL, 2, '2026-01-20 16:21:18', '2026-01-22 11:01:14', 0, NULL);
INSERT INTO `message` VALUES (3, '李小美&王大明 2026-02-13 的订单已创建，请与新人进行沟通', 16, NULL, 2, '2026-02-13 15:13:18', '2026-02-24 15:07:43', 0, 1);
INSERT INTO `message` VALUES (4, '李四&汪芜 2026-02-27 的订单已创建，请与新人进行沟通', 16, NULL, 2, '2026-02-25 19:59:19', '2026-03-01 16:40:22', 0, 3);
INSERT INTO `message` VALUES (5, '李小美&王大明 2026-02-26 的订单已创建，请与新人进行沟通', 16, NULL, 2, '2026-02-25 20:05:20', '2026-02-25 20:08:24', 0, 1);
INSERT INTO `message` VALUES (6, '李四&汪芜 2026-03-13 的订单已创建，请与新人进行沟通', 19, NULL, 2, '2026-03-01 18:38:12', '2026-03-02 20:59:42', 0, 3);
INSERT INTO `message` VALUES (7, '李四&汪芜 2026-03-12 的订单已创建，请与新人进行沟通', 16, NULL, 2, '2026-03-02 20:59:28', '2026-03-02 20:59:41', 0, 3);

-- ----------------------------
-- Table structure for order
-- ----------------------------
DROP TABLE IF EXISTS `order`;
CREATE TABLE `order`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `order_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `user_id` bigint NOT NULL,
  `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `host_id` bigint NOT NULL,
  `host_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `wedding_date` date NOT NULL,
  `wedding_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `amount` decimal(10, 2) NULL DEFAULT NULL,
  `status` tinyint NULL DEFAULT 1 COMMENT '1:待确认 2:已确认 3:定金已付 4:已完成 5:已取消',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  `rating` tinyint NULL DEFAULT NULL COMMENT '用户评分 1-5星',
  `comment` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户评价',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `order_no`(`order_no` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 26 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of order
-- ----------------------------
INSERT INTO `order` VALUES (7, '0ee8b156-6c66-46e1-8b85-3bedc4f5d337', 1, '李小美&王大明', 16, NULL, '2026-01-22', '01', 2999.00, 3, '2026-01-14 10:34:50', '2026-03-01 17:27:37', 0, NULL, '312312');
INSERT INTO `order` VALUES (15, '1d053464-81dc-4e7b-aaac-2aa2a72a769b', 1, '李小美&王大明', 16, NULL, '2026-01-21', '02', 2999.00, 4, '2026-01-14 17:20:18', '2026-03-01 17:27:38', 0, NULL, '31');
INSERT INTO `order` VALUES (16, '2a166fa6-4493-4402-ba58-d21924fdcdf6', 1, '李小美&王大明', 16, NULL, '2026-01-15', '01', 2999.00, 1, '2026-01-15 10:53:22', '2026-03-01 17:27:39', 1, NULL, '123131232');
INSERT INTO `order` VALUES (17, '03ba4f7d-3121-4318-a635-ec5e94fb2018', 1, '李小美&王大明', 16, '张主持', '2026-01-15', '01', 2999.00, 1, '2026-01-15 10:53:59', '2026-03-01 17:27:41', 1, NULL, '123131232');
INSERT INTO `order` VALUES (18, 'c925d6f5-7f44-4bac-a165-664faaeeea15', 1, '李小美&王大明', 16, '张主持', '2026-01-15', '01', 2999.00, 1, '2026-01-15 10:57:24', '2026-03-01 17:27:42', 1, NULL, '123131232');
INSERT INTO `order` VALUES (19, '63911358-ab05-4933-96f6-f40990746abc', 1, '李小美&王大明', 16, '张主持', '2026-01-15', '01', 2999.00, 4, '2026-01-15 10:58:47', '2026-03-01 17:27:42', 0, 3, '123131232');
INSERT INTO `order` VALUES (20, '4559baf6-b285-4708-95bc-e6ae68a3ab05', 1, '李小美&王大明', 16, '张主持', '2026-01-23', '01', 2999.00, 1, '2026-01-21 15:52:39', '2026-03-01 17:27:43', 1, NULL, '123131232');
INSERT INTO `order` VALUES (21, '23125edd-6393-4c05-9f79-0709e738c7cf', 1, '李小美&王大明', 16, '张主持', '2026-01-23', '01', 2999.00, 4, '2026-01-21 16:21:18', '2026-03-01 17:27:52', 0, 4, '123131232');
INSERT INTO `order` VALUES (22, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', 1, '李小美&王大明', 16, '张主持', '2026-02-13', '01', 2999.00, 4, '2026-02-13 15:13:18', '2026-03-01 17:27:53', 0, NULL, '123131232');
INSERT INTO `order` VALUES (23, '44a42555-54c2-48f4-90ca-af84ac5893bf', 3, '李四&汪芜', 16, '张主持', '2026-02-27', '01', 2999.00, 4, '2026-02-25 19:59:19', '2026-03-01 17:27:54', 0, 5, '123131232');
INSERT INTO `order` VALUES (24, '7a27b0bb-4b6e-4eb3-a81f-00672202d6ab', 1, '李小美&王大明', 16, '张主持', '2026-02-26', '01', 2999.00, 5, '2026-02-25 20:05:20', '2026-03-01 17:27:55', 0, NULL, '123131232');
INSERT INTO `order` VALUES (25, '943a8996-40a2-4f89-9189-538b521d9da2', 3, '李四&汪芜', 19, '昭流', '2026-03-13', '01', 55550.00, 3, '2026-03-01 18:38:12', '2026-03-01 18:38:12', 0, NULL, NULL);
INSERT INTO `order` VALUES (26, '151567c0-be60-485f-89e7-6c458331aee1', 3, '李四&汪芜', 16, '张主持', '2026-03-12', '03', 2999.00, 3, '2026-03-02 20:59:28', '2026-03-02 20:59:28', 0, NULL, NULL);

-- ----------------------------
-- Table structure for order_log
-- ----------------------------
DROP TABLE IF EXISTS `order_log`;
CREATE TABLE `order_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `order_no` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '订单号',
  `old_status` int NULL DEFAULT NULL COMMENT '原状态',
  `new_status` int NOT NULL COMMENT '新状态',
  `operator` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '操作人',
  `operator_ip` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '操作IP',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_order_no`(`order_no` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 28 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '订单状态变更日志表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of order_log
-- ----------------------------
INSERT INTO `order_log` VALUES (1, '23125edd-6393-4c05-9f79-0709e738c7cf', 1, 3, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:34:10');
INSERT INTO `order_log` VALUES (2, '23125edd-6393-4c05-9f79-0709e738c7cf', 3, 4, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:36:03');
INSERT INTO `order_log` VALUES (3, '23125edd-6393-4c05-9f79-0709e738c7cf', 4, 3, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:36:19');
INSERT INTO `order_log` VALUES (4, '23125edd-6393-4c05-9f79-0709e738c7cf', 3, 1, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:36:26');
INSERT INTO `order_log` VALUES (5, '23125edd-6393-4c05-9f79-0709e738c7cf', 1, 3, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:36:37');
INSERT INTO `order_log` VALUES (6, '23125edd-6393-4c05-9f79-0709e738c7cf', 3, 4, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:38:23');
INSERT INTO `order_log` VALUES (7, '23125edd-6393-4c05-9f79-0709e738c7cf', 4, 1, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:40:34');
INSERT INTO `order_log` VALUES (8, '23125edd-6393-4c05-9f79-0709e738c7cf', 1, 3, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:42:33');
INSERT INTO `order_log` VALUES (9, '23125edd-6393-4c05-9f79-0709e738c7cf', 3, 4, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:44:03');
INSERT INTO `order_log` VALUES (10, '23125edd-6393-4c05-9f79-0709e738c7cf', 4, 1, '2', '0:0:0:0:0:0:0:1', '2026-01-22 11:44:47');
INSERT INTO `order_log` VALUES (11, '23125edd-6393-4c05-9f79-0709e738c7cf', 1, 3, '13900139000', '0:0:0:0:0:0:0:1', '2026-01-22 11:46:14');
INSERT INTO `order_log` VALUES (12, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', 1, 3, 'admin', '0:0:0:0:0:0:0:1', '2026-02-13 15:14:04');
INSERT INTO `order_log` VALUES (13, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', 3, 1, 'admin', '0:0:0:0:0:0:0:1', '2026-02-13 15:15:17');
INSERT INTO `order_log` VALUES (14, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', 1, 3, 'admin', '0:0:0:0:0:0:0:1', '2026-02-13 15:15:22');
INSERT INTO `order_log` VALUES (15, '23125edd-6393-4c05-9f79-0709e738c7cf', 3, 4, 'admin', '0:0:0:0:0:0:0:1', '2026-02-24 15:25:03');
INSERT INTO `order_log` VALUES (16, '63911358-ab05-4933-96f6-f40990746abc', 4, 3, 'admin', '0:0:0:0:0:0:0:1', '2026-02-24 15:48:32');
INSERT INTO `order_log` VALUES (17, '63911358-ab05-4933-96f6-f40990746abc', 3, 4, 'admin', '0:0:0:0:0:0:0:1', '2026-02-24 15:49:12');
INSERT INTO `order_log` VALUES (18, '1d053464-81dc-4e7b-aaac-2aa2a72a769b', 3, 4, 'admin', '0:0:0:0:0:0:0:1', '2026-02-24 15:54:12');
INSERT INTO `order_log` VALUES (19, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', 3, 1, '13900139000', '0:0:0:0:0:0:0:1', '2026-02-24 17:27:05');
INSERT INTO `order_log` VALUES (20, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', 1, 3, '13900139000', '0:0:0:0:0:0:0:1', '2026-02-24 17:27:08');
INSERT INTO `order_log` VALUES (21, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', 3, 4, '13900139000', '0:0:0:0:0:0:0:1', '2026-02-24 17:27:16');
INSERT INTO `order_log` VALUES (22, '44a42555-54c2-48f4-90ca-af84ac5893bf', 1, 3, '13900139000', '0:0:0:0:0:0:0:1', '2026-02-25 20:01:43');
INSERT INTO `order_log` VALUES (23, '44a42555-54c2-48f4-90ca-af84ac5893bf', 3, 4, '13900139000', '0:0:0:0:0:0:0:1', '2026-02-25 20:07:38');
INSERT INTO `order_log` VALUES (24, '7a27b0bb-4b6e-4eb3-a81f-00672202d6ab', 1, 5, 'admin', '0:0:0:0:0:0:0:1', '2026-02-25 20:11:02');
INSERT INTO `order_log` VALUES (25, '943a8996-40a2-4f89-9189-538b521d9da2', 1, 3, '13900139000', '0:0:0:0:0:0:0:1', '2026-03-01 18:38:34');
INSERT INTO `order_log` VALUES (26, '151567c0-be60-485f-89e7-6c458331aee1', 1, 3, 'admin', '0:0:0:0:0:0:0:1', '2026-03-02 21:00:52');
INSERT INTO `order_log` VALUES (27, '151567c0-be60-485f-89e7-6c458331aee1', 3, 1, 'admin', '0:0:0:0:0:0:0:1', '2026-03-02 21:04:46');
INSERT INTO `order_log` VALUES (28, '151567c0-be60-485f-89e7-6c458331aee1', 1, 3, 'admin', '0:0:0:0:0:0:0:1', '2026-03-02 21:04:50');

-- ----------------------------
-- Table structure for questionnaire_submission
-- ----------------------------
DROP TABLE IF EXISTS `questionnaire_submission`;
CREATE TABLE `questionnaire_submission`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `submission_code` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `user_id` bigint NOT NULL,
  `template_id` bigint NOT NULL,
  `host_id` bigint NULL DEFAULT NULL,
  `answers` json NULL,
  `status` tinyint NULL DEFAULT 1 COMMENT '1:待处理 2:已提交-待查看 3:已查看',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  `order_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `submission_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `submission_code`(`submission_code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of questionnaire_submission
-- ----------------------------
INSERT INTO `questionnaire_submission` VALUES (1, 'QS202601070001', 1, 1, 16, '{\"1\": {\"answer\": \"1\", \"question\": \"新郎姓名\"}, \"2\": {\"answer\": \"1\", \"question\": \"新娘姓名\"}, \"3\": {\"answer\": \"2026-01-30\", \"question\": \"婚礼日期\"}, \"4\": {\"answer\": \"1\", \"question\": \"婚礼地点\"}, \"5\": {\"answer\": \"中式传统\", \"question\": \"婚礼风格\"}, \"6\": {\"answer\": \"1\", \"question\": \"预计宾客人数\"}, \"7\": {\"answer\": [\"需要双语主持\", \"有特殊仪式环节\"], \"question\": \"特殊需求（多选）\"}, \"8\": {\"answer\": \"1\", \"question\": \"其他补充说明\"}}', 2, '2026-01-07 10:22:51', '2026-03-01 16:33:19', 1, '0ee8b156-6c66-46e1-8b85-3bedc4f5d337', NULL);
INSERT INTO `questionnaire_submission` VALUES (2, 'QS2011367764085792768', 1, 2, 16, '{\"1\": {\"answer\": \"1\", \"question\": \"新郎姓名\"}, \"2\": {\"answer\": \"2\", \"question\": \"新娘姓名\"}, \"3\": {\"answer\": \"2026-01-31\", \"question\": \"婚礼日期\"}, \"4\": {\"answer\": \"1\", \"question\": \"婚礼地点\"}, \"5\": {\"answer\": \"中式传统\", \"question\": \"婚礼风格\"}, \"6\": {\"answer\": \"1\", \"question\": \"预计宾客人数\"}, \"7\": {\"answer\": [\"需要双语主持\", \"有特殊仪式环节\"], \"question\": \"特殊需求（多选）\"}, \"8\": {\"answer\": \"111\", \"question\": \"其他补充说明\"}}', 2, '2026-01-14 17:20:19', '2026-03-01 16:33:21', 0, '1d053464-81dc-4e7b-aaac-2aa2a72a769b', NULL);
INSERT INTO `questionnaire_submission` VALUES (3, 'QS2011373082547068928', 1, 1, 16, NULL, 2, '2026-01-14 17:41:27', '2026-03-01 16:33:23', 0, '0ee8b156-6c66-46e1-8b85-3bedc4f5d337', NULL);
INSERT INTO `questionnaire_submission` VALUES (4, 'QS2014179776691986432', 1, 1, 16, NULL, 2, '2026-01-22 11:34:18', '2026-03-01 16:33:25', 0, '23125edd-6393-4c05-9f79-0709e738c7cf', NULL);
INSERT INTO `questionnaire_submission` VALUES (5, 'QS2022207630247796736', 1, 1, 16, NULL, 1, '2026-02-13 15:14:05', '2026-02-13 15:14:05', 0, '2f19eaa3-2438-4f53-8b08-e19ed40a166d', NULL);
INSERT INTO `questionnaire_submission` VALUES (6, 'QS2026202589263126528', 1, 1, 16, NULL, 1, '2026-02-24 15:48:37', '2026-02-24 15:48:37', 0, '63911358-ab05-4933-96f6-f40990746abc', NULL);
INSERT INTO `questionnaire_submission` VALUES (7, 'QS2026628673158778880', 3, 1, 16, '{\"1\": {\"answer\": \"测\", \"question\": \"新郎姓名\"}, \"2\": {\"answer\": \"1\", \"question\": \"新娘姓名\"}, \"3\": {\"answer\": \"纯中式传统婚礼\", \"question\": \"婚礼仪式形式\"}, \"4\": {\"answer\": \"10桌以内（小型温馨）\", \"question\": \"婚宴规模（预计桌数）\"}, \"5\": {\"answer\": \"酒店宴会厅\", \"question\": \"婚礼场地类型\"}, \"6\": {\"answer\": \"需要（含堵门、找红鞋等游戏）\", \"question\": \"是否需要传统接亲环节\"}, \"7\": {\"answer\": [\"拜天地\", \"敬茶改口\"], \"question\": \"希望包含的中式传统仪式环节（可多选）\"}, \"8\": {\"answer\": \"秀禾服（经典红色）\", \"question\": \"新娘礼服风格偏好\"}, \"9\": {\"answer\": \"传统正红+金色\", \"question\": \"婚礼主色调偏好\"}, \"10\": {\"answer\": [\"红灯笼\"], \"question\": \"婚礼现场布置元素偏好（可多选）\"}, \"11\": {\"answer\": \"庄重大气型（传统司仪风格）\", \"question\": \"婚礼司仪/主持风格偏好\"}, \"12\": {\"answer\": [\"中式传统乐器演奏（古筝/琵琶等）\"], \"question\": \"婚礼音乐/表演需求（可多选）\"}, \"13\": {\"answer\": \"传统中式宴席（八大碗等）\", \"question\": \"婚宴菜品风格偏好\"}, \"14\": {\"answer\": \"5万以内\", \"question\": \"婚礼预算范围\"}, \"15\": {\"answer\": \"仪式感与传统文化传承\", \"question\": \"对婚礼最看重的方面\"}, \"16\": {\"answer\": \"测试\", \"question\": \"其他说明\"}}', 1, '2026-02-25 20:01:43', '2026-03-01 16:33:03', 0, '44a42555-54c2-48f4-90ca-af84ac5893bf', NULL);
INSERT INTO `questionnaire_submission` VALUES (8, 'QS2028057299142082560', 3, 1, 19, '{\"1\": {\"answer\": \"1\", \"question\": \"新郎姓名\"}, \"2\": {\"answer\": \"1\", \"question\": \"新娘姓名\"}, \"3\": {\"answer\": \"纯中式传统婚礼\", \"question\": \"婚礼仪式形式\"}, \"4\": {\"answer\": \"10桌以内（小型温馨）\", \"question\": \"婚宴规模（预计桌数）\"}, \"5\": {\"answer\": \"酒店宴会厅\", \"question\": \"婚礼场地类型\"}, \"6\": {\"answer\": \"需要（含堵门、找红鞋等游戏）\", \"question\": \"是否需要传统接亲环节\"}, \"7\": {\"answer\": [\"拜天地\"], \"question\": \"希望包含的中式传统仪式环节（可多选）\"}, \"8\": {\"answer\": \"秀禾服（经典红色）\", \"question\": \"新娘礼服风格偏好\"}, \"9\": {\"answer\": \"传统正红+金色\", \"question\": \"婚礼主色调偏好\"}, \"10\": {\"answer\": [\"红灯笼\"], \"question\": \"婚礼现场布置元素偏好（可多选）\"}, \"11\": {\"answer\": \"庄重大气型（传统司仪风格）\", \"question\": \"婚礼司仪/主持风格偏好\"}, \"12\": {\"answer\": [\"中式传统乐器演奏（古筝/琵琶等）\"], \"question\": \"婚礼音乐/表演需求（可多选）\"}, \"13\": {\"answer\": \"传统中式宴席（八大碗等）\", \"question\": \"婚宴菜品风格偏好\"}, \"14\": {\"answer\": \"5万以内\", \"question\": \"婚礼预算范围\"}, \"15\": {\"answer\": \"仪式感与传统文化传承\", \"question\": \"对婚礼最看重的方面\"}, \"16\": {\"answer\": \"\", \"question\": \"其他说明\"}}', 2, '2026-03-01 18:38:34', '2026-03-01 18:39:11', 0, '943a8996-40a2-4f89-9189-538b521d9da2', NULL);
INSERT INTO `questionnaire_submission` VALUES (9, 'QS2028455496263946240', 3, 4, 16, '{\"1\": {\"answer\": \"童话/公主\", \"question\": \"婚礼主题风格偏好\"}, \"2\": {\"answer\": \"简约婚纱\", \"question\": \"新娘礼服风格偏好\"}, \"3\": {\"answer\": \"主题定制西装\", \"question\": \"新郎礼服风格偏好\"}, \"4\": {\"answer\": \"室内宴会厅\", \"question\": \"婚礼场地类型\"}, \"5\": {\"answer\": \"梦幻粉色系\", \"question\": \"婚礼主色调\"}, \"6\": {\"answer\": [\"气球装饰\", \"灯光特效\", \"特殊材质（如纱幔/金属）\", \"花卉\"], \"question\": \"希望加入的主题装饰元素（可多选）\"}, \"7\": {\"answer\": [\"主题游戏\", \"表演节目\", \"互动装置\"], \"question\": \"宾客互动环节偏好（可多选）\"}, \"8\": {\"answer\": \"10-20万\", \"question\": \"婚礼预算范围\"}, \"9\": {\"answer\": \"50-100人\", \"question\": \"预计宾客人数\"}, \"10\": {\"answer\": \"无\", \"question\": \"其他说明或特殊要求\"}}', 2, '2026-03-02 21:00:52', '2026-03-02 21:05:34', 0, '151567c0-be60-485f-89e7-6c458331aee1', NULL);

-- ----------------------------
-- Table structure for questionnaire_template
-- ----------------------------
DROP TABLE IF EXISTS `questionnaire_template`;
CREATE TABLE `questionnaire_template`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '模板类型',
  `question_count` int NULL DEFAULT 0,
  `use_count` int NULL DEFAULT 0,
  `content` json NULL COMMENT '问卷内容',
  `status` tinyint NULL DEFAULT 1,
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of questionnaire_template
-- ----------------------------
INSERT INTO `questionnaire_template` VALUES (1, '中式婚礼问卷', '01', 8, 1, '[{\"id\": 1, \"type\": \"radio\", \"options\": [\"秀禾服（经典红色）\", \"龙凤褂\", \"汉服（唐制/明制/宋制）\", \"旗袍\", \"中式礼服+西式婚纱各一套\"], \"question\": \"新娘礼服风格偏好\", \"required\": true}, {\"id\": 2, \"type\": \"radio\", \"options\": [\"长袍马褂\", \"中山装\", \"西装\", \"汉服\", \"其他\"], \"question\": \"新郎礼服风格偏好\", \"required\": true}, {\"id\": 3, \"type\": \"radio\", \"options\": [\"酒店宴会厅\", \"户外草坪\", \"中式庭院\", \"传统祠堂\", \"特色餐厅\", \"其他\"], \"question\": \"婚礼场地类型\", \"required\": true}, {\"id\": 4, \"type\": \"checkbox\", \"options\": [\"川菜\", \"粤菜\", \"本帮菜\", \"淮扬菜\", \"鲁菜\", \"素食\", \"其他\"], \"question\": \"婚宴菜系偏好（可多选）\", \"required\": true}, {\"id\": 5, \"type\": \"checkbox\", \"options\": [\"拜堂\", \"敬茶\", \"掀盖头\", \"合卺酒\", \"结发礼\", \"父母致辞\", \"其他\"], \"question\": \"婚礼仪式流程偏好（可多选）\", \"required\": true}, {\"id\": 6, \"type\": \"radio\", \"options\": [\"中国红\", \"金色\", \"粉色\", \"蓝色\", \"紫色\", \"橙色\", \"其他\"], \"question\": \"婚礼主色调\", \"required\": true}, {\"id\": 7, \"type\": \"radio\", \"options\": [\"50人以下\", \"50-100人\", \"100-200人\", \"200-300人\", \"300人以上\"], \"question\": \"预计宾客人数\", \"required\": true}, {\"id\": 8, \"type\": \"radio\", \"options\": [\"5万以下\", \"5-10万\", \"10-20万\", \"20-50万\", \"50万以上\"], \"question\": \"婚礼预算范围\", \"required\": true}, {\"id\": 9, \"type\": \"checkbox\", \"options\": [\"舞狮\", \"唢呐\", \"花轿\", \"火盆\", \"马鞍\", \"其他\"], \"question\": \"希望加入的传统婚礼元素（可多选）\", \"required\": true}, {\"id\": 10, \"type\": \"text\", \"question\": \"其他说明或特殊要求\", \"required\": false}]', 1, '2026-01-07 10:22:51', '2026-03-02 18:04:28', 0);
INSERT INTO `questionnaire_template` VALUES (2, '西式婚礼问卷', '02', 8, 1, '[{\"id\": 1, \"type\": \"radio\", \"options\": [\"A字型婚纱\", \"鱼尾婚纱\", \"蓬蓬裙婚纱\", \"短款婚纱\", \"复古蕾丝婚纱\", \"其他\"], \"question\": \"新娘婚纱款式偏好\", \"required\": true}, {\"id\": 2, \"type\": \"radio\", \"options\": [\"经典黑色西装\", \"藏蓝色西装\", \"灰色西装\", \"白色西装\", \"燕尾服\", \"休闲西装\"], \"question\": \"新郎礼服风格偏好\", \"required\": true}, {\"id\": 3, \"type\": \"radio\", \"options\": [\"教堂\", \"酒店宴会厅\", \"户外草坪\", \"海滩\", \"庄园/别墅\", \"特色餐厅\", \"其他\"], \"question\": \"婚礼场地类型\", \"required\": true}, {\"id\": 4, \"type\": \"checkbox\", \"options\": [\"西式自助餐\", \"西式套餐\", \"中式圆桌宴\", \"中西融合菜\", \"素食\", \"其他\"], \"question\": \"婚宴菜品偏好（可多选）\", \"required\": true}, {\"id\": 5, \"type\": \"checkbox\", \"options\": [\"交换戒指\", \"宣读誓言\", \"父亲交接\", \"抛捧花\", \"切蛋糕\", \"第一支舞\", \"其他\"], \"question\": \"婚礼仪式流程偏好（可多选）\", \"required\": true}, {\"id\": 6, \"type\": \"radio\", \"options\": [\"经典白绿色\", \"香槟色\", \"粉色\", \"蓝色\", \"紫色\", \"红色\", \"其他\"], \"question\": \"婚礼主色调\", \"required\": true}, {\"id\": 7, \"type\": \"radio\", \"options\": [\"50人以下\", \"50-100人\", \"100-200人\", \"200-300人\", \"300人以上\"], \"question\": \"预计宾客人数\", \"required\": true}, {\"id\": 8, \"type\": \"radio\", \"options\": [\"5万以下\", \"5-10万\", \"10-20万\", \"20-50万\", \"50万以上\"], \"question\": \"婚礼预算范围\", \"required\": true}, {\"id\": 9, \"type\": \"checkbox\", \"options\": [\"马车/复古汽车\", \"弦乐四重奏\", \"合影区\", \"甜品台\", \"户外仪式\", \"烟花/冷焰火\", \"其他\"], \"question\": \"希望加入的西式婚礼元素（可多选）\", \"required\": true}, {\"id\": 10, \"type\": \"text\", \"question\": \"其他说明或特殊要求\", \"required\": false}]', 1, '2026-01-07 10:22:51', '2026-03-02 18:05:18', 0);
INSERT INTO `questionnaire_template` VALUES (4, '主题婚礼问卷', '03', 8, 1, '[{\"id\": 1, \"type\": \"radio\", \"options\": [\"童话/公主\", \"复古/怀旧\", \"海洋/沙滩\", \"星空/宇宙\", \"森林/自然\", \"工业/现代\", \"动漫/游戏\", \"其他\"], \"question\": \"婚礼主题风格偏好\", \"required\": true}, {\"id\": 2, \"type\": \"radio\", \"options\": [\"主题定制礼服\", \"简约婚纱\", \"复古婚纱\", \"彩色婚纱\", \"短款礼服\", \"其他\"], \"question\": \"新娘礼服风格偏好\", \"required\": true}, {\"id\": 3, \"type\": \"radio\", \"options\": [\"主题定制西装\", \"复古西装\", \"休闲装\", \"特殊主题服饰（如cosplay）\", \"其他\"], \"question\": \"新郎礼服风格偏好\", \"required\": true}, {\"id\": 4, \"type\": \"radio\", \"options\": [\"室内宴会厅\", \"户外草坪\", \"海滩\", \"城堡/庄园\", \"艺术空间\", \"特色场馆（如博物馆/科技馆）\", \"其他\"], \"question\": \"婚礼场地类型\", \"required\": true}, {\"id\": 5, \"type\": \"radio\", \"options\": [\"梦幻粉色系\", \"复古棕色系\", \"海洋蓝系\", \"星空紫/蓝系\", \"森林绿系\", \"工业黑白灰\", \"其他\"], \"question\": \"婚礼主色调\", \"required\": true}, {\"id\": 6, \"type\": \"checkbox\", \"options\": [\"气球装饰\", \"灯光特效\", \"道具布景\", \"特殊材质（如纱幔/金属）\", \"花卉\", \"投影/多媒体\", \"其他\"], \"question\": \"希望加入的主题装饰元素（可多选）\", \"required\": true}, {\"id\": 7, \"type\": \"checkbox\", \"options\": [\"主题游戏\", \"合影道具\", \"抽奖环节\", \"表演节目\", \"互动装置\", \"其他\"], \"question\": \"宾客互动环节偏好（可多选）\", \"required\": true}, {\"id\": 8, \"type\": \"radio\", \"options\": [\"5万以下\", \"5-10万\", \"10-20万\", \"20-50万\", \"50万以上\"], \"question\": \"婚礼预算范围\", \"required\": true}, {\"id\": 9, \"type\": \"radio\", \"options\": [\"50人以下\", \"50-100人\", \"100-200人\", \"200-300人\", \"300人以上\"], \"question\": \"预计宾客人数\", \"required\": true}, {\"id\": 10, \"type\": \"text\", \"question\": \"其他说明或特殊要求\", \"required\": false}]', 1, '2026-01-07 10:22:51', '2026-03-02 18:06:04', 0);
INSERT INTO `questionnaire_template` VALUES (5, '户外婚礼问卷', '04', 8, 1, '[{\"id\": 1, \"type\": \"radio\", \"options\": [\"草坪\", \"海滩\", \"花园\", \"露台/天台\", \"森林\", \"湖边/河边\", \"山庄/庄园\", \"其他\"], \"question\": \"户外婚礼场地类型偏好\", \"required\": true}, {\"id\": 2, \"type\": \"radio\", \"options\": [\"轻便婚纱\", \"短款婚纱\", \"复古蕾丝婚纱\", \"简约鱼尾婚纱\", \"休闲西装\", \"其他\"], \"question\": \"新娘新郎礼服风格偏好（考虑户外舒适度）\", \"required\": true}, {\"id\": 3, \"type\": \"radio\", \"options\": [\"春季（3-5月）\", \"夏季（6-8月）\", \"秋季（9-11月）\", \"冬季（12-2月）\"], \"question\": \"计划举办季节\", \"required\": true}, {\"id\": 4, \"type\": \"checkbox\", \"options\": [\"西式自助餐\", \"户外烧烤\", \"野餐风格\", \"中西融合菜\", \"冷餐会\", \"其他\"], \"question\": \"婚宴餐饮形式偏好（可多选）\", \"required\": true}, {\"id\": 5, \"type\": \"checkbox\", \"options\": [\"交换戒指\", \"宣读誓言\", \"倒沙仪式\", \"合水仪式\", \"种树/植树\", \"放飞气球/蝴蝶\", \"其他\"], \"question\": \"户外婚礼仪式流程偏好（可多选）\", \"required\": true}, {\"id\": 6, \"type\": \"radio\", \"options\": [\"森系绿/白\", \"海洋蓝/白\", \"落日橙/粉\", \"清新黄/绿\", \"梦幻紫/白\", \"其他\"], \"question\": \"婚礼主色调\", \"required\": true}, {\"id\": 7, \"type\": \"radio\", \"options\": [\"50人以下\", \"50-100人\", \"100-200人\", \"200-300人\", \"300人以上\"], \"question\": \"预计宾客人数\", \"required\": true}, {\"id\": 8, \"type\": \"checkbox\", \"options\": [\"遮阳伞/棚\", \"驱蚊用品\", \"暖炉/毛毯（针对低温）\", \"风扇/降温用品\", \"透明雨伞（防雨）\", \"其他\"], \"question\": \"天气应对措施偏好（可多选）\", \"required\": true}, {\"id\": 9, \"type\": \"checkbox\", \"options\": [\"木制桌椅\", \"串灯/灯带\", \"鲜花拱门\", \"草垛装饰\", \"纱幔\", \"原木/麻绳元素\", \"其他\"], \"question\": \"希望加入的户外装饰元素（可多选）\", \"required\": true}, {\"id\": 10, \"type\": \"text\", \"question\": \"其他说明或特殊要求（如备选场地、天气预案等）\", \"required\": false}]', 1, '2026-01-07 10:22:51', '2026-03-02 18:06:43', 0);

-- ----------------------------
-- Table structure for sys_admin
-- ----------------------------
DROP TABLE IF EXISTS `sys_admin`;
CREATE TABLE `sys_admin`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `status` tinyint NULL DEFAULT 1 COMMENT '1:正常 0:禁用',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_admin
-- ----------------------------
INSERT INTO `sys_admin` VALUES (1, 'admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '管理员', NULL, 1, '2026-01-04 11:08:09', '2026-01-04 11:08:09', 0);

-- ----------------------------
-- Table structure for sys_permission
-- ----------------------------
DROP TABLE IF EXISTS `sys_permission`;
CREATE TABLE `sys_permission`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `permission_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '权限编码',
  `permission_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '权限名称',
  `resource_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '资源类型: MENU/API/BUTTON',
  `resource_path` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '资源路径',
  `parent_id` bigint NULL DEFAULT 0 COMMENT '父权限ID',
  `sort_order` int NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint NULL DEFAULT 1 COMMENT '状态: 0-禁用 1-正常',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `permission_code`(`permission_code` ASC) USING BTREE,
  INDEX `idx_parent_id`(`parent_id` ASC) USING BTREE,
  INDEX `idx_resource_type`(`resource_type` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 19 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '权限表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_permission
-- ----------------------------
INSERT INTO `sys_permission` VALUES (1, 'system:user:view', '查看用户', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (2, 'system:user:edit', '编辑用户', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (3, 'system:host:view', '查看主持人', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (4, 'system:host:edit', '编辑主持人', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (5, 'system:order:view', '查看订单', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (6, 'system:order:manage', '管理订单', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (7, 'system:tag:manage', '管理标签', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (8, 'system:questionnaire:manage', '管理问卷', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (9, 'host:schedule:view', '查看档期', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (10, 'host:schedule:manage', '管理档期', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (11, 'host:order:view', '查看订单', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (12, 'host:order:manage', '管理订单', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (13, 'host:questionnaire:view', '查看问卷', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (14, 'host:profile:edit', '编辑资料', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (15, 'customer:host:view', '查看主持人', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (16, 'customer:order:view', '查看订单', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (17, 'customer:order:create', '创建订单', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (18, 'customer:questionnaire:submit', '提交问卷', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_permission` VALUES (19, 'customer:profile:edit', '编辑资料', 'API', NULL, 0, 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);

-- ----------------------------
-- Table structure for sys_role
-- ----------------------------
DROP TABLE IF EXISTS `sys_role`;
CREATE TABLE `sys_role`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色编码',
  `role_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '角色名称',
  `user_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '适用用户类型: CUSTOMER/HOST/ADMIN',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '角色描述',
  `sort_order` int NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint NULL DEFAULT 1 COMMENT '状态: 0-禁用 1-正常',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `role_code`(`role_code` ASC) USING BTREE,
  INDEX `idx_user_type`(`user_type` ASC) USING BTREE,
  INDEX `idx_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '角色表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_role
-- ----------------------------
INSERT INTO `sys_role` VALUES (4, 'ROLE_ADMIN', '系统管理员', 'ADMIN', '拥有系统所有权限', 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_role` VALUES (5, 'ROLE_HOST', '主持人', 'HOST', '主持人角色，可管理自己的档期和订单', 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);
INSERT INTO `sys_role` VALUES (6, 'ROLE_CUSTOMER', '新人', 'CUSTOMER', '新人角色，可预约主持人和填写问卷', 0, 1, '2026-01-08 11:25:23', '2026-01-08 11:25:23', 0);

-- ----------------------------
-- Table structure for sys_role_permission
-- ----------------------------
DROP TABLE IF EXISTS `sys_role_permission`;
CREATE TABLE `sys_role_permission`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_id` bigint NOT NULL COMMENT '角色ID',
  `permission_id` bigint NOT NULL COMMENT '权限ID',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_role_permission`(`role_id` ASC, `permission_id` ASC) USING BTREE,
  INDEX `idx_role_id`(`role_id` ASC) USING BTREE,
  INDEX `idx_permission_id`(`permission_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 43 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '角色权限关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_role_permission
-- ----------------------------
INSERT INTO `sys_role_permission` VALUES (1, 4, 1, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (2, 4, 2, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (3, 4, 3, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (4, 4, 4, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (5, 4, 5, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (6, 4, 6, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (7, 4, 7, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (8, 4, 8, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (9, 4, 9, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (10, 4, 10, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (11, 4, 11, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (12, 4, 12, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (13, 4, 13, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (14, 4, 14, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (15, 4, 15, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (16, 4, 16, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (17, 4, 17, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (18, 4, 18, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (19, 4, 19, '2026-01-08 11:25:23');
INSERT INTO `sys_role_permission` VALUES (32, 5, 12, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (33, 5, 11, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (34, 5, 14, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (35, 5, 13, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (36, 5, 10, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (37, 5, 9, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (39, 6, 15, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (40, 6, 17, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (41, 6, 16, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (42, 6, 19, '2026-01-08 11:25:24');
INSERT INTO `sys_role_permission` VALUES (43, 6, 18, '2026-01-08 11:25:24');

-- ----------------------------
-- Table structure for sys_user_role
-- ----------------------------
DROP TABLE IF EXISTS `sys_user_role`;
CREATE TABLE `sys_user_role`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `account_id` bigint NOT NULL COMMENT '账号映射表ID（account_mapping.id）',
  `role_id` bigint NOT NULL COMMENT '角色ID',
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_account_role`(`account_id` ASC, `role_id` ASC) USING BTREE,
  INDEX `idx_account_id`(`account_id` ASC) USING BTREE,
  INDEX `idx_role_id`(`role_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户角色关联表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of sys_user_role
-- ----------------------------
INSERT INTO `sys_user_role` VALUES (1, 1, 4, '2026-01-08 11:25:24');
INSERT INTO `sys_user_role` VALUES (2, 2, 5, '2026-01-08 11:25:24');
INSERT INTO `sys_user_role` VALUES (3, 3, 6, '2026-01-08 11:25:24');
INSERT INTO `sys_user_role` VALUES (4, 4, 5, '2026-01-22 10:26:00');
INSERT INTO `sys_user_role` VALUES (5, 5, 6, '2026-01-22 10:30:54');
INSERT INTO `sys_user_role` VALUES (6, 6, 5, '2026-02-10 17:19:56');
INSERT INTO `sys_user_role` VALUES (7, 9, 5, '2026-02-10 17:28:00');
INSERT INTO `sys_user_role` VALUES (8, 10, 6, '2026-02-25 19:57:41');
INSERT INTO `sys_user_role` VALUES (9, 11, 5, '2026-03-02 20:30:18');

-- ----------------------------
-- Table structure for tag
-- ----------------------------
DROP TABLE IF EXISTS `tag`;
CREATE TABLE `tag`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `category_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `use_count` int NULL DEFAULT 0,
  `status` tinyint NULL DEFAULT 1,
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `category_id`(`category_code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 14 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tag
-- ----------------------------
INSERT INTO `tag` VALUES (6, '02', '中式婚礼', '01', 0, 1, '2026-01-07 10:22:51', '2026-01-07 10:29:58', 0);
INSERT INTO `tag` VALUES (7, '02', '西式婚礼', '02', 0, 1, '2026-01-07 10:22:51', '2026-01-07 10:30:02', 0);
INSERT INTO `tag` VALUES (8, '01', '中式婚礼', '01', 0, 1, '2026-01-13 17:34:38', '2026-01-13 17:34:38', 0);
INSERT INTO `tag` VALUES (9, '01', '西式婚礼', '02', 0, 1, '2026-01-13 17:34:46', '2026-01-13 17:34:46', 0);
INSERT INTO `tag` VALUES (10, '01', '主题婚礼', '03', 0, 1, '2026-01-13 17:35:04', '2026-01-13 17:35:04', 0);
INSERT INTO `tag` VALUES (11, '01', '户外婚礼', '04', 0, 1, '2026-01-13 17:35:15', '2026-01-13 17:35:15', 0);
INSERT INTO `tag` VALUES (12, '02', '主题婚礼', '03', 0, 1, '2026-01-07 10:22:51', '2026-01-07 10:30:02', 0);
INSERT INTO `tag` VALUES (13, '02', '户外婚礼', '04', 0, 1, '2026-01-07 10:22:51', '2026-01-07 10:30:02', 0);
INSERT INTO `tag` VALUES (14, '01', '幽默风趣', '05', 0, 1, '2026-02-13 15:04:28', '2026-02-13 15:04:28', 0);

-- ----------------------------
-- Table structure for tag_category
-- ----------------------------
DROP TABLE IF EXISTS `tag_category`;
CREATE TABLE `tag_category`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `tag_count` int NULL DEFAULT 0,
  `status` tinyint NULL DEFAULT 1,
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `code`(`code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tag_category
-- ----------------------------
INSERT INTO `tag_category` VALUES (8, '婚礼风格', '01', 0, 1, '2026-01-07 10:21:42', '2026-01-07 10:21:42', 0);
INSERT INTO `tag_category` VALUES (9, '问卷类型', '02', 0, 1, '2026-01-07 10:21:42', '2026-01-07 10:21:42', 0);

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `bride_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '新娘姓名',
  `groom_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '新郎姓名',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `wedding_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '婚礼类型',
  `status` tinyint NULL DEFAULT 1 COMMENT '1:正常 0:禁用',
  `order_count` int NULL DEFAULT 0,
  `create_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_deleted` tinyint NULL DEFAULT 0,
  `user_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT 'CUSTOMER' COMMENT '用户类型: CUSTOMER',
  `account_status` tinyint NULL DEFAULT 1 COMMENT '账号状态: 0-禁用 1-正常',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (1, '李小美', '王大明', '13800138000', '/uploads/avatars/5a9927e0-b76e-4c04-9841-8953d09c791a.gif', '中式婚礼', 1, 0, '2026-01-07 10:20:15', '2026-01-22 10:09:51', 0, 'CUSTOMER', 1);
INSERT INTO `user` VALUES (2, '张三', '李四', '17382928273', NULL, NULL, 1, 0, '2026-01-22 10:30:53', '2026-01-22 10:30:53', 0, 'CUSTOMER', 1);
INSERT INTO `user` VALUES (3, '李四', '汪芜', '17382391555', NULL, NULL, 1, 0, '2026-02-25 19:57:41', '2026-02-25 19:57:41', 0, 'CUSTOMER', 1);

SET FOREIGN_KEY_CHECKS = 1;
