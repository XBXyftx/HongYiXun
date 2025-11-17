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

import { curves } from "@kit.ArkUI";
import { NAV_DESTS, KV_DB_KEYS, PreferenceEnum, DEVICE_TYPES, APP_STORAGE_KEYS } from './enums';

// ==================== 动画参数配置 ====================

/**
 * 新闻列表项入场动画参数
 * 
 * 用于新闻列表项目的转场动画效果配置
 * - 透明度渐变：从完全透明到完全不透明
 * - 缩放效果：从 0.5 倍缩放至原始大小
 * - 动画曲线：使用弹簧运动曲线，提供更自然的动画效果
 * 
 * @param response - 响应速度参数 0.5（较快响应）
 * @param dampingFraction - 阻尼系数 0.7（适中的阻尼，有轻微回弹效果）
 */
export const NEWS_LIST_ITEM_ANIMATE_PARAM = TransitionEffect.OPACITY
  .combine(TransitionEffect.scale({ x: 0.5, y: 0.5 }))
  .animation({ curve: curves.springMotion(0.5, 0.7) })
;

/**
 * 新闻列表滚动动画参数
 * 
 * 用于新闻列表滚动时的动画配置
 * - 曲线：EaseInOut 缓入缓出效果
 * - 时长：200ms 快速响应
 * 
 * 适用场景：
 * - 列表滚动到指定位置
 * - 列表项展开/收起动画
 */
export const NEWS_LIST_ANIMATION_PARAM: AnimateParam = {
  curve: Curve.EaseInOut,
  duration: 200,
}

// ==================== 枚举导出 ====================

/**
 * 统一导出所有枚举类型
 * 
 * 包含：
 * - NAV_DESTS: 导航目的地枚举
 * - KV_DB_KEYS: KV数据库键枚举
 * - PreferenceEnum: 用户偏好设置枚举
 * - DEVICE_TYPES: 设备类型枚举
 * - APP_STORAGE_KEYS: AppStorageV2 键值枚举
 */
export { NAV_DESTS, KV_DB_KEYS, PreferenceEnum, DEVICE_TYPES, APP_STORAGE_KEYS }

// ==================== 服务器配置 ====================

/**
 * 后端服务器基础地址
 * 
 * 用于所有 HTTP 请求的基础 URL
 * 
 * @example
 * ```typescript
 * const apiUrl = `${SERVE_BASE_ADDRESS}/api/news`
 * ```
 * 
 * @remarks
 * 生产环境部署时需要修改为实际的服务器地址
 */
export const SERVE_BASE_ADDRESS = 'http://113.47.8.204:32776'

// ==================== 应用默认配置 ====================

/**
 * 默认字体大小（单位：fp）
 * 
 * 用于文章内容显示的基础字体大小
 * 
 * @remarks
 * - 合理取值区间：12-24
 * - 用户可在设置中调整此值
 * - 影响范围：文章详情页的文字显示
 */
export const DEFAULT_FONT_SIZE = 16

/**
 * 默认颜色模式
 * 
 * 应用启动时的默认主题模式
 * 
 * @remarks
 * 取值说明：
 * - 0: 浅色模式（Light Mode）
 * - 1: 深色模式（Dark Mode）
 * - 2: 跟随系统（Follow System）
 * 
 * @default 2 (跟随系统)
 */
export const DEFAULT_COLOR_MODE = 2

// ==================== 数据库配置 ====================

/**
 * 应用 KV 数据库名称
 * 
 * 用于初始化和访问 KV（Key-Value）数据库
 * 
 * @remarks
 * 存储内容：
 * - 新闻文章列表缓存
 * - 轮播图数据缓存
 * - 其他需要持久化的键值对数据
 * 
 * @see KVDatabase 数据库操作类
 */
export const APP_KV_DB = 'HongYiXunKVDB'

// ==================== 系统标识符 ====================

/**
 * 断点系统实例标识符
 * 
 * 用于在 AppStorageV2 中存储和获取 BreakpointSystem 实例
 * 
 * @remarks
 * 断点系统用于响应式布局，根据屏幕尺寸自动调整 UI
 * 
 * 断点分类：
 * - xs: 超小屏幕（手机竖屏）
 * - sm: 小屏幕（手机横屏）
 * - md: 中等屏幕（小平板）
 * - lg: 大屏幕（大平板）
 * - xl: 超大屏幕（桌面）
 * 
 * @see BreakpointSystem 断点系统实现
 */
export const GET_BREAK_POINT_SYSTEM = 'getBreakpointSystem'