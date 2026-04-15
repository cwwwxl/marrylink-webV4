/**
 * MarryLink 聊天服务器
 * 提供新人（客户）与主持人之间的实时聊天功能
 *
 * 技术栈：Express + WebSocket (ws) + Multer
 * 存储方式：内存存储（开发/演示用途）
 */

const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const multer = require('multer');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');
const url = require('url');

// ============================================================
// 配置
// ============================================================
const PORT = process.env.PORT || 3001;
const UPLOADS_DIR = path.join(__dirname, 'uploads');

// 确保上传目录存在
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// ============================================================
// Express 应用初始化
// ============================================================
const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(UPLOADS_DIR));

const server = http.createServer(app);

// ============================================================
// Multer 文件上传配置
// ============================================================
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${uuidv4()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 最大 10MB
  fileFilter: (_req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|webp/;
    const extOk = allowed.test(path.extname(file.originalname).toLowerCase());
    const mimeOk = allowed.test(file.mimetype);
    if (extOk && mimeOk) {
      cb(null, true);
    } else {
      cb(new Error('仅支持上传图片文件（jpg/png/gif/webp）'));
    }
  },
});

// ============================================================
// 内存数据存储
// ============================================================

/** @type {Map<string, object>} 会话映射：conversationId -> Conversation */
const conversations = new Map();

/** @type {Map<string, object[]>} 消息映射：conversationId -> Message[] */
const messages = new Map();

/** @type {Map<number, WebSocket>} 在线用户 WebSocket 连接：userId -> ws */
const onlineUsers = new Map();

// ============================================================
// 用户认证（Token 解析）
// ============================================================
/**
 * 解析认证令牌，返回用户信息
 * 支持三种方式：
 *   1. 预设演示令牌（host_demo / customer_demo）
 *   2. Base64 编码的 JSON（模拟 JWT payload）
 *   3. 回退：根据令牌字符串生成确定性的模拟用户
 *
 * @param {string} token - 认证令牌
 * @returns {{ userId: number, userType: string, realName: string, avatar: string } | null}
 */
function parseToken(token) {
  if (!token) return null;

  // 1. 预设演示令牌
  const demoUsers = {
    host_demo: {
      userId: 100,
      userType: 'HOST',
      realName: '李主持',
      avatar: '',
    },
    customer_demo: {
      userId: 200,
      userType: 'CUSTOMER',
      realName: '王新人',
      avatar: '',
    },
  };

  if (demoUsers[token]) {
    return { ...demoUsers[token] };
  }

  // 2. 尝试 Base64 JSON 解码（模拟 JWT payload）
  try {
    const decoded = JSON.parse(Buffer.from(token, 'base64').toString('utf-8'));
    if (decoded.userId && decoded.userType) {
      return {
        userId: Number(decoded.userId),
        userType: decoded.userType,
        realName: decoded.realName || decoded.nickName || `用户${decoded.userId}`,
        avatar: decoded.avatar || '',
      };
    }
  } catch (_) {
    // 解码失败，继续回退逻辑
  }

  // 3. 回退：根据令牌字符串生成确定性的模拟用户
  let hash = 0;
  for (let i = 0; i < token.length; i++) {
    hash = ((hash << 5) - hash + token.charCodeAt(i)) | 0;
  }
  const absHash = Math.abs(hash);
  return {
    userId: absHash % 10000,
    userType: absHash % 2 === 0 ? 'CUSTOMER' : 'HOST',
    realName: `用户${absHash % 10000}`,
    avatar: '',
  };
}

/**
 * Express 中间件：从 Authorization 头中提取用户信息
 */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ code: 401, message: '未提供认证令牌' });
  }
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  const user = parseToken(token);
  if (!user) {
    return res.status(401).json({ code: 401, message: '无效的认证令牌' });
  }
  req.user = user;
  next();
}

// ============================================================
// 辅助函数
// ============================================================
/**
 * 获取或创建两个用户之间的会话
 * 保证同一对用户之间只有一个会话
 */
function getOrCreateConversation(user1, user2) {
  // 查找已存在的会话
  for (const [, conv] of conversations) {
    const ids = conv.participants.map((p) => p.userId);
    if (ids.includes(user1.userId) && ids.includes(user2.userId)) {
      return conv;
    }
  }

  // 创建新会话
  const convId = `conv_${uuidv4().slice(0, 8)}`;
  const conversation = {
    id: convId,
    participants: [
      {
        userId: user1.userId,
        userType: user1.userType,
        userName: user1.realName,
        avatar: user1.avatar || '',
      },
      {
        userId: user2.userId,
        userType: user2.userType,
        userName: user2.realName,
        avatar: user2.avatar || '',
      },
    ],
    lastMessage: '',
    lastMessageTime: null,
    // 每个用户的未读消息数
    unreadCount: {
      [user1.userId]: 0,
      [user2.userId]: 0,
    },
    createdAt: new Date().toISOString(),
  };

  conversations.set(convId, conversation);
  messages.set(convId, []);
  return conversation;
}

