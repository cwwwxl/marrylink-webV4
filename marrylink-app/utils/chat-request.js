// 聊天服务独立请求工具
// 聊天服务运行在独立端口 3001

const getChatBaseUrl = () => {
  const isDev = process.env.NODE_ENV === 'development'
  if (isDev) {
    return 'http://localhost:3001/api/v1'
  } else {
    return '/chat-api'
  }
}

export const CHAT_BASE_URL = getChatBaseUrl()

export const CHAT_WS_URL = (() => {
  const isDev = process.env.NODE_ENV === 'development'
  if (isDev) {
    return 'ws://localhost:3001/ws'
  } else {
    // 生产环境通过 nginx 代理
    const protocol = 'wss'
    return `${protocol}://${location.host}/chat-ws`
  }
})()

/**
 * 聊天服务请求方法
 */
function chatRequest(options) {
  return new Promise((resolve, reject) => {
    const token = uni.getStorageSync('token')

    uni.request({
      url: CHAT_BASE_URL + options.url,
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
          resolve(res.data)
        } else if (res.statusCode === 401) {
          uni.showToast({
            title: '未认证，请先登录',
            icon: 'none'
          })
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
