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
 * 点赞项接口
 * 
 * 用于存储用户点赞新闻的信息
 * 
 * @interface LikeItem
 */
export interface LikeItem {
  /** 新闻文章数据 */
  article: NewsArticle
  /** 点赞时间戳 */
  timestamp: number
  /** 格式化的日期字符串 */
  dateStr: string
}
