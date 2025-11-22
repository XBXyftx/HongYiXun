/**
 * Copyright (c) 2025 XBXyftx
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ==================== 导航相关枚举 ====================

/**
 * 导航目的地枚举
 * 
 * 定义应用内所有可导航的页面路由标识
 * 
 * @remarks
 * 用于 Navigation 组件的路由跳转，通过 navPathStack.pushPath() 使用
 * 
 * @example
 * ```typescript
 * // 跳转到文章详情页
 * navPathStack.pushPath({ name: NAV_DESTS.ARTICLE, param: articleData })
 * ```
 */
export enum NAV_DESTS {
  /** 主页面 - 包含新闻列表和标签页 */
  MAIN = 'Main',
  /** 文章详情页 - 显示具体文章内容 */
  ARTICLE = 'Article'
}

// ==================== 数据库相关枚举 ====================

/**
 * KV 数据库键枚举
 * 
 * 统一管理 KV 数据库中使用的所有键名，避免硬编码字符串
 * 
 * @remarks
 * KV 数据库用于缓存从服务器获取的数据，提升应用响应速度
 * 
 * 使用场景：
 * - 离线访问：用户无网络时可浏览缓存的新闻
 * - 快速启动：应用启动时先展示缓存数据，再从服务器更新
 * 
 * @see KVDatabase 数据库操作类
 */
export enum KV_DB_KEYS {
  /** 新闻文章列表 - 存储所有新闻文章的数组 */
  NEWS_ARTICLE_LIST = 'NewsArticleList',
  /** 新闻轮播图 - 存储轮播图图片 URL 数组 */
  NEWS_SWIPER = 'NewsSwiper',
  /** 开源鸿蒙官方动态 - 存储 OpenHarmony 官网新闻公告 */
  NEWS_OPENHARMONY_OFFICIAL = 'NewsOpenHarmonyOfficial',
  /** 开源鸿蒙技术博客 - 存储 OpenHarmony 官方技术博客文章 */
  NEWS_OPENHARMONY_BLOG = 'NewsOpenHarmonyBlog',
  /** 鸿蒙资讯 - 存储鸿蒙相关资讯（待开发） */
  NEWS_HARMONY_NEWS = 'NewsHarmonyNews',
  /** 鸿蒙开发者论坛 - 存储鸿蒙开发者论坛内容（待开发） */
  NEWS_HARMONY_FORUM = 'NewsHarmonyForum',
  /** 浏览历史记录 - 存储用户浏览过的新闻文章 */
  READING_HISTORY = 'ReadingHistory'
}

/**
 * 用户偏好设置枚举
 * 
 * 定义应用中所有可持久化的用户配置项
 * 
 * @remarks
 * 这些设置通过 PreferenceDB 存储在本地，应用重启后保持用户的个性化配置
 * 
 * 数据同步流程：
 * 1. 用户修改设置 → AppStorageV2 (运行时状态)
 * 2. UserConfigManager.syncDataToPreference() → PreferenceDB (持久化)
 * 3. 应用启动时 PreferenceDB → AppStorageV2 (恢复设置)
 * 
 * @see PreferenceDB 偏好设置数据库类
 * @see UserConfigManager 用户配置管理器
 */
export enum PreferenceEnum {
  /**
   * 深浅色模式配置
   * 
   * @remarks
   * 取值类型：0 | 1 | 2
   * - 0: 浅色模式（Light Mode） - 适合白天使用
   * - 1: 深色模式（Dark Mode） - 适合夜间使用，减少眼睛疲劳
   * - 2: 跟随系统（Follow System） - 自动跟随系统主题设置
   * 
   * @default 2
   */
  COLOR_MODE = 'ColorMode',
  
  /**
   * 文章字体大小
   * 
   * @remarks
   * 取值类型：number
   * - 合理取值区间：12-24（单位：fp）
   * - 默认值：16
   * - 影响范围：文章详情页的正文字体大小
   * 
   * 建议范围：
   * - 12-14: 较小，适合视力良好的用户
   * - 16-18: 标准大小，适合大多数用户
   * - 20-24: 较大，适合视力较弱或老年用户
   * 
   * @default 16
   */
  FONT_SIZE = 'FontSize'
}

