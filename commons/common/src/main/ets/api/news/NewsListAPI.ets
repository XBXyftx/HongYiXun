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
import { NewsArticle, NewsResponse } from "../../modules/news/NewsListModules";
import { logger } from "../../utils/logger/logger";
import { axiosHttp } from "../http/AxiosHttp";
import { BusinessError } from "@kit.BasicServicesKit";
import { LOG_TAG } from '../../modules/enums';

/**
 * 新闻列表 API 类
 * 
 * 提供新闻数据获取的接口，支持分页加载和全量加载
 * 
 * @remarks
 * 使用建议：
 * - 优先使用分页加载 `getNewsPage()` 以提升性能
 * - 使用 `getLatestNews()` 快速获取最新数据
 * - 避免使用 `getAllNews()` 加载大量数据
 */
export class NewsListAPI {
  /**
   * 获取指定页的新闻列表（分页接口）
   * 
   * @param page - 页码，从 1 开始
   * @param pageSize - 每页数量，默认 20 条，最大 100 条
   * @returns Promise<NewsResponse | null> - 分页新闻响应对象，失败返回 null
   * 
   * @remarks
   * 分页机制：
   * - 数据按日期倒序排列（最新的在前）
   * - 最后一页数据可能少于 pageSize
   * - 超出范围返回空数组但不会报错
   * - 通过 has_next 判断是否有下一页
   * 
   * @example
   * ```typescript
   * // 获取第 1 页，每页 20 条
   * const response = await NewsListAPI.getNewsPage(1, 20)
   * if (response) {
   *   console.log(`获取到 ${response.articles.length} 条新闻`)
   *   console.log(`总共 ${response.total} 条，是否有下一页: ${response.has_next}`)
   * }
   * ```
   */
  static async getNewsPage(page: number = 1, pageSize: number = 20): Promise<NewsResponse | null> {
    try {
      const res = await axiosHttp.request<NewsResponse>({
        url: `/api/news/?page=${page}&page_size=${pageSize}`
      })
      logger.info(`${LOG_TAG.NEWS_LIST_API}分页获取新闻成功: 第${page}页, 共${res.articles.length}条`)
      return res
    } catch (e) {
      let err = e as BusinessError
      logger.error(`${LOG_TAG.NEWS_LIST_API}分页获取新闻失败: ${err.message}`)
      return null
    }
  }

  /**
   * 获取最新的 N 条新闻（快速加载）
   * 
   * @param count - 需要获取的新闻数量，默认 10 条
   * @returns Promise<NewsArticle[] | null> - 新闻数组，失败返回 null
   * 
   * @remarks
   * 适用场景：
   * - 应用启动时的首屏快速加载
   * - 预览最新内容
   * 
   * @example
   * ```typescript
   * // 获取最新 10 条新闻
   * const latestNews = await NewsListAPI.getLatestNews(10)
   * if (latestNews) {
   *   console.log(`获取到最新 ${latestNews.length} 条新闻`)
   * }
   * ```
   */
  static async getLatestNews(count: number = 10): Promise<NewsArticle[] | null> {
    try {
      const res = await axiosHttp.request<NewsResponse>({
        url: `/api/news/?page=1&page_size=${count}`
      })
      logger.info(`${LOG_TAG.NEWS_LIST_API}获取最新${count}条新闻成功: 实际${res.articles.length}条`)
      return res.articles
    } catch (e) {
      let err = e as BusinessError
      logger.error(`${LOG_TAG.NEWS_LIST_API}获取最新新闻失败: ${err.message}`)
      return null
    }
  }

  /**
   * 按分类获取新闻列表（支持分页）
   * 
   * @param category - 新闻分类（"官方动态" | "技术博客"）
   * @param page - 页码，从 1 开始
   * @param pageSize - 每页数量，默认 20 条
   * @returns Promise<NewsResponse | null> - 分类新闻响应对象，失败返回 null
   * 
   * @remarks
   * 分类过滤机制：
   * - 先从所有新闻中过滤出指定分类
   * - 再对过滤结果进行分页
   * - total 返回该分类的文章总数
   * - has_next/has_prev 基于过滤后的数据判断
   * 
   * 可用的分类值：
   * - "官方动态": OpenHarmony 官网新闻公告
   * - "技术博客": OpenHarmony 官方技术博客文章
   * 
   * @example
   * ```typescript
   * // 获取官方动态第 1 页
   * const response = await NewsListAPI.getNewsByCategory("官方动态", 1, 20)
   * if (response) {
   *   console.log(`官方动态共 ${response.total} 条，本页 ${response.articles.length} 条`)
   * }
   * ```
   */
  static async getNewsByCategory(category: string, page: number = 1, pageSize: number = 20): Promise<NewsResponse | null> {
    try {
      const res = await axiosHttp.request<NewsResponse>({
        url: `/api/news/?category=${encodeURIComponent(category)}&page=${page}&page_size=${pageSize}`
      })
      logger.info(`${LOG_TAG.NEWS_LIST_API}获取【${category}】第${page}页成功: 共${res.articles.length}条，总计${res.total}条`)
      return res
    } catch (e) {
      let err = e as BusinessError
      logger.error(`${LOG_TAG.NEWS_LIST_API}获取【${category}】失败: ${err.message}`)
      return null
    }
  }

  /**
   * 按分类获取所有新闻（不分页，慎用）
   * 
   * @param category - 新闻分类（"官方动态" | "技术博客"）
   * @returns Promise<NewsArticle[] | null> - 分类新闻数组，失败返回 null
   * 
   * @remarks
   * 适用场景：
   * - 需要获取某分类的全部数据进行缓存
   * - 分类数据量较小（< 100 条）
   * 
   * @example
   * ```typescript
   * // 获取所有官方动态
   * const allOfficial = await NewsListAPI.getAllNewsByCategory("官方动态")
   * ```
   */
  static async getAllNewsByCategory(category: string): Promise<NewsArticle[] | null> {
    try {
      const res = await axiosHttp.request<NewsResponse>({
        url: `/api/news/?category=${encodeURIComponent(category)}&all=true`
      })
      logger.info(`${LOG_TAG.NEWS_LIST_API}获取【${category}】全部数据成功: 共${res.articles.length}条`)
      return res.articles
    } catch (e) {
      let err = e as BusinessError
      logger.error(`${LOG_TAG.NEWS_LIST_API}获取【${category}】全部数据失败: ${err.message}`)
      return null
    }
  }

  /**
   * 获取全部新闻列表接口（不推荐）
   * 
   * @deprecated 建议使用 getNewsPage() 进行分页加载以提升性能
   * @returns Promise<NewsArticle[] | null> - 全部新闻数组，失败返回 null
   * 
   * @remarks
   * 性能警告：
   * - 数据量大时响应慢（可能数百条）
   * - 内存占用高
   * - 用户体验差（长时间等待）
   * 
   * 替代方案：
   * - 使用 getNewsPage() 分页加载
   * - 使用 getLatestNews() 快速加载最新数据
   */
  static async getAllNews(): Promise<NewsArticle[] | null> {
    try {
      const res = await axiosHttp.request<NewsResponse>({
        url: '/api/news/?all=true'
      })
      logger.warn(`${LOG_TAG.NEWS_LIST_API}使用getAllNews()一次性加载${res.articles.length}条数据，建议改用分页加载`)
      return res.articles
    } catch (e) {
      let err = e as BusinessError
      logger.error(`${LOG_TAG.NEWS_LIST_API}获取全部新闻失败: ${err.message}`)
      return null
    }
  }
}