/**
 * 创建一条消息并更新会话状态
 */
function createMessage(conversationId, sender, content, msgType = 'text') {
  const conv = conversations.get(conversationId);
  if (!conv) return null;

  const message = {
    id: `msg_${uuidv4().slice(0, 12)}`,
    conversationId,
    senderId: sender.userId,
    senderName: sender.realName || sender.userName,
    senderType: sender.userType,
    content,
    msgType,
    timestamp: new Date().toISOString(),
    read: false,
  };

  // 添加消息到列表
  const msgList = messages.get(conversationId) || [];
  msgList.push(message);
  messages.set(conversationId, msgList);

  // 更新会话的最后消息和时间
  conv.lastMessage = msgType === 'image' ? '[图片]' : content;
  conv.lastMessageTime = message.timestamp;

  // 增加接收方的未读计数
  for (const p of conv.participants) {
    if (p.userId !== sender.userId) {
      conv.unreadCount[p.userId] = (conv.unreadCount[p.userId] || 0) + 1;
    }
  }

  return message;
}

/**
 * 获取会话中的对方用户 ID
 */
function getRecipientId(conversation, senderId) {
  const other = conversation.participants.find((p) => p.userId !== senderId);
  return other ? other.userId : null;
}

/**
 * 向指定用户发送 WebSocket 消息
 */
function sendToUser(userId, data) {
  const ws = onlineUsers.get(userId);
  if (ws && ws.readyState === 1) { // WebSocket.OPEN === 1
    ws.send(JSON.stringify(data));
    return true;
  }
  return false;
}

// ============================================================
// REST API 路由
// ============================================================
const router = express.Router();

// --- 获取当前用户的会话列表 ---
router.get('/conversations', authMiddleware, (req, res) => {
  const { userId } = req.user;
  const result = [];

  for (const [, conv] of conversations) {
    const isParticipant = conv.participants.some((p) => p.userId === userId);
    if (!isParticipant) continue;

    // 找到对方信息
    const other = conv.participants.find((p) => p.userId !== userId);

    result.push({
      id: conv.id,
      participants: conv.participants,
      // 对方信息（方便前端展示）
      targetUser: other || null,
      lastMessage: conv.lastMessage,
      lastMessageTime: conv.lastMessageTime,
      unreadCount: conv.unreadCount[userId] || 0,
      createdAt: conv.createdAt,
    });
  }

  // 按最后消息时间倒序排列
  result.sort((a, b) => {
    if (!a.lastMessageTime) return 1;
    if (!b.lastMessageTime) return -1;
    return new Date(b.lastMessageTime) - new Date(a.lastMessageTime);
  });

  res.json({ code: 200, data: result });
});

// --- 获取会话的消息历史（支持分页） ---
router.get('/conversations/:conversationId/messages', authMiddleware, (req, res) => {
  const { conversationId } = req.params;
  const { userId } = req.user;
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const size = Math.min(100, Math.max(1, parseInt(req.query.size, 10) || 20));

  const conv = conversations.get(conversationId);
  if (!conv) {
    return res.status(404).json({ code: 404, message: '会话不存在' });
  }

  // 验证用户是否为会话参与者
  const isParticipant = conv.participants.some((p) => p.userId === userId);
  if (!isParticipant) {
    return res.status(403).json({ code: 403, message: '无权访问此会话' });
  }

  const allMsgs = messages.get(conversationId) || [];
  const total = allMsgs.length;

  // 分页：返回最新的消息（倒序分页）
  const start = Math.max(0, total - page * size);
  const end = Math.max(0, total - (page - 1) * size);
  const pageMsgs = allMsgs.slice(start, end);

  res.json({
    code: 200,
    data: {
      records: pageMsgs,
      total,
      page,
      size,
      pages: Math.ceil(total / size),
    },
  });
});

