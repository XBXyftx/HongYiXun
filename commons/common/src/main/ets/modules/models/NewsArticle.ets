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
 * 内容类型枚举
 * 
 * 定义新闻文章中支持的内容块类型
 * 
 * @enum CONTENT_TYPE_ENUM
 */
export enum CONTENT_TYPE_ENUM {
  /** 文本内容 */
  TEXT = "text",
  /** 图片内容 */
  IMAGE = "image",
  /** 视频内容 */
  VIDEO = "video",
  /** 代码内容 */
  CODE = "code"
}

/**
 * 新闻内容块接口
 * 
 * 定义新闻文章中单个内容块的结构
 * 
 * @interface NewsContentBlock
 * 
 * @remarks
 * 新闻文章由多个内容块组成，每个内容块可以是文本、图片、视频或代码
 * 
 * @example
 * ```typescript
 * // 文本块
 * const textBlock: NewsContentBlock = {
 *   type: CONTENT_TYPE_ENUM.TEXT,
 *   value: "这是一段新闻正文内容"
 * }
 * 
 * // 图片块
 * const imageBlock: NewsContentBlock = {
 *   type: CONTENT_TYPE_ENUM.IMAGE,
 *   value: "https://example.com/image.jpg"
 * }
 * ```
 */
export interface NewsContentBlock {
  /** 
   * 内容类型
   * 
   * 使用 CONTENT_TYPE_ENUM 枚举值
   */
  type: CONTENT_TYPE_ENUM
  
  /** 
   * 内容值
   * 
   * 根据类型不同，值的含义也不同：
   * - TEXT: 文本内容
   * - IMAGE: 图片 URL
   * - VIDEO: 视频 URL
   * - CODE: 代码字符串
   */
  value: string
}

/**
 * 新闻文章类
 * 
 * 定义完整新闻文章的数据结构
 * 
 * @class NewsArticle
 * 
 * @remarks
 * 使用 @ObservedV2 装饰器实现响应式数据更新
 * 
 * 数据来源：
 * - 从后端 API 获取
 * - 从本地 KV 数据库缓存读取
 * 
 * 使用场景：
 * - 新闻列表展示
 * - 文章详情页显示
 * - 历史记录和收藏功能
 * 
 * @example
 * ```typescript
 * const article = new NewsArticle()
 * article.id = "news_001"
 * article.title = "鸿蒙系统最新更新"
 * article.date = "2025-01-15"
 * article.url = "https://example.com/news/001"
 * article.content = [
 *   { type: CONTENT_TYPE_ENUM.TEXT, value: "正文内容" },
 *   { type: CONTENT_TYPE_ENUM.IMAGE, value: "https://example.com/image.jpg" }
 * ]
 * article.source = "官方资讯"
 * ```
 */
@ObservedV2
export class NewsArticle {
  /** 
   * 文章唯一标识符
   * 
   * 用于去重和数据库查询
   */
  @Trace id: string = ''
  
  /** 
   * 文章标题
   * 
   * 显示在列表和详情页的标题
   */
  title: string = ''
  
  /** 
   * 发布日期
   * 
   * 格式：YYYY-MM-DD
   * 
   * @example "2025-01-15"
   */
  date: string = ''
  
  /** 
   * 文章原链接
   * 
   * 指向原始新闻页面的 URL
   */
  url: string = ''
  
  /** 
   * 文章内容块数组
   * 
   * 由多个 NewsContentBlock 组成，支持富文本内容
   */
  content: NewsContentBlock[] = []
  
  /** 
   * 文章分类（可选）
   * 
   * 新闻所属的分类标签
   */
  category?: string | null
  
  /** 
   * 文章摘要（可选）
   * 
   * 简短的内容概述
   */
  summary?: string | null
  
  /** 
   * 新闻来源（可选）
   * 
   * 新闻的来源平台或媒体
   * 
   * @example "OpenHarmony官网"
   */
  source?: string | null
  
  /** 
   * 创建时间（可选）
   * 
   * ISO 8601 格式的时间戳
   * 
   * @example "2025-01-15T14:30:56.789Z"
   */
  created_at?: string | null
  
  /** 
   * 更新时间（可选）
   * 
   * ISO 8601 格式的时间戳
   * 
   * @example "2025-01-15T14:30:56.789Z"
   */
  updated_at?: string | null
}

/**
 * 新闻响应接口
 * 
 * 定义分页新闻数据的响应结构
 * 
 * @interface NewsResponse
 * 
 * @remarks
 * 用于后端 API 返回的分页数据结构
 * 
 * @example
 * ```typescript
 * const response: NewsResponse = {
 *   articles: [...],
 *   total: 100,
 *   page: 1,
 *   page_size: 20,
 *   has_next: true,
 *   has_prev: false
 * }
 * ```
 */
export interface NewsResponse {
  /** 
   * 新闻文章数组
   * 
   * 当前页的新闻列表
   */
  articles: NewsArticle[]
  
  /** 
   * 总文章数量
   * 
   * 数据库中符合条件的文章总数
   */
  total: number
  
  /** 
   * 当前页码
   * 
   * 从 1 开始计数
   */
  page: number
  
  /** 
   * 每页文章数量
   * 
   * 分页大小
   */
  page_size: number
  
  /** 
   * 是否有下一页
   * 
   * true 表示可以加载更多数据
   */
  has_next: boolean
  
  /** 
   * 是否有上一页
   * 
   * true 表示可以返回上一页
   */
  has_prev: boolean
}
