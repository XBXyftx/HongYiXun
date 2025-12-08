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

/**
 * 带匹配度的文章
 */
interface ArticleWithScore {
  article: NewsArticle
  score: number
}

/**
 * 计算模糊匹配分数
 * @param text 待匹配文本
 * @param keyword 搜索关键词
 * @returns 匹配分数（0-100），越高越匹配
 */
function calculateFuzzyScore(text: string, keyword: string): number {
  if (!text || !keyword) {
    return 0
  }

  const lowerText = text.toLowerCase()
  const lowerKeyword = keyword.toLowerCase()

  // 完全匹配，最高分
  if (lowerText.includes(lowerKeyword)) {
    // 标题开头匹配加分
    if (lowerText.startsWith(lowerKeyword)) {
      return 100
    }
    // 完整包含
    return 90
  }

  // 分词匹配（按空格、标点分割关键词）
  const keywordParts = lowerKeyword.split(/[\s,，.。!！?？;；:：、]+/).filter(p => p.length > 0)
  if (keywordParts.length > 1) {
    let matchedParts = 0
    for (const part of keywordParts) {
      if (lowerText.includes(part)) {
        matchedParts++
      }
    }
    if (matchedParts > 0) {
      // 按匹配的分词比例计算分数
      return Math.floor((matchedParts / keywordParts.length) * 80)
    }
  }

  // 字符级模糊匹配（关键词字符在文本中按顺序出现）
  let keywordIndex = 0
  let consecutiveMatches = 0
  let maxConsecutive = 0

  for (let i = 0; i < lowerText.length && keywordIndex < lowerKeyword.length; i++) {
    if (lowerText[i] === lowerKeyword[keywordIndex]) {
      keywordIndex++
      consecutiveMatches++
      maxConsecutive = Math.max(maxConsecutive, consecutiveMatches)
    } else {
      consecutiveMatches = 0
    }
  }

  // 所有字符都按顺序匹配到了
  if (keywordIndex === lowerKeyword.length) {
    // 根据连续匹配程度给分
    const continuityBonus = (maxConsecutive / lowerKeyword.length) * 30
    return Math.floor(50 + continuityBonus)
  }

  // 部分字符匹配
  if (keywordIndex > 0) {
    return Math.floor((keywordIndex / lowerKeyword.length) * 40)
  }

  return 0
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

      // 模糊搜索匹配并计算分数
      const scoredArticles: ArticleWithScore[] = []

      for (const article of Array.from(uniqueMap.values())) {
        // 计算标题匹配分数（权重更高）
        const titleScore = calculateFuzzyScore(article.title || '', searchKeyword) * 1.5
        // 计算来源匹配分数
        const sourceScore = calculateFuzzyScore(article.source || '', searchKeyword)
        // 取最高分
        const maxScore = Math.max(titleScore, sourceScore)

        // 只保留有匹配的文章（分数 > 0）
        if (maxScore > 0) {
          scoredArticles.push({
            article: article,
            score: maxScore
          })
        }
      }

      // 按匹配度降序排序，相同匹配度按日期降序
      scoredArticles.sort((a, b) => {
        if (b.score !== a.score) {
          return b.score - a.score
        }
        return b.article.date.localeCompare(a.article.date)
      })

      const matchedArticles = scoredArticles.map(item => item.article)

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