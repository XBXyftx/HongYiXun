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

/**
 * 导航目的地枚举
 */
export enum NAV_DESTS {
  MAIN = 'Main',
  ARTICLE = 'Article'
}

/**
 * KV数据库键枚举
 */
export enum KV_DB_KEYS {
  NEWS_ARTICLE_LIST = 'NewsArticleList',
  NEWS_SWIPER = 'NewsSwiper'
}

/**
 * 用户偏好设置枚举
 */
export enum PreferenceEnum {
  /**
   * 深浅色模式
   * 0 浅色模式
   * 1 深色模式
   * 2 跟随系统
   */
  COLOR_MODE = 'ColorMode',
  /**
   * 文章字体大小
   * 合理取值区间12-24
   * 默认16
   */
  FONT_SIZE = 'FontSize'
}

/**
 * 设备类型枚举
 */
export enum DEVICE_TYPES {
  PHONE = 'phone',
  TABLET = 'tablet'
}

/**
 * AppStorageV2 键值枚举 - 统一管理所有 AppStorageV2 的键值
 */
export enum APP_STORAGE_KEYS {
  /**
   * 导航路径栈
   */
  NAV_PATH_STUCK = 'navPathStuck',
  /**
   * 用户配置
   */
  USER_CONFIG = 'UserConfig',
  /**
   * 窗口宽度
   */
  WINDOW_WIDTH = 'Window width',
  /**
   * 是否粘性
   */
  IS_STICKY = 'isSticky'
}

/**
 * 日志标签枚举 - 统一管理所有模块的日志标签
 */
export enum LOG_TAG {
  // Entry模块
  START_PAGE = 'StartPage: ',
  MAIN_PAGE = 'MainPage: ',
  INDEX_PAGE = 'Main: ',
  APP_INIT = 'AppInit: ',
  ENTRY_ABILITY = 'EntryAbility: ',

  // Common模块 - 工具类
  BREAK_POINT_SYSTEM = 'BreakpointSystem: ',

  // Common模块 - 数据库
  PREFERENCE_DB = 'PreferenceDB: ',
  KV_DATABASE = 'KVDatabase: ',

  // Common模块 - API
  NEWS_LIST_API = 'NewsListAPI: ',
  NEWS_SWIPER_API = 'NewsSwiperAPI: ',
  SERVER_HEALTH_API = 'ServerHealthAPI: ',
  SWIPER_STATE_API = 'SwiperStateAPI: ',
  AXIOS_HTTP = 'AxiosHttp: ',

  // Feature模块 - 组件
  NEWS_LIST = 'NewsList: ',
  FONT_SIZE_ADJUST_BUTTON = 'FontSizeAdjustButton: ',
  COLOR_MOD_CHOSE_BUTTON = 'ColorModChoseButton: ',

  // Feature模块 - 管理器
  COLOR_MOD_MANAGER = 'ColorModManager: ',
  NEWS_MANAGER = 'NewsManager: ',
  USER_CONFIG_MANAGER = 'UserConfigManager: '
}
