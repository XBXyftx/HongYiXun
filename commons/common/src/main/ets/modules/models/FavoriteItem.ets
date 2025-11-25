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

import { NewsArticle } from './NewsArticle'

/**
 * 收藏项接口
 * 
 * 用于存储用户收藏新闻的信息
 * 
 * @interface FavoriteItem
 * 
 * @remarks
 * 收藏功能特点：
 * - 手动添加：用户主动点击收藏按钮
 * - 去重机制：同一文章不会重复收藏
 * - 时间排序：按收藏时间倒序排列
 * - 数量限制：最多保存 200 条记录
 * 
 * 存储位置：
 * - KV 数据库键：KV_DB_KEYS.FAVORITE_LIST
 * - 数据格式：JSON 字符串数组
 * 
 * 与历史记录的区别：
 * - 收藏：用户主动操作，重要内容保存
 * - 历史：自动记录，浏览轨迹追踪
 * 
 * @example
 * ```typescript
 * const favoriteItem: FavoriteItem = {
 *   article: {
 *     id: "news_001",
 *     title: "鸿蒙系统最新更新",
 *     date: "2025-01-15",
 *     url: "https://example.com/news/001",
 *     content: [...],
 *     source: "官方资讯"
 *   },
 *   timestamp: 1705123456789,
 *   dateStr: "2025-01-15 14:30:56"
 * }
 * ```
 * 
 * @see FavoriteManager 收藏管理器
 * @see NewsArticle 新闻文章数据模型
 */
export interface FavoriteItem {
  /** 
   * 新闻文章数据
   * 
   * 包含文章的完整信息，用于显示和跳转
   */
  article: NewsArticle
  
  /** 
   * 收藏时间戳
   * 
   * Unix 时间戳（毫秒），用于排序和时间计算
   * 
   * @example 1705123456789
   */
  timestamp: number
  
  /** 
   * 格式化的日期字符串
   * 
   * 用于界面显示的友好时间格式
   * 
   * @example "2025-01-15 14:30:56"
   */
  dateStr: string
}
