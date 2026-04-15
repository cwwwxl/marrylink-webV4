import type { RouteRecordRaw } from 'vue-router'

export const Layout = () => import('@/layout/index.vue')

// 婚礼智配路由
export const marrylinkRoutes: RouteRecordRaw[] = [
  {
    path: '/marrylink',
    component: Layout,
    redirect: '/marrylink/questionnaire',
    name: 'Marrylink',
    meta: {
      title: '婚礼智配',
      icon: 'homepage',
      alwaysShow: true
    },
    children: [
      {
        path: 'chat',
        name: 'ChatManage',
        component: () => import('@/views/marrylink/chat/index.vue'),
        meta: {
          title: '实时对话',
        }
      },
      {
        path: 'host',
        name: 'HostManage',
        component: () => import('@/views/marrylink/host/index.vue'),
        meta: {
          title: '主持人管理',
        }
      },
      {
        path: 'user',
        name: 'UserManage',
        component: () => import('@/views/marrylink/user/index.vue'),
        meta: {
          title: '用户管理',
        }
      },
      {
        path: 'order',
        name: 'OrderManage',
        component: () => import('@/views/marrylink/order/index.vue'),
        meta: {
          title: '订单管理',
        }
      },
      {
        path: 'order-log',
        name: 'OrderLogManage',
        component: () => import('@/views/marrylink/order-log/index.vue'),
        meta: {
          title: '日志管理',
        }
      },
      {
        path: 'schedule',
        name: 'ScheduleManage',
        component: () => import('@/views/marrylink/schedule/index.vue'),
        meta: {
          title: '档期管理',
        }
      },
      {
        path: 'tag',
        name: 'TagManage',
        component: () => import('@/views/marrylink/tag/index.vue'),
        meta: {
          title: '标签管理',
        }
      },
      {
        path: 'questionnaire',
        name: 'QuestionnaireManage',
        component: () => import('@/views/marrylink/questionnaire/index.vue'),
        meta: {
          title: '问卷管理',
        }
      },
      {
        path: 'user-questionnaire',
        name: 'UserQuestionnaire',
        component: () => import('@/views/marrylink/user-questionnaire/index.vue'),
        meta: {
          title: '我的问卷',
        }
      },
      {
        path: 'user-questionnaire/fill',
        name: 'UserQuestionnaireFill',
        component: () => import('@/views/marrylink/user-questionnaire/fill.vue'),
        meta: {
          title: '填写问卷',
          hidden: true
        }
      }
    ]
  }
]