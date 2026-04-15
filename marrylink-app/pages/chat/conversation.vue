<template>
  <view class="chat-container">
    <!-- 消息列表区域 -->
    <scroll-view
      class="message-scroll"
      scroll-y
      :scroll-into-view="scrollToId"
      :scroll-with-animation="scrollAnimation"
      refresher-enabled
      :refresher-triggered="isLoadingMore"
      @refresherrefresh="loadMoreMessages"
    >
      <!-- 加载更多提示 -->
      <view v-if="noMoreMessages" class="load-more-tip">
        <text class="load-more-text">没有更多消息了</text>
      </view>

      <!-- 消息列表 -->
      <view
        v-for="(msg, index) in messages"
        :key="msg.id || index"
        :id="'msg-' + (msg.id || index)"
      >
        <!-- 时间分隔线 -->
        <view v-if="shouldShowTime(msg, index)" class="time-divider">
          <text class="time-text">{{ formatMessageTime(msg.createdAt) }}</text>
        </view>

        <!-- 消息气泡 -->
        <view class="message-row" :class="{ 'message-row-right': msg.isSelf }">
          <!-- 对方头像（左） -->
          <image
            v-if="!msg.isSelf"
            class="msg-avatar"
            :src="targetAvatar || '/static/default-avatar.png'"
            mode="aspectFill"
          ></image>

          <!-- 消息内容 -->
          <view class="msg-bubble" :class="msg.isSelf ? 'bubble-self' : 'bubble-other'">
            <!-- 文本消息 -->
            <text v-if="msg.type === 'text'" class="msg-text">{{ msg.content }}</text>
            <!-- 图片消息 -->
            <image
              v-else-if="msg.type === 'image'"
              class="msg-image"
              :src="msg.content"
              mode="widthFix"
              @click="previewImage(msg.content)"
            ></image>
            <!-- 默认当文本处理 -->
            <text v-else class="msg-text">{{ msg.content }}</text>
          </view>

          <!-- 自己头像（右） -->
          <image
            v-if="msg.isSelf"
            class="msg-avatar"
            :src="myAvatar || '/static/default-avatar.png'"
            mode="aspectFill"
          ></image>
        </view>
      </view>

      <!-- 底部占位 -->
      <view class="scroll-bottom-spacer" id="scroll-bottom"></view>
    </scroll-view>

    <!-- 输入区域 -->
    <view class="input-bar" :style="{ paddingBottom: safeAreaBottom + 'px' }">
      <view class="input-row">
        <view class="input-wrap">
          <input
            class="msg-input"
            v-model="inputText"
            placeholder="输入消息..."
            placeholder-class="input-placeholder"
            confirm-type="send"
            :adjust-position="true"
            @confirm="sendTextMessage"
          />
        </view>
        <view class="input-actions">
          <view class="action-btn" @click="chooseImage">
            <text class="action-icon">🖼️</text>
          </view>
          <view
            class="send-btn"
            :class="{ 'send-btn-active': inputText.trim() }"
            @click="sendTextMessage"
          >
            <text class="send-text">发送</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script>
import { getMessages } from '@/api/chat'
import { CHAT_WS_URL, CHAT_BASE_URL } from '@/utils/chat-request'
import { mapState } from 'vuex'