// ==================== 设备相关枚举 ====================

/**
 * 设备类型枚举
 * 
 * 标识当前运行设备的类型，用于响应式布局和自适应 UI
 * 
 * @remarks
 * 通过 deviceInfo.deviceType 获取设备类型，应用据此调整：
 * - 布局方式（单列/多列）
 * - 组件大小
 * - 交互方式
 * - 导航模式（Stack/Split）
 * 
 * @example
 * ```typescript
 * import { deviceInfo } from '@kit.BasicServicesKit'
 * const deviceType = deviceInfo.deviceType === DEVICE_TYPES.PHONE 
 *   ? DEVICE_TYPES.PHONE 
 *   : DEVICE_TYPES.TABLET
 * ```
 */
export enum DEVICE_TYPES {
  /** 手机设备 - 屏幕较小，使用单列布局 */
  PHONE = 'phone',
  /** 平板设备 - 屏幕较大，可使用多列布局或分栏模式 */
  TABLET = 'tablet'
}

// ==================== 新闻分类枚举 ====================

/**
 * 新闻栏目类别枚举
 * 
 * 定义新闻列表中可用的栏目分类
 * 
 * @remarks
 * 用于新闻列表头部的分栏切换功能
 */
export enum NEWS_CATEGORY {
  /** 开源鸿蒙官方动态 - OpenHarmony 官网新闻公告 */
  OPENHARMONY_OFFICIAL = 'OPENHARMONY_OFFICIAL',
  /** 开源鸿蒙技术博客 - OpenHarmony 官方技术博客文章 */
  OPENHARMONY_BLOG = 'OPENHARMONY_BLOG',
  /** 鸿蒙资讯 - 鸿蒙相关资讯（待开发） */
  HARMONY_NEWS = 'HARMONY_NEWS',
  /** 鸿蒙开发者论坛 - 鸿蒙开发者论坛内容（待开发） */
  HARMONY_FORUM = 'HARMONY_FORUM'
}

/**
 * 新闻栏目信息接口
 */
export interface NewsCategoryInfo {
  /** 栏目 ID */
  id: NEWS_CATEGORY
  /** 栏目显示名称 */
  displayName: string
  /** 后端 API 的 category 参数值（待开发栏目为空字符串） */
  apiCategory: string
  /** 数据库存储键 */
  dbKey: KV_DB_KEYS
  /** 是否已开发 */
  isDeveloped: boolean
}

// ==================== 应用状态管理枚举 ====================

/**
 * AppStorageV2 键值枚举
 * 
 * 统一管理所有 AppStorageV2 的键名，确保全局状态管理的一致性
 * 
 * @remarks
 * AppStorageV2 是 HarmonyOS 提供的应用级状态管理方案：
 * - 作用域：整个应用生命周期
 * - 用途：跨页面、跨组件共享状态
 * - 响应式：状态变化自动更新 UI
 * 
 * 使用方式：
 * ```typescript
 * // 连接并获取状态
 * const config = AppStorageV2.connect(
 *   UserConfigViewModel, 
 *   APP_STORAGE_KEYS.USER_CONFIG, 
 *   () => new UserConfigViewModel()
 * )
 * ```
 * 
 * @see AppStorageV2 HarmonyOS 全局状态管理
 */
export enum APP_STORAGE_KEYS {
  /**
   * 导航路径栈
   * 
   * 存储 NavPathStack 实例，用于页面导航和路由管理
   * 
   * @type NavPathStack
   */
  NAV_PATH_STUCK = 'navPathStuck',
  
  /**
   * 用户配置视图模型
   * 
   * 存储用户的个性化配置（字体大小、颜色模式等）
   * 
   * @type UserConfigViewModel
   */
  USER_CONFIG = 'UserConfig',
  
  /**
   * 窗口宽度
   * 
   * 存储应用窗口的实际宽度（单位：px），用于响应式布局计算
   * 
   * @type WinWidth
   */
  WINDOW_WIDTH = 'Window width',
  
  /**
   * 新闻列表头部是否吸顶
   * 
   * 标识新闻列表的头部是否处于吸顶状态
   * 
   * @type NewsListHeaderIsSticky
   */
  IS_STICKY = 'isSticky',
  
