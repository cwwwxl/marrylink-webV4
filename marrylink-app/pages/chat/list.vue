<template>
  <view class="chat-list-container">
    <!-- 搜索栏 -->
    <view class="search-bar">
      <view class="search-input-wrap">
        <text class="search-icon">🔍</text>
        <input
          class="search-input"
          v-model="searchText"
          placeholder="搜索联系人"
          placeholder-class="search-placeholder"
          @input="onSearch"
        />
        <text v-if="searchText" class="search-clear" @click="clearSearch">✕</text>
      </view>
    </view>

    <!-- 会话列表 -->
    <scroll-view
      class="conversation-scroll"
      scroll-y
      refresher-enabled
      :refresher-triggered="isRefreshing"
      @refresherrefresh="onRefresh"
    >
      <view v-if="filteredConversations.length > 0" class="conversation-list">
        <view
          class="conversation-item"
          v-for="item in filteredConversations"
          :key="item.id"
          @click="goToConversation(item)"
        >
          <view class="conv-avatar-wrap">
            <image
              class="conv-avatar"
              :src="item.targetAvatar || '/static/default-avatar.png'"
              mode="aspectFill"
            ></image>
            <view v-if="item.unreadCount > 0" class="conv-badge">
              {{ item.unreadCount > 99 ? '99+' : item.unreadCount }}
            </view>
          </view>
          <view class="conv-content">
            <view class="conv-header">
              <text class="conv-name">{{ item.targetName || '未知用户' }}</text>
              <text class="conv-time">{{ formatTime(item.lastMessageTime) }}</text>
            </view>
            <view class="conv-preview">
              <text class="conv-last-msg">{{ getPreviewText(item) }}</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 空状态 -->
      <view v-else class="empty-state">
        <text class="empty-icon">💬</text>
        <text class="empty-text">{{ searchText ? '未找到相关会话' : '暂无消息' }}</text>
        <text class="empty-hint">{{ searchText ? '请尝试其他关键词' : '联系主持人后会在这里显示' }}</text>
      </view>
    </scroll-view>
  </view>
</template>

<script>
import { getConversations } from '@/api/chat'
import { CHAT_WS_URL } from '@/utils/chat-request'