export default {
  data() {
    return {
      conversationId: '',
      targetName: '',
      targetAvatar: '',
      messages: [],
      inputText: '',
      scrollToId: '',
      scrollAnimation: false,
      isLoadingMore: false,
      noMoreMessages: false,
      page: 1,
      pageSize: 20,
      socketTask: null,
      reconnectTimer: null,
      reconnectCount: 0,
      maxReconnect: 5,
      safeAreaBottom: 0
    }
  },

  computed: {
    ...mapState('user', ['userInfo']),

    myAvatar() {
      if (!this.userInfo || !this.userInfo.avatar) return '/static/default-avatar.png'
      if (this.userInfo.avatar.startsWith('http')) return this.userInfo.avatar
      return this.userInfo.avatar
    }
  },

  onLoad(options) {
    this.conversationId = options.conversationId || ''
    this.targetName = decodeURIComponent(options.targetName || '聊天')
    this.targetAvatar = options.targetAvatar ? decodeURIComponent(options.targetAvatar) : ''

    // 设置导航栏标题
    uni.setNavigationBarTitle({ title: this.targetName })

    // 获取安全区域
    const systemInfo = uni.getSystemInfoSync()
    this.safeAreaBottom = systemInfo.safeAreaInsets ? systemInfo.safeAreaInsets.bottom : 0

    const token = uni.getStorageSync('token')
    if (!token) {
      uni.redirectTo({ url: '/pages/login/index' })
      return
    }

    this.loadMessages()
    this.connectWebSocket()
  },

  onUnload() {
    this.closeWebSocket()
  },

  methods: {
    // 加载消息
    async loadMessages() {
      try {
        const res = await getMessages(this.conversationId, {
          page: this.page,
          pageSize: this.pageSize
        })
        if (res.code === 200 || res.code === '00000') {
          const list = res.data || []
          if (list.length < this.pageSize) {
            this.noMoreMessages = true
          }
          this.messages = list.reverse()
          this.$nextTick(() => {
            this.scrollToBottom()
          })
        }
      } catch (e) {
        console.error('加载消息失败:', e)
      }
    },

    // 加载更多（下拉）
    async loadMoreMessages() {
      if (this.noMoreMessages) {
        this.isLoadingMore = false
        return
      }
      this.isLoadingMore = true
      this.page++
      try {
        const res = await getMessages(this.conversationId, {
          page: this.page,
          pageSize: this.pageSize
        })
        if (res.code === 200 || res.code === '00000') {
          const list = res.data || []
          if (list.length < this.pageSize) {
            this.noMoreMessages = true
          }
          this.messages = [...list.reverse(), ...this.messages]
        }
      } catch (e) {
        console.error('加载更多消息失败:', e)
        this.page--
      }
      this.isLoadingMore = false
    },

    // 发送文本消息
    sendTextMessage() {
      const text = this.inputText.trim()
      if (!text) return

      const msg = {
        type: 'text',
        content: text,
        conversationId: this.conversationId
      }

      this.sendSocketMsg({
        action: 'send_message',
        data: msg
      })

      // 本地先添加消息
      this.messages.push({
        id: 'local_' + Date.now(),
        type: 'text',
        content: text,
        isSelf: true,
        createdAt: new Date().toISOString(),
        status: 'sending'
      })

      this.inputText = ''
      this.$nextTick(() => {
        this.scrollToBottom()
      })
    },

    // 选择图片
    chooseImage() {
      uni.chooseImage({
        count: 1,
        sizeType: ['compressed'],
        sourceType: ['album', 'camera'],
        success: (res) => {
          const tempFilePath = res.tempFilePaths[0]
          this.uploadAndSendImage(tempFilePath)
        }
      })
    },

    // 上传并发送图片
    uploadAndSendImage(filePath) {
      const token = uni.getStorageSync('token')

      // 本地先显示
      const localId = 'local_img_' + Date.now()
      this.messages.push({
        id: localId,
        type: 'image',
        content: filePath,
        isSelf: true,
        createdAt: new Date().toISOString(),
        status: 'sending'
      })
      this.$nextTick(() => {
        this.scrollToBottom()
      })

      uni.uploadFile({
        url: CHAT_BASE_URL + '/chat/upload',
        filePath: filePath,
        name: 'file',
        header: {
          'Authorization': token ? `Bearer ${token}` : ''
        },
        success: (uploadRes) => {
          try {
            const data = JSON.parse(uploadRes.data)
            if (data.code === 200 || data.code === '00000') {
              const imageUrl = data.data.url || data.data
              // 通过 WebSocket 发送图片消息
              this.sendSocketMsg({
                action: 'send_message',
                data: {
                  type: 'image',
                  content: imageUrl,
                  conversationId: this.conversationId
                }
              })
              // 更新本地消息 URL
              const localMsg = this.messages.find(m => m.id === localId)
              if (localMsg) {
                localMsg.content = imageUrl
                localMsg.status = 'sent'
              }
            }
          } catch (e) {
            console.error('解析上传结果失败:', e)
          }
        },
        fail: (err) => {
          console.error('上传图片失败:', err)
          uni.showToast({ title: '图片发送失败', icon: 'none' })
        }
      })
    },

    // 预览图片
    previewImage(url) {
      const imageUrls = this.messages
        .filter(m => m.type === 'image')
        .map(m => m.content)
      uni.previewImage({
        current: url,
        urls: imageUrls.length > 0 ? imageUrls : [url]
      })
    },

    // 滚动到底部
    scrollToBottom() {
      this.scrollAnimation = true
      this.scrollToId = 'scroll-bottom'
      // 需要重置再设置才能触发滚动
      this.$nextTick(() => {
        this.scrollToId = ''
        this.$nextTick(() => {
          this.scrollToId = 'scroll-bottom'
        })
      })
    },

    // 是否显示时间
    shouldShowTime(msg, index) {
      if (index === 0) return true
      const prev = this.messages[index - 1]
      if (!prev || !prev.createdAt || !msg.createdAt) return false
      const diff = new Date(msg.createdAt) - new Date(prev.createdAt)
      return diff > 5 * 60 * 1000 // 5分钟
    },

    // 格式化消息时间
    formatMessageTime(timestamp) {
      if (!timestamp) return ''
      const date = new Date(timestamp)
      const now = new Date()

      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const timeStr = `${hours}:${minutes}`

      if (date.toDateString() === now.toDateString()) {
        return timeStr
      }

      const yesterday = new Date(now)
      yesterday.setDate(yesterday.getDate() - 1)
      if (date.toDateString() === yesterday.toDateString()) {
        return `昨天 ${timeStr}`
      }

      const month = date.getMonth() + 1
      const day = date.getDate()
      return `${month}月${day}日 ${timeStr}`
    },

    // WebSocket 连接
    connectWebSocket() {
      this.closeWebSocket()
      const token = uni.getStorageSync('token')
      if (!token) return

      try {
        this.socketTask = uni.connectSocket({
          url: `${CHAT_WS_URL}?token=${token}&conversationId=${this.conversationId}`,
          success: () => {
            console.log('聊天 WebSocket 连接已发起')
          }
        })

        uni.onSocketOpen(() => {
          console.log('聊天 WebSocket 已连接')
          this.reconnectCount = 0
        })

        uni.onSocketMessage((res) => {
          try {
            const data = JSON.parse(res.data)
            this.handleSocketMessage(data)
          } catch (e) {
            console.error('解析消息失败:', e)
          }
        })

        uni.onSocketError(() => {
          console.error('聊天 WebSocket 错误')
          this.tryReconnect()
        })

        uni.onSocketClose(() => {
          console.log('聊天 WebSocket 已关闭')
        })
      } catch (e) {
        console.error('WebSocket 连接失败:', e)
      }
    },

    // 处理收到的消息
    handleSocketMessage(data) {
      if (data.type === 'message' || data.type === 'new_message') {
        const msg = data.data || data.message || data
        // 确保消息属于当前会话
        if (msg.conversationId && msg.conversationId !== this.conversationId) return

        this.messages.push({
          id: msg.id || 'remote_' + Date.now(),
          type: msg.type || msg.messageType || 'text',
          content: msg.content,
          isSelf: false,
          createdAt: msg.createdAt || new Date().toISOString()
        })
        this.$nextTick(() => {
          this.scrollToBottom()
        })
      }
    },

    // 发送 WebSocket 消息
    sendSocketMsg(data) {
      try {
        uni.sendSocketMessage({
          data: JSON.stringify(data)
        })
      } catch (e) {
        console.error('发送 WebSocket 消息失败:', e)
        uni.showToast({ title: '消息发送失败', icon: 'none' })
      }
    },

    // 重连
    tryReconnect() {
      if (this.reconnectCount >= this.maxReconnect) return
      this.reconnectCount++
      clearTimeout(this.reconnectTimer)
      this.reconnectTimer = setTimeout(() => {
        this.connectWebSocket()
      }, 3000 * this.reconnectCount)
    },

    // 关闭连接
    closeWebSocket() {
      clearTimeout(this.reconnectTimer)
      if (this.socketTask) {
        try {
          uni.closeSocket()
        } catch (e) {
          // ignore
        }
        this.socketTask = null
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: #f5f7fa;
}

.message-scroll {
  flex: 1;
  padding: 20rpx 24rpx;
  box-sizing: border-box;
}

.load-more-tip {
  text-align: center;
  padding: 20rpx 0;

  .load-more-text {
    font-size: 24rpx;
    color: #999999;
  }
}

.time-divider {
  text-align: center;
  padding: 20rpx 0;

  .time-text {
    font-size: 22rpx;
    color: #999999;
    background-color: #e8eaed;
    padding: 6rpx 20rpx;
    border-radius: 20rpx;
  }
}

.message-row {
  display: flex;
  align-items: flex-start;
  margin-bottom: 24rpx;

  &.message-row-right {
    flex-direction: row-reverse;
  }

  .msg-avatar {
    width: 80rpx;
    height: 80rpx;
    border-radius: 50%;
    flex-shrink: 0;
    background-color: #e8eaed;
  }

  .msg-bubble {
    max-width: 520rpx;
    padding: 20rpx 28rpx;
    border-radius: 20rpx;
    word-break: break-all;

    &.bubble-self {
      background-color: #1d4ed8;
      margin-right: 16rpx;
      border-top-right-radius: 4rpx;

      .msg-text {
        color: #ffffff;
      }
    }

    &.bubble-other {
      background-color: #ffffff;
      margin-left: 16rpx;
      border-top-left-radius: 4rpx;

      .msg-text {
        color: #333333;
      }
    }
  }

  .msg-text {
    font-size: 30rpx;
    line-height: 1.6;
  }

  .msg-image {
    max-width: 400rpx;
    min-width: 200rpx;
    border-radius: 12rpx;
  }
}

.scroll-bottom-spacer {
  height: 20rpx;
}

.input-bar {
  background-color: #ffffff;
  border-top: 1rpx solid #eef0f5;
  padding: 16rpx 24rpx;

  .input-row {
    display: flex;
    align-items: center;

    .input-wrap {
      flex: 1;
      background-color: #f5f7fa;
      border-radius: 36rpx;
      padding: 0 28rpx;
      height: 72rpx;
      display: flex;
      align-items: center;

      .msg-input {
        width: 100%;
        height: 72rpx;
        font-size: 28rpx;
        color: #333333;
      }

      .input-placeholder {
        color: #999999;
        font-size: 28rpx;
      }
    }

    .input-actions {
      display: flex;
      align-items: center;
      margin-left: 16rpx;

      .action-btn {
        width: 72rpx;
        height: 72rpx;
        display: flex;
        align-items: center;
        justify-content: center;

        .action-icon {
          font-size: 44rpx;
        }
      }

      .send-btn {
        background-color: #93c5fd;
        border-radius: 36rpx;
        padding: 0 28rpx;
        height: 72rpx;
        display: flex;
        align-items: center;
        justify-content: center;

        &.send-btn-active {
          background-color: #1d4ed8;
        }

        .send-text {
          color: #ffffff;
          font-size: 28rpx;
          font-weight: 500;
        }
      }
    }
  }
}
</style>
