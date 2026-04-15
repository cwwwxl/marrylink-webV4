// 聊天服务请求工具
// 聊天 API 集成在主后端中，共用同一个 API 地址

import { BASE_URL } from '@/utils/request'

// WebSocket 地址 (直连后端 WebSocket 端点)
export const CHAT_WS_URL = (() => {
  const isDev = process.env.NODE_ENV === 'development'
  if (isDev) {
    return 'ws://localhost:8080/api/v1/ws/chat'
  } else {
    // 生产环境通过 nginx 代理
    const protocol = location.protocol === 'https:' ? 'wss' : 'ws'
    return `${protocol}://${location.host}/app-api/ws/chat`
  }
})()

// REST API 基础地址（复用主后端地址）
export const CHAT_BASE_URL = BASE_URL

/**
 * 聊天服务请求方法
 */
function chatRequest(options) {
  return new Promise((resolve, reject) => {
    const token = uni.getStorageSync('token')

    uni.request({
      url: BASE_URL + options.url,
      method: options.method || 'GET',
      data: options.data || {},
      header: {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : '',
        ...options.header
      },
      timeout: options.timeout || 30000,
      success: (res) => {
        if (res.statusCode === 200) {
          const data = res.data
          // 兼容 Spring Boot 返回格式 { code: "00000", data: ... }
          if (data.code === 200 || data.code === '00000') {
            resolve(data)
          } else if (data.code === 401 || data.code === '401') {
            uni.showToast({ title: '未认证，请先登录', icon: 'none' })
            uni.removeStorageSync('token')
            uni.removeStorageSync('userInfo')
            setTimeout(() => {
              uni.reLaunch({ url: '/pages/login/index' })
            }, 1500)
            reject(data)
          } else {
            reject(data)
          }
        } else if (res.statusCode === 401) {
          uni.showToast({ title: '未认证，请先登录', icon: 'none' })
          uni.removeStorageSync('token')
          uni.removeStorageSync('userInfo')
          setTimeout(() => {
            uni.reLaunch({ url: '/pages/login/index' })
          }, 1500)
          reject(res)
        } else {
          reject(res)
        }
      },
      fail: (err) => {
        reject(err)
      }
    })
  })
}

/**
 * GET 请求
 */
export function chatGet(url, data = {}) {
  return chatRequest({ url, method: 'GET', data })
}

/**
 * POST 请求
 */
export function chatPost(url, data = {}) {
  return chatRequest({ url, method: 'POST', data })
}

export default chatRequest