// --- 创建或获取已有会话 ---
router.post('/conversations', authMiddleware, (req, res) => {
  const { targetId, targetType } = req.body;

  if (!targetId || !targetType) {
    return res.status(400).json({ code: 400, message: '缺少 targetId 或 targetType' });
  }

  if (!['HOST', 'CUSTOMER'].includes(targetType)) {
    return res.status(400).json({ code: 400, message: 'targetType 必须是 HOST 或 CUSTOMER' });
  }

  const currentUser = req.user;

  // 构造目标用户信息（在实际生产环境中应从数据库查询）
  const targetUser = {
    userId: Number(targetId),
    userType: targetType,
    realName: targetType === 'HOST' ? `主持人${targetId}` : `新人${targetId}`,
    avatar: '',
  };

  // 尝试从已有会话中查找目标用户的真实名称
  for (const [, conv] of conversations) {
    const found = conv.participants.find((p) => p.userId === Number(targetId));
    if (found) {
      targetUser.realName = found.userName;
      targetUser.avatar = found.avatar;
      break;
    }
  }

  const conversation = getOrCreateConversation(currentUser, targetUser);

  res.json({ code: 200, data: conversation });
});

// --- 上传图片 ---
router.post('/upload', authMiddleware, upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ code: 400, message: '未选择文件' });
  }

  const fileUrl = `/uploads/${req.file.filename}`;
  res.json({
    code: 200,
    data: {
      url: fileUrl,
      fullUrl: `http://localhost:${PORT}${fileUrl}`,
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
    },
  });
});

// --- 获取未读消息总数 ---
router.get('/unread-count', authMiddleware, (req, res) => {
  const { userId } = req.user;
  let totalUnread = 0;

  for (const [, conv] of conversations) {
    const isParticipant = conv.participants.some((p) => p.userId === userId);
    if (isParticipant) {
      totalUnread += conv.unreadCount[userId] || 0;
    }
  }

  res.json({ code: 200, data: { totalUnread } });
});

app.use('/api/v1/chat', router);

// ============================================================
// WebSocket 服务
// ============================================================
const wss = new WebSocketServer({ noServer: true });

// 处理 HTTP 升级请求，将 WebSocket 连接路由到 /ws
server.on('upgrade', (request, socket, head) => {
  const { pathname, query } = url.parse(request.url, true);

  if (pathname === '/ws') {
    const token = query.token;
    const user = parseToken(token);

    if (!user) {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }

    wss.handleUpgrade(request, socket, head, (ws) => {
      ws.user = user;
      wss.emit('connection', ws, request);
    });
  } else {
    socket.destroy();
  }
});

wss.on('connection', (ws) => {
  const { userId, realName, userType } = ws.user;
  console.log(`[WebSocket] 用户上线: ${realName} (ID: ${userId}, 类型: ${userType})`);

  // 注册在线用户（同一用户新连接会替代旧连接）
  const oldWs = onlineUsers.get(userId);
  if (oldWs && oldWs !== ws && oldWs.readyState === 1) {
    oldWs.close(4000, '被其他设备挤下线');
  }
  onlineUsers.set(userId, ws);

  // 发送连接成功确认
  ws.send(JSON.stringify({
    type: 'connected',
    data: {
      userId,
      realName,
      userType,
      message: '连接成功',
    },
  }));

  // 处理客户端消息
  ws.on('message', (raw) => {
    let payload;
    try {
      payload = JSON.parse(raw.toString());
    } catch (_) {
      ws.send(JSON.stringify({ type: 'error', message: '消息格式错误，请发送 JSON' }));
      return;
    }

    handleWebSocketMessage(ws, payload);
  });

  ws.on('close', () => {
    console.log(`[WebSocket] 用户下线: ${realName} (ID: ${userId})`);
    // 仅在当前连接还是注册的那个时才移除
    if (onlineUsers.get(userId) === ws) {
      onlineUsers.delete(userId);
    }
  });

  ws.on('error', (err) => {
    console.error(`[WebSocket] 用户 ${userId} 连接异常:`, err.message);
  });
});

/**
 * 处理 WebSocket 收到的消息
 */
