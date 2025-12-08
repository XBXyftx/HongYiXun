/**
 * 搜索管理器
 * 负责本地新闻搜索和搜索历史管理
 */
import {
  APP_KV_DB,
  kvDatabase,
  KV_DB_KEYS,
  logger,
  LOG_TAG,
  NewsArticle,
  NEWS_CATEGORIES
} from "common"
import { distributedKVStore } from "@kit.ArkData"

/**
 * 搜索历史项
 */
export interface SearchHistoryItem {
  keyword: string
  timestamp: number
}

/**
 * 搜索结果
 */
export interface SearchResult {
  articles: NewsArticle[]
  total: number
  keyword: string
}

export class SearchManager {
  private appKVDb: distributedKVStore.SingleKVStore | undefined = undefined
  private maxHistoryCount: number = 20

  /**
   * 初始化搜索管理器
   */
  async init(): Promise<boolean> {
    const res = await kvDatabase.getKVStoreById(APP_KV_DB)
    if (res) {
      this.appKVDb = res
      logger.info(`${LOG_TAG.NEWS_MANAGER}SearchManager 初始化成功`)
      return true
    }
    logger.error(`${LOG_TAG.NEWS_MANAGER}SearchManager 初始化失败`)
    return false
  }

  /**
   * 搜索本地新闻
   * 从所有分类的数据库中搜索匹配关键词的新闻
   */
  async searchNews(keyword: string): Promise<SearchResult> {
    const result: SearchResult = {
      articles: [],
      total: 0,
      keyword: keyword
    }

    if (!keyword.trim() || !this.appKVDb) {
      return result
    }

    const searchKeyword = keyword.toLowerCase().trim()
    const allArticles: NewsArticle[] = []

    try {
      // 从所有已开发的分类中搜索
      for (const category of NEWS_CATEGORIES) {
        if (category.isDeveloped) {
          try {
            const data = await this.appKVDb.get(category.dbKey) as string
            const articles = JSON.parse(data) as NewsArticle[]
            allArticles.push(...articles)
          } catch (e) {
            // 该分类无数据，跳过
          }
        }
      }

      // 也从主新闻列表搜索
      try {
        const mainData = await this.appKVDb.get(KV_DB_KEYS.NEWS_ARTICLE_LIST) as string
        const mainArticles = JSON.parse(mainData) as NewsArticle[]
        allArticles.push(...mainArticles)
      } catch (e) {
        // 无数据
      }

      // 去重（根据 id）
      const uniqueMap = new Map<string, NewsArticle>()
      allArticles.forEach(article => {
        if (article.id && !uniqueMap.has(article.id)) {
          uniqueMap.set(article.id, article)
        }
      })

      // 搜索匹配
      const matchedArticles = Array.from(uniqueMap.values()).filter(article => {
        const titleMatch = article.title?.toLowerCase().includes(searchKeyword)
        const sourceMatch = article.source?.toLowerCase().includes(searchKeyword)
        return titleMatch || sourceMatch
      })

      // 按日期倒序排序
      matchedArticles.sort((a, b) => b.date.localeCompare(a.date))

      result.articles = matchedArticles
      result.total = matchedArticles.length

      logger.info(`${LOG_TAG.NEWS_MANAGER}搜索 "${keyword}" 找到 ${result.total} 条结果`)

    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}搜索异常: ${JSON.stringify(error)}`)
    }

    return result
  }


  /**
   * 获取搜索历史
   */
  async getSearchHistory(): Promise<SearchHistoryItem[]> {
    if (!this.appKVDb) {
      return []
    }

    try {
      const data = await this.appKVDb.get(KV_DB_KEYS.SEARCH_HISTORY) as string
      return JSON.parse(data) as SearchHistoryItem[]
    } catch (e) {
      return []
    }
  }

  /**
   * 添加搜索历史
   */
  async addSearchHistory(keyword: string): Promise<void> {
    if (!keyword.trim() || !this.appKVDb) {
      return
    }

    try {
      let history = await this.getSearchHistory()
      
      // 移除已存在的相同关键词
      history = history.filter(item => item.keyword !== keyword)
      
      // 添加到开头
      history.unshift({
        keyword: keyword.trim(),
        timestamp: Date.now()
      })

      // 限制数量
      if (history.length > this.maxHistoryCount) {
        history = history.slice(0, this.maxHistoryCount)
      }

      await this.appKVDb.put(KV_DB_KEYS.SEARCH_HISTORY, JSON.stringify(history))
      logger.info(`${LOG_TAG.NEWS_MANAGER}添加搜索历史: ${keyword}`)

    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}添加搜索历史失败: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 删除单条搜索历史
   */
  async removeSearchHistory(keyword: string): Promise<void> {
    if (!this.appKVDb) {
      return
    }

    try {
      let history = await this.getSearchHistory()
      history = history.filter(item => item.keyword !== keyword)
      await this.appKVDb.put(KV_DB_KEYS.SEARCH_HISTORY, JSON.stringify(history))
      logger.info(`${LOG_TAG.NEWS_MANAGER}删除搜索历史: ${keyword}`)
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}删除搜索历史失败: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 清空搜索历史
   */
  async clearSearchHistory(): Promise<void> {
    if (!this.appKVDb) {
      return
    }

    try {
      await this.appKVDb.put(KV_DB_KEYS.SEARCH_HISTORY, JSON.stringify([]))
      logger.info(`${LOG_TAG.NEWS_MANAGER}清空搜索历史`)
    } catch (error) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}清空搜索历史失败: ${JSON.stringify(error)}`)
    }
  }
}

export const searchManager = new SearchManager()