export default {
  data() {
    return {
      conversations: [],
      searchText: '',
      isRefreshing: false,
      socketTask: null,
      reconnectTimer: null,
      reconnectCount: 0,
      maxReconnect: 5
    }
  },

  computed: {
    filteredConversations() {
      if (!this.searchText) {
        return this.conversations
      }
      const keyword = this.searchText.toLowerCase()
      return this.conversations.filter(item => {
        return (item.targetName || '').toLowerCase().indexOf(keyword) > -1
      })
    }
  },

  onShow() {
    const token = uni.getStorageSync('token')
    if (!token) {
      uni.redirectTo({ url: '/pages/login/index' })
      return
    }
    this.loadConversations()
    this.connectWebSocket()
  },

  onHide() {
    this.closeWebSocket()
  },

  onUnload() {
    this.closeWebSocket()
  },

  methods: {
    // 加载会话列表
    async loadConversations() {
      try {
        const res = await getConversations()
        if (res.code === 200 || res.code === '00000') {
          this.conversations = res.data || []
        }
      } catch (e) {
        console.error('加载会话列表失败:', e)
      }
    },

    // 下拉刷新
    async onRefresh() {
      this.isRefreshing = true
      await this.loadConversations()
      this.isRefreshing = false
    },

    // 搜索
    onSearch() {
      // 实时过滤，通过 computed 实现
    },

    // 清除搜索
    clearSearch() {
      this.searchText = ''
    },

    // 跳转到聊天页
    goToConversation(item) {
      uni.navigateTo({
        url: `/pages/chat/conversation?conversationId=${item.id}&targetName=${encodeURIComponent(item.targetName || '聊天')}`
      })
    },

    // 获取预览文本
    getPreviewText(item) {
      if (!item.lastMessage) return ''
      if (item.lastMessageType === 'image') return '[图片]'
      return item.lastMessage
    },

    // 格式化时间
    formatTime(timestamp) {
      if (!timestamp) return ''
      const date = new Date(timestamp)
      const now = new Date()
      const diff = now - date

      // 今天：显示时间
      if (date.toDateString() === now.toDateString()) {
        const hours = String(date.getHours()).padStart(2, '0')
        const minutes = String(date.getMinutes()).padStart(2, '0')
        return `${hours}:${minutes}`
      }

      // 昨天
      const yesterday = new Date(now)
      yesterday.setDate(yesterday.getDate() - 1)
      if (date.toDateString() === yesterday.toDateString()) {
        return '昨天'
      }

      // 一周内：显示星期
      if (diff < 7 * 24 * 3600 * 1000) {
        const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
        return days[date.getDay()]
      }

      // 更早：显示日期
      const month = date.getMonth() + 1
      const day = date.getDate()
      return `${month}/${day}`
    },

    // WebSocket 连接
    connectWebSocket() {
      this.closeWebSocket()
      const token = uni.getStorageSync('token')
      if (!token) return

      try {
        this.socketTask = uni.connectSocket({
          url: `${CHAT_WS_URL}?token=${token}`,
          success: () => {
            console.log('WebSocket 连接已发起')
          }
        })

        uni.onSocketOpen(() => {
          console.log('WebSocket 已连接')
          this.reconnectCount = 0
        })

        uni.onSocketMessage((res) => {
          try {
            const data = JSON.parse(res.data)
            this.handleSocketMessage(data)
          } catch (e) {
            console.error('解析 WebSocket 消息失败:', e)
          }
        })

        uni.onSocketError(() => {
          console.error('WebSocket 连接错误')
          this.tryReconnect()
        })

        uni.onSocketClose(() => {
          console.log('WebSocket 已关闭')
        })
      } catch (e) {
        console.error('WebSocket 连接失败:', e)
      }
    },

    // 处理 WebSocket 消息
    handleSocketMessage(data) {
      if (data.type === 'new_message' || data.type === 'message') {
        // 收到新消息，刷新会话列表
        this.loadConversations()
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

    // 关闭 WebSocket
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
.chat-list-container {
  min-height: 100vh;
  background-color: #f5f7fa;
  display: flex;
  flex-direction: column;
}

.search-bar {
  background-color: #ffffff;
  padding: 20rpx 24rpx;
  border-bottom: 1rpx solid #eef0f5;

  .search-input-wrap {
    display: flex;
    align-items: center;
    background-color: #f5f7fa;
    border-radius: 36rpx;
    padding: 0 24rpx;
    height: 72rpx;

    .search-icon {
      font-size: 28rpx;
      margin-right: 12rpx;
    }

    .search-input {
      flex: 1;
      font-size: 28rpx;
      color: #333333;
      height: 72rpx;
    }

    .search-placeholder {
      color: #999999;
      font-size: 28rpx;
    }

    .search-clear {
      font-size: 28rpx;
      color: #999999;
      padding: 8rpx;
    }
  }
}

.conversation-scroll {
  flex: 1;
  height: calc(100vh - 112rpx);
}

.conversation-list {
  background-color: #ffffff;
}

.conversation-item {
  display: flex;
  align-items: center;
  padding: 24rpx 32rpx;
  border-bottom: 1rpx solid #f5f7fa;

  &:active {
    background-color: #f5f7fa;
  }

  .conv-avatar-wrap {
    position: relative;
    margin-right: 24rpx;
    flex-shrink: 0;

    .conv-avatar {
      width: 96rpx;
      height: 96rpx;
      border-radius: 50%;
      background-color: #eef0f5;
    }

    .conv-badge {
      position: absolute;
      top: -8rpx;
      right: -8rpx;
      min-width: 36rpx;
      height: 36rpx;
      line-height: 36rpx;
      padding: 0 10rpx;
      background-color: #ef4444;
      color: #ffffff;
      border-radius: 18rpx;
      font-size: 20rpx;
      text-align: center;
    }
  }

  .conv-content {
    flex: 1;
    overflow: hidden;

    .conv-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 10rpx;

      .conv-name {
        font-size: 30rpx;
        color: #333333;
        font-weight: 500;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        max-width: 400rpx;
      }

      .conv-time {
        font-size: 22rpx;
        color: #999999;
        flex-shrink: 0;
        margin-left: 16rpx;
      }
    }

    .conv-preview {
      .conv-last-msg {
        font-size: 26rpx;
        color: #999999;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        display: block;
      }
    }
  }
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding-top: 200rpx;

  .empty-icon {
    font-size: 120rpx;
    margin-bottom: 32rpx;
  }

  .empty-text {
    font-size: 32rpx;
    color: #666666;
    margin-bottom: 16rpx;
  }

  .empty-hint {
    font-size: 26rpx;
    color: #999999;
  }
}
</style>