function handleWebSocketMessage(ws, payload) {
  const { type } = payload;
  const sender = ws.user;

  switch (type) {
    // ---------- 发送聊天消息 ----------
    case 'message': {
      const { conversationId, content, msgType = 'text' } = payload;

      if (!conversationId || !content) {
        ws.send(JSON.stringify({ type: 'error', message: '缺少 conversationId 或 content' }));
        return;
      }

      const conv = conversations.get(conversationId);
      if (!conv) {
        ws.send(JSON.stringify({ type: 'error', message: '会话不存在' }));
        return;
      }

      // 验证发送者是会话参与者
      if (!conv.participants.some((p) => p.userId === sender.userId)) {
        ws.send(JSON.stringify({ type: 'error', message: '您不是此会话的参与者' }));
        return;
      }

      const message = createMessage(conversationId, sender, content, msgType);
      if (!message) {
        ws.send(JSON.stringify({ type: 'error', message: '消息发送失败' }));
        return;
      }

      // 通知发送方：消息已送达
      ws.send(JSON.stringify({ type: 'message_sent', data: message }));

      // 通知接收方：新消息
      const recipientId = getRecipientId(conv, sender.userId);
      if (recipientId) {
        sendToUser(recipientId, { type: 'new_message', data: message });
      }
      break;
    }

    // ---------- 正在输入指示器 ----------
    case 'typing': {
      const { conversationId } = payload;
      const conv = conversations.get(conversationId);
      if (!conv) return;

      const recipientId = getRecipientId(conv, sender.userId);
      if (recipientId) {
        sendToUser(recipientId, {
          type: 'typing',
          data: {
            conversationId,
            userId: sender.userId,
            userName: sender.realName,
          },
        });
      }
      break;
    }

    // ---------- 已读回执 ----------
    case 'read': {
      const { conversationId } = payload;
      const conv = conversations.get(conversationId);
      if (!conv) return;

      // 将该会话中对方发的消息标为已读
      const msgList = messages.get(conversationId) || [];
      for (const msg of msgList) {
        if (msg.senderId !== sender.userId && !msg.read) {
          msg.read = true;
        }
      }

      // 清零当前用户的未读计数
      conv.unreadCount[sender.userId] = 0;

      // 通知对方：消息已读
      const recipientId = getRecipientId(conv, sender.userId);
      if (recipientId) {
        sendToUser(recipientId, {
          type: 'messages_read',
          data: {
            conversationId,
            readBy: sender.userId,
          },
        });
      }
      break;
    }

    // ---------- 心跳 ----------
    case 'ping': {
      ws.send(JSON.stringify({ type: 'pong', timestamp: new Date().toISOString() }));
      break;
    }

    default:
      ws.send(JSON.stringify({ type: 'error', message: `未知消息类型: ${type}` }));
  }
}

