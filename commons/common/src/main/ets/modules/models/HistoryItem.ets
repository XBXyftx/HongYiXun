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
 * 历史记录项接口
 * 
 * 用于存储用户浏览新闻的历史记录信息
 * 
 * @interface HistoryItem
 * 
 * @remarks
 * 历史记录特点：
 * - 自动记录：用户打开文章时自动添加
 * - 去重机制：同一文章只保留最新的浏览记录
 * - 时间排序：按浏览时间倒序排列
 * - 数量限制：最多保存 100 条记录
 * 
 * 存储位置：
 * - KV 数据库键：KV_DB_KEYS.READING_HISTORY
 * - 数据格式：JSON 字符串数组
 * 
 * @example
 * ```typescript
 * const historyItem: HistoryItem = {
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
 * @see HistoryManager 历史记录管理器
 * @see NewsArticle 新闻文章数据模型
 */
export interface HistoryItem {
  /** 
   * 新闻文章数据
   * 
   * 包含文章的完整信息，用于显示和跳转
   */
  article: NewsArticle
  
  /** 
   * 浏览时间戳
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