  /**
   * 历史记录更新触发器
   * 
   * 用于通知历史记录页面刷新数据
   * 每次历史记录变化时递增该值
   * 
   * @type HistoryUpdateTrigger
   */
  HISTORY_UPDATE_TRIGGER = 'historyUpdateTrigger'
}

// ==================== 日志相关枚举 ====================

/**
 * 日志标签枚举
 * 
 * 统一管理所有模块的日志标签，便于日志过滤和问题定位
 * 
 * @remarks
 * 日志标签命名规范：
 * - 格式：模块名 + 冒号 + 空格
 * - 示例：'NewsManager: '
 * 
 * 使用场景：
 * ```typescript
 * logger.info(`${LOG_TAG.NEWS_MANAGER}开始获取新闻列表`)
 * logger.error(`${LOG_TAG.NEWS_MANAGER}获取新闻失败: ${error.message}`)
 * ```
 * 
 * 日志级别建议：
 * - debug: 详细的调试信息
 * - info: 一般信息，如操作成功
 * - warn: 警告信息，如使用默认值
 * - error: 错误信息，如操作失败
 * 
 * @see logger 日志工具类
 */
export enum LOG_TAG {
  // ========== Entry 模块 ==========
  /** 启动页 - 应用启动时的欢迎页面 */
  START_PAGE = 'StartPage: ',
  /** 主页面 - 应用的主要页面容器 */
  MAIN_PAGE = 'MainPage: ',
  /** 首页 - Index 页面 */
  INDEX_PAGE = 'Main: ',
  /** 应用初始化 - 应用启动时的初始化流程 */
  APP_INIT = 'AppInit: ',
  /** 入口 Ability - 应用的入口能力 */
  ENTRY_ABILITY = 'EntryAbility: ',

  // ========== Common 模块 - 工具类 ==========
  /** 断点系统 - 响应式布局断点管理 */
  BREAK_POINT_SYSTEM = 'BreakpointSystem: ',

  // ========== Common 模块 - 数据库 ==========
  /** 偏好设置数据库 - 用户配置持久化 */
  PREFERENCE_DB = 'PreferenceDB: ',
  /** KV 数据库 - 键值对数据缓存 */
  KV_DATABASE = 'KVDatabase: ',

  // ========== Common 模块 - API ==========
  /** 新闻列表 API - 获取新闻文章列表 */
  NEWS_LIST_API = 'NewsListAPI: ',
  /** 新闻轮播图 API - 获取轮播图数据 */
  NEWS_SWIPER_API = 'NewsSwiperAPI: ',
  /** 服务器健康检查 API - 检测后端服务状态 */
  SERVER_HEALTH_API = 'ServerHealthAPI: ',
  /** 轮播图状态 API - 获取轮播图开关状态 */
  SWIPER_STATE_API = 'SwiperStateAPI: ',
  /** Axios HTTP - HTTP 请求客户端 */
  AXIOS_HTTP = 'AxiosHttp: ',

  // ========== Feature 模块 - 组件 ==========
  /** 新闻列表组件 - 展示新闻文章列表 */
  NEWS_LIST = 'NewsList: ',
  /** 字体大小调整按钮 - 文章字体大小设置 */
  FONT_SIZE_ADJUST_BUTTON = 'FontSizeAdjustButton: ',
  /** 颜色模式选择按钮 - 深浅色主题切换 */
  COLOR_MOD_CHOSE_BUTTON = 'ColorModChoseButton: ',

  // ========== Feature 模块 - 管理器 ==========
  /** 颜色模式管理器 - 管理应用主题切换 */
  COLOR_MOD_MANAGER = 'ColorModManager: ',
  /** 新闻管理器 - 管理新闻数据的获取和缓存 */
  NEWS_MANAGER = 'NewsManager: ',
  /** 用户配置管理器 - 管理用户个性化设置 */
  USER_CONFIG_MANAGER = 'UserConfigManager: ',
  /** 历史记录管理器 - 管理用户浏览历史 */
  HISTORY_MANAGER = 'HistoryManager: '
}