// ============================================================
// 种子数据（演示用）
// ============================================================
function seedDemoData() {
  console.log('[MarryLink Chat] 正在加载演示数据...');

  // ---- 演示用户 ----
  const host1 = { userId: 100, userType: 'HOST', realName: '李主持', avatar: '' };
  const host2 = { userId: 101, userType: 'HOST', realName: '赵主持', avatar: '' };
  const customer1 = { userId: 200, userType: 'CUSTOMER', realName: '王新人', avatar: '' };
  const customer2 = { userId: 201, userType: 'CUSTOMER', realName: '刘新人', avatar: '' };

  // ---- 会话 1：王新人 <-> 李主持 ----
  const conv1 = {
    id: 'conv_1',
    participants: [
      { userId: customer1.userId, userType: 'CUSTOMER', userName: customer1.realName, avatar: '' },
      { userId: host1.userId, userType: 'HOST', userName: host1.realName, avatar: '' },
    ],
    lastMessage: '好的，我们婚礼当天见！',
    lastMessageTime: '2024-01-15T14:35:00.000Z',
    unreadCount: { [customer1.userId]: 1, [host1.userId]: 0 },
    createdAt: '2024-01-10T09:00:00.000Z',
  };
  conversations.set(conv1.id, conv1);
  messages.set(conv1.id, [
    {
      id: 'msg_001', conversationId: 'conv_1',
      senderId: customer1.userId, senderName: customer1.realName, senderType: 'CUSTOMER',
      content: '您好李主持，我想咨询一下婚礼主持的事情', msgType: 'text',
      timestamp: '2024-01-10T09:05:00.000Z', read: true,
    },
    {
      id: 'msg_002', conversationId: 'conv_1',
      senderId: host1.userId, senderName: host1.realName, senderType: 'HOST',
      content: '您好！很高兴为您服务，请问您的婚礼日期定了吗？', msgType: 'text',
      timestamp: '2024-01-10T09:10:00.000Z', read: true,
    },
    {
      id: 'msg_003', conversationId: 'conv_1',
      senderId: customer1.userId, senderName: customer1.realName, senderType: 'CUSTOMER',
      content: '定了，3月18号，在杭州洲际酒店', msgType: 'text',
      timestamp: '2024-01-10T09:15:00.000Z', read: true,
    },
    {
      id: 'msg_004', conversationId: 'conv_1',
      senderId: host1.userId, senderName: host1.realName, senderType: 'HOST',
      content: '好的，那个日期我有空。我们可以先见面详细聊聊您对婚礼的期望和风格偏好', msgType: 'text',
      timestamp: '2024-01-10T09:20:00.000Z', read: true,
    },
    {
      id: 'msg_005', conversationId: 'conv_1',
      senderId: customer1.userId, senderName: customer1.realName, senderType: 'CUSTOMER',
      content: '太好了！我们希望是中式风格的婚礼', msgType: 'text',
      timestamp: '2024-01-15T14:30:00.000Z', read: true,
    },
    {
      id: 'msg_006', conversationId: 'conv_1',
      senderId: host1.userId, senderName: host1.realName, senderType: 'HOST',
      content: '好的，我们婚礼当天见！', msgType: 'text',
      timestamp: '2024-01-15T14:35:00.000Z', read: false,
    },
  ]);

  // ---- 会话 2：刘新人 <-> 李主持 ----
  const conv2 = {
    id: 'conv_2',
    participants: [
      { userId: customer2.userId, userType: 'CUSTOMER', userName: customer2.realName, avatar: '' },
      { userId: host1.userId, userType: 'HOST', userName: host1.realName, avatar: '' },
    ],
    lastMessage: '请问费用怎么算呢？',
    lastMessageTime: '2024-01-14T16:20:00.000Z',
    unreadCount: { [customer2.userId]: 0, [host1.userId]: 1 },
    createdAt: '2024-01-14T16:00:00.000Z',
  };
  conversations.set(conv2.id, conv2);
  messages.set(conv2.id, [
    {
      id: 'msg_007', conversationId: 'conv_2',
      senderId: customer2.userId, senderName: customer2.realName, senderType: 'CUSTOMER',
      content: '李主持您好，朋友推荐您的，想了解一下', msgType: 'text',
      timestamp: '2024-01-14T16:05:00.000Z', read: true,
    },
    {
      id: 'msg_008', conversationId: 'conv_2',
      senderId: host1.userId, senderName: host1.realName, senderType: 'HOST',
      content: '感谢信任！请问您婚礼什么时候呢？', msgType: 'text',
      timestamp: '2024-01-14T16:10:00.000Z', read: true,
    },
    {
      id: 'msg_009', conversationId: 'conv_2',
      senderId: customer2.userId, senderName: customer2.realName, senderType: 'CUSTOMER',
      content: '请问费用怎么算呢？', msgType: 'text',
      timestamp: '2024-01-14T16:20:00.000Z', read: false,
    },
  ]);

  // ---- 会话 3：王新人 <-> 赵主持 ----
  const conv3 = {
    id: 'conv_3',
    participants: [
      { userId: customer1.userId, userType: 'CUSTOMER', userName: customer1.realName, avatar: '' },
      { userId: host2.userId, userType: 'HOST', userName: host2.realName, avatar: '' },
    ],
    lastMessage: '好的，期待合作！',
    lastMessageTime: '2024-01-13T11:00:00.000Z',
    unreadCount: { [customer1.userId]: 0, [host2.userId]: 0 },
    createdAt: '2024-01-13T10:00:00.000Z',
  };
  conversations.set(conv3.id, conv3);
  messages.set(conv3.id, [
    {
      id: 'msg_010', conversationId: 'conv_3',
      senderId: customer1.userId, senderName: customer1.realName, senderType: 'CUSTOMER',
      content: '赵主持您好，我想了解下您的主持风格', msgType: 'text',
      timestamp: '2024-01-13T10:05:00.000Z', read: true,
    },
    {
      id: 'msg_011', conversationId: 'conv_3',
      senderId: host2.userId, senderName: host2.realName, senderType: 'HOST',
      content: '好的，期待合作！', msgType: 'text',
      timestamp: '2024-01-13T11:00:00.000Z', read: true,
    },
  ]);

  console.log(`[MarryLink Chat] 演示数据加载完成：${conversations.size} 个会话，${[...messages.values()].reduce((n, m) => n + m.length, 0)} 条消息`);
}

// 加载演示数据
seedDemoData();

// ============================================================
// 启动服务器
// ============================================================
server.listen(PORT, () => {
  console.log(`[MarryLink Chat] 聊天服务器已启动，端口: ${PORT}`);
  console.log(`[MarryLink Chat] REST API: http://localhost:${PORT}/api/v1/chat`);
  console.log(`[MarryLink Chat] WebSocket: ws://localhost:${PORT}/ws?token=xxx`);
  console.log(`[MarryLink Chat] 演示令牌: host_demo / customer_demo`);
});
