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

import {
  APP_KV_DB as APP_KV_DB_ID,
  kvDatabase,
  KV_DB_KEYS,
  logger,
  LOG_TAG,
  NewsArticle,
  NewsListAPI,
  NewsSwiperAPI,
  NewsSwiperStateAPI,
  ServerHealthAPI,
  NEWS_CATEGORIES,
  NewsCategoryInfo
} from "common"
import { common } from "@kit.AbilityKit"
import { distributedKVStore } from "@kit.ArkData"
import { promptAction } from "@kit.ArkUI"
import { BusinessError } from "@kit.BasicServicesKit"

/**
 * 快速刷新结果接口
 */
interface QuickRefreshResult {
  /** 是否成功 */
  success: boolean
  /** 成功加载的栏目数量 */
  loadedCount: number
}

/**
 * 完整刷新结果接口
 */
interface FullRefreshResult {
  /** 是否成功 */
  success: boolean
  /** 成功更新的栏目数量 */
  updatedCount: number
}

/**
 * 刷新进度信息接口
 */
interface RefreshProgress {
  /** 栏目名称 */
  category: string
  /** 当前进度 */
  current: number
  /** 总数 */
  total: number
}

/**
 * 栏目加载结果接口
 */
interface CategoryLoadResult {
  /** 栏目名称 */
  category: string
  /** 是否成功 */
  success: boolean
  /** 加载的新闻条数 */
  count: number
}

export class NewsManager {
  /**
   * 当前应用的键值数据库实例对象
   */
  appKVDb: distributedKVStore.SingleKVStore | undefined = undefined

  /**
   * 初始化函数，获取当前应用的键值对数据库实例。
   * @param context
   * @returns
   */
  async init(context: common.UIAbilityContext): Promise<boolean> {
    kvDatabase.init(context)
    const res = await kvDatabase.getKVStoreById(APP_KV_DB_ID)
    if (res) {
      this.appKVDb = res
      logger.info(`${LOG_TAG.NEWS_MANAGER}init: 获取appKVDb成功`)
      return true
    }
    logger.error(`${LOG_TAG.NEWS_MANAGER}初始化失败`)
    return false
  }

  /**
   * 从后端更新新闻文章列表数据，并持久化最新的新闻列表数据（一次性全量加载）
   * 
   * @deprecated 建议使用 loadNewsIncrementally() 进行分页加载以提升性能
   * @returns Promise<boolean> - 是否成功获取以及持久化
   * 
   * @remarks
   * 此方法会一次性加载所有新闻，适用于数据量较小的场景。
   * 对于大数据量场景，建议使用 loadNewsIncrementally() 分页加载。
   */
  async updateNewsListToDB(): Promise<boolean> {
    if (await ServerHealthAPI.isServerReady()) {
      const news: NewsArticle[] | null = (await NewsListAPI.getAllNews())
      if (news && this.appKVDb) {
        logger.info(`${LOG_TAG.NEWS_MANAGER}成功获取最新新闻，总条数: ${news.length}`)
        try {
          this.appKVDb.put(KV_DB_KEYS.NEWS_ARTICLE_LIST, JSON.stringify(news))
          logger.info(`${LOG_TAG.NEWS_MANAGER}数据库写入成功，无异常`)
          return true
        } catch (e) {
          let err = e as BusinessError
          logger.error(`${LOG_TAG.NEWS_MANAGER}更新数据库NewsArticle数据发生异常，异常信息: ${err.message}`)
          return false
        }
      }
      logger.error(`${LOG_TAG.NEWS_MANAGER}获取新闻失败,新闻数据或键值数据库为空。`)
      return false
    }
    logger.error(`${LOG_TAG.NEWS_MANAGER}获取新闻失败，后端服务状态异常，返回false`)
    return false
  }

  /**
   * 增量加载新闻数据（分页加载）
   * 
   * 从后端分页获取新闻数据，并增量更新到数据库（自动去重）
   * 
   * @param pageSize - 每页加载数量，默认 50 条
   * @param onPageLoaded - 每页加载完成的回调函数，参数为当前已加载的总条数
   * @returns Promise<boolean> - 加载是否成功
   * 
   * @remarks
   * 加载策略：
   * - 从第 1 页开始逐页加载
   * - 每加载一页立即合并到数据库并去重
   * - 通过 has_next 判断是否继续加载
   * - 加载失败不影响已加载的数据
   * 
   * 去重机制：
   * - 根据新闻 ID 去重
   * - 新数据优先（覆盖旧数据）
   * 
   * @example
   * ```typescript
   * // 分页加载所有新闻，每页 50 条
   * await newsManager.loadNewsIncrementally(50, (loadedCount) => {
   *   console.log(`已加载 ${loadedCount} 条新闻`)
   * })
   * ```
   */
  async loadNewsIncrementally(
    pageSize: number = 50,
    onPageLoaded?: (loadedCount: number) => void
  ): Promise<boolean> {
    if (!(await ServerHealthAPI.isServerReady())) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}服务端未就绪，无法加载新闻`)
      return false
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}数据库未初始化，无法加载新闻`)
      return false
    }

    try {
      let currentPage = 1
      let totalLoaded = 0
      let hasMore = true

      logger.info(`${LOG_TAG.NEWS_MANAGER}开始分页加载新闻，每页 ${pageSize} 条`)

      while (hasMore) {
        const response = await NewsListAPI.getNewsPage(currentPage, pageSize)
        
        if (!response || response.articles.length === 0) {
          if (currentPage === 1) {
            logger.error(`${LOG_TAG.NEWS_MANAGER}第 1 页加载失败或无数据`)
            return false
          }
          logger.info(`${LOG_TAG.NEWS_MANAGER}第 ${currentPage} 页无数据，加载结束`)
          break
        }

        // 合并到数据库（自动去重）
        const mergeSuccess = await this.mergeAndUpdateNewsDB(response.articles)
        if (!mergeSuccess) {
          logger.warn(`${LOG_TAG.NEWS_MANAGER}第 ${currentPage} 页数据合并失败，但已加载 ${totalLoaded} 条数据`)
          return totalLoaded > 0
        }

        totalLoaded += response.articles.length
        logger.info(`${LOG_TAG.NEWS_MANAGER}✓ 第 ${currentPage} 页加载成功，本页 ${response.articles.length} 条，累计 ${totalLoaded}/${response.total} 条`)

        // 调用回调函数
        if (onPageLoaded) {
          onPageLoaded(totalLoaded)
        }

        // 判断是否有下一页
        hasMore = response.has_next
        currentPage++
      }

      logger.info(`${LOG_TAG.NEWS_MANAGER}✓ 分页加载完成，共加载 ${totalLoaded} 条新闻`)
      return true

    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.NEWS_MANAGER}分页加载异常: ${err.message}`)
      return false
    }
  }

  /**
   * 快速加载最新的 N 条新闻到数据库
   * 
   * @param count - 需要加载的新闻数量，默认 10 条
   * @returns Promise<boolean> - 加载是否成功
   * 
   * @remarks
   * 此方法适用于应用启动时的首屏快速加载场景
   * 加载的数据会合并到现有数据库中（自动去重）
   * 
   * @example
   * ```typescript
   * // 快速加载最新 10 条新闻
   * await newsManager.loadLatestNewsToDB(10)
   * ```
   */
  async loadLatestNewsToDB(count: number = 10): Promise<boolean> {
    if (!(await ServerHealthAPI.isServerReady())) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}服务端未就绪，无法加载最新新闻`)
      return false
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}数据库未初始化，无法加载最新新闻`)
      return false
    }

    try {
      const latestNews:NewsArticle[]|null = await NewsListAPI.getLatestNews(count)
      
      if (!latestNews || latestNews.length === 0) {
        logger.error(`${LOG_TAG.NEWS_MANAGER}获取最新新闻失败或无数据`)
        return false
      }

      logger.info(`${LOG_TAG.NEWS_MANAGER}获取最新 ${latestNews.length} 条新闻成功`)

      // 合并到数据库（自动去重）
      const mergeSuccess = await this.mergeAndUpdateNewsDB(latestNews)
      if (mergeSuccess) {
        logger.info(`${LOG_TAG.NEWS_MANAGER}✓ 最新新闻已合并到数据库`)
        return true
      } else {
        logger.error(`${LOG_TAG.NEWS_MANAGER}最新新闻合并到数据库失败`)
        return false
      }

    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.NEWS_MANAGER}加载最新新闻异常: ${err.message}`)
      return false
    }
  }

  /**
   * 合并新闻数据到数据库（带去重）
   * 
   * 将新的新闻数据与数据库中的现有数据合并，自动去重
   * 
   * @param newArticles - 待合并的新闻数组
   * @returns Promise<boolean> - 合并是否成功
   * 
   * @remarks
   * 合并策略：
   * - 根据新闻 ID 进行去重
   * - 新数据优先（覆盖相同 ID 的旧数据）
   * - 合并后按日期倒序排列（最新的在前）
   * 
   * @private
   */
  private async mergeAndUpdateNewsDB(newArticles: NewsArticle[]): Promise<boolean> {
    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}数据库未初始化`)
      return false
    }

    try {
      // 读取现有数据
      let existingArticles: NewsArticle[] = []
      try {
        const existingData = (await this.appKVDb.get(KV_DB_KEYS.NEWS_ARTICLE_LIST)) as string
        existingArticles = JSON.parse(existingData) as NewsArticle[]
        logger.debug(`${LOG_TAG.NEWS_MANAGER}读取到现有数据 ${existingArticles.length} 条`)
      } catch (e) {
        // 数据库为空或读取失败，使用空数组
        logger.info(`${LOG_TAG.NEWS_MANAGER}数据库为空或读取失败，初始化为空数组`)
        existingArticles = []
      }

      // 使用 Map 进行去重合并（新数据优先）
      const articleMap = new Map<string, NewsArticle>()
      
      // 先添加旧数据
      existingArticles.forEach(article => {
        if (article.id) {
          articleMap.set(article.id, article)
        }
      })

      // 再添加新数据（覆盖旧数据）
      newArticles.forEach(article => {
        if (article.id) {
          articleMap.set(article.id, article)
        }
      })

      // 转换为数组并按日期倒序排序
      const mergedArticles = Array.from(articleMap.values()).sort((a, b) => {
        // 按日期倒序排列（最新的在前）
        return b.date.localeCompare(a.date)
      })

      const beforeCount = existingArticles.length
      const afterCount = mergedArticles.length
      const newCount = newArticles.length

      logger.info(`${LOG_TAG.NEWS_MANAGER}数据合并: 原有 ${beforeCount} 条 + 新增 ${newCount} 条 = 合并后 ${afterCount} 条（去重 ${beforeCount + newCount - afterCount} 条）`)

      // 写入数据库
      await this.appKVDb.put(KV_DB_KEYS.NEWS_ARTICLE_LIST, JSON.stringify(mergedArticles))
      logger.debug(`${LOG_TAG.NEWS_MANAGER}数据库更新成功`)

      return true

    } catch (e) {
      let err = e as BusinessError
      logger.error(`${LOG_TAG.NEWS_MANAGER}合并数据异常: ${err.message}`)
      return false
    }
  }

  async getNewsArticleListFromDB(): Promise<NewsArticle[] | null> {
    if (this.appKVDb) {
      try {
        const res: string = (await this.appKVDb.get(KV_DB_KEYS.NEWS_ARTICLE_LIST)) as string
        logger.info(`${LOG_TAG.NEWS_MANAGER}读取到数据库新闻列表数据: ${res}`)
        const newsArticleList = JSON.parse(res) as NewsArticle[]
        return newsArticleList
      } catch (e) {
        let err = e as BusinessError
        logger.error(`${LOG_TAG.NEWS_MANAGER}尝试获取数据库新闻列表数据发生异常，异常信息: ${err.message}`)
        return null
      }
    }
    return null
  }

  /**
   * 按分类加载新闻数据到数据库
   * 
   * 从后端获取指定分类的所有新闻，并存储到对应的数据库键中
   * 
   * @param category - 新闻分类（"官方动态" | "技术博客"）
   * @param dbKey - 数据库存储键（KV_DB_KEYS 中的枚举值）
   * @returns Promise<boolean> - 加载是否成功
   * 
   * @remarks
   * 加载策略：
   * - 获取该分类的所有数据（不分页）
   * - 直接覆盖数据库中的旧数据
   * - 适合分类数据量较小（< 100 条）的场景
   * 
   * @example
   * ```typescript
   * // 加载官方动态数据
   * await newsManager.loadCategoryNewsToDB("官方动态", KV_DB_KEYS.NEWS_OPENHARMONY_OFFICIAL)
   * ```
   */
  async loadCategoryNewsToDB(category: string, dbKey: KV_DB_KEYS): Promise<boolean> {
    if (!(await ServerHealthAPI.isServerReady())) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}服务端未就绪，无法加载【${category}】`)
      return false
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}数据库未初始化，无法加载【${category}】`)
      return false
    }

    try {
      const categoryNews = await NewsListAPI.getAllNewsByCategory(category)
      
      if (!categoryNews || categoryNews.length === 0) {
        logger.warn(`${LOG_TAG.NEWS_MANAGER}【${category}】无数据`)
        // 即使无数据也存储空数组，避免读取时出错
        await this.appKVDb.put(dbKey, JSON.stringify([]))
        return true
      }

      logger.info(`${LOG_TAG.NEWS_MANAGER}获取【${category}】成功，共 ${categoryNews.length} 条`)

      // 存储到数据库
      await this.appKVDb.put(dbKey, JSON.stringify(categoryNews))
      logger.info(`${LOG_TAG.NEWS_MANAGER}✓ 【${category}】已存储到数据库`)
      return true

    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.NEWS_MANAGER}加载【${category}】异常: ${err.message}`)
      return false
    }
  }

  /**
   * 从数据库读取分类新闻数据
   * 
   * @param dbKey - 数据库存储键（KV_DB_KEYS 中的枚举值）
   * @param categoryName - 分类名称（用于日志输出）
   * @returns Promise<NewsArticle[] | null> - 新闻数组，失败或无数据返回 null
   * 
   * @example
   * ```typescript
   * // 读取官方动态数据
   * const officialNews = await newsManager.getCategoryNewsFromDB(
   *   KV_DB_KEYS.NEWS_OPENHARMONY_OFFICIAL, 
   *   "官方动态"
   * )
   * ```
   */
  async getCategoryNewsFromDB(dbKey: KV_DB_KEYS, categoryName: string): Promise<NewsArticle[] | null> {
    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}数据库未初始化，无法读取【${categoryName}】`)
      return null
    }

    try {
      const res: string = (await this.appKVDb.get(dbKey)) as string
      const categoryNews = JSON.parse(res) as NewsArticle[]
      logger.info(`${LOG_TAG.NEWS_MANAGER}从数据库读取【${categoryName}】: ${categoryNews.length} 条`)
      return categoryNews
    } catch (e) {
      let err = e as BusinessError
      logger.warn(`${LOG_TAG.NEWS_MANAGER}读取【${categoryName}】失败或无数据: ${err.message}`)
      return null
    }
  }

  async updateNewsSwiperToDB(): Promise<boolean> {
    if (await NewsSwiperStateAPI.isSwiperServerReady()) {
      let swiperData: ResourceStr[] | null = await NewsSwiperAPI.getNewsSwiperImgData()
      if (swiperData && this.appKVDb) {
        logger.info(`${LOG_TAG.NEWS_MANAGER}成功获取最新轮播图数据，总条数: ${swiperData.length}`)
        try {
          this.appKVDb.put(KV_DB_KEYS.NEWS_SWIPER, JSON.stringify(swiperData))
          logger.info(`${LOG_TAG.NEWS_MANAGER}轮播图数据库写入成功，无异常`)
          return true
        } catch (e) {
          let err = e as BusinessError
          logger.error(`${LOG_TAG.NEWS_MANAGER}更新数据库NewsSwiper数据发生异常，异常信息: ${err.message}`)
          return false
        }
      }
      logger.error(`${LOG_TAG.NEWS_MANAGER}获取到的轮播图数据或键值数据库为空`)
      return false
    }
    logger.error(`${LOG_TAG.NEWS_MANAGER}获取轮播图数据失败，后端轮播图服务状态异常`)
    return false
  }

  async getNewsSwiperDataFromDB(): Promise<ResourceStr[] | null> {
    if (this.appKVDb) {
      try {
        const res: string = (await this.appKVDb.get(KV_DB_KEYS.NEWS_SWIPER)) as string
        logger.info(`${LOG_TAG.NEWS_MANAGER}读取到数据库轮播图数据列表数据: ${res}`)
        const newsSwiperData = JSON.parse(res) as ResourceStr[]
        return newsSwiperData
      } catch (e) {
        let err = e as BusinessError
        logger.error(`${LOG_TAG.NEWS_MANAGER}尝试获取数据库轮播图数据发生异常，异常信息: ${err.message}`)
        return null
      }
    }
    return null
  }

  /**
   * 两阶段刷新 - 第一阶段：快速加载各分栏前20条最新数据
   * 
   * 使用 Promise.all 并发加载所有已开发栏目的前20条数据，快速响应用户
   * 
   * @returns Promise<{ success: boolean, loadedCount: number }> - 加载结果和成功加载的栏目数
   * 
   * @remarks
   * 刷新策略：
   * - 仅加载已开发的栏目（isDeveloped === true）
   * - 每个栏目获取最新 20 条数据
   * - 使用 Promise.all 并发请求，最大化速度
   * - 单个栏目失败不影响其他栏目
   * - 同时刷新轮播图数据
   * 
   * 适用场景：
   * - 用户下拉刷新时的第一阶段
   * - 需要快速看到最新内容
   * 
   * @example
   * ```typescript
   * const result = await newsManager.quickRefreshCategories()
   * if (result.success) {
   *   console.log(`快速刷新完成，加载了 ${result.loadedCount} 个栏目`)
   * }
   * ```
   */
  async quickRefreshCategories(): Promise<QuickRefreshResult> {
    logger.info(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 开始第一阶段：并发加载各分栏前20条数据`)
    
    if (!(await ServerHealthAPI.isServerReady())) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 服务端未就绪`)
      const result: QuickRefreshResult = { success: false, loadedCount: 0 }
      return result
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 数据库未初始化`)
      const result: QuickRefreshResult = { success: false, loadedCount: 0 }
      return result
    }

    try {
      const startTime = Date.now()
      
      // 筛选出已开发的栏目
      const developedCategories = NEWS_CATEGORIES.filter(cat => cat.isDeveloped)
      logger.info(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 需要刷新 ${developedCategories.length} 个栏目`)

      // 创建并发加载任务数组
      const loadTasks = developedCategories.map(async (category: NewsCategoryInfo) => {
        try {
          logger.debug(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 开始加载【${category.displayName}】前20条`)
          
          // 调用分类 API 获取前20条数据
          const response = await NewsListAPI.getNewsByCategory(category.apiCategory, 1, 20)
          
          if (response && response.articles.length > 0) {
            // 读取现有数据
            let existingArticles: NewsArticle[] = []
            try {
              const existingData = (await this.appKVDb!.get(category.dbKey)) as string
              existingArticles = JSON.parse(existingData) as NewsArticle[]
            } catch (e) {
              existingArticles = []
            }

            // 合并去重（新数据优先）
            const articleMap = new Map<string, NewsArticle>()
            existingArticles.forEach(article => {
              if (article.id) articleMap.set(article.id, article)
            })
            response.articles.forEach(article => {
              if (article.id) articleMap.set(article.id, article)
            })

            // 按日期倒序排序
            const mergedArticles = Array.from(articleMap.values())
              .sort((a, b) => b.date.localeCompare(a.date))

            // 写入数据库
            await this.appKVDb!.put(category.dbKey, JSON.stringify(mergedArticles))
            
            logger.info(`${LOG_TAG.NEWS_MANAGER}[快速刷新] ✓ 【${category.displayName}】加载成功: ${response.articles.length}条`)
            const result: CategoryLoadResult = { category: category.displayName, success: true, count: response.articles.length }
            return result
          } else {
            logger.warn(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 【${category.displayName}】无数据`)
            const result: CategoryLoadResult = { category: category.displayName, success: false, count: 0 }
            return result
          }
        } catch (error) {
          logger.error(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 【${category.displayName}】加载失败: ${JSON.stringify(error)}`)
          const result: CategoryLoadResult = { category: category.displayName, success: false, count: 0 }
          return result
        }
      })

      // 同时加载轮播图数据
      const swiperTask = this.updateNewsSwiperToDB()

      // 并发执行所有任务
      const results = await Promise.all([...loadTasks, swiperTask])
      
      // 统计结果（最后一个是轮播图任务）
      const categoryResults = results.slice(0, -1) as CategoryLoadResult[]
      const swiperSuccess = results[results.length - 1] as boolean
      
      const successCount = categoryResults.filter(r => r.success).length
      const totalArticles = categoryResults.reduce((sum, r) => sum + r.count, 0)
      
      const endTime = Date.now()
      const duration = endTime - startTime

      logger.info(`${LOG_TAG.NEWS_MANAGER}[快速刷新] ✓ 第一阶段完成: ${successCount}/${developedCategories.length} 个栏目成功, 共${totalArticles}条数据, 耗时${duration}ms`)
      logger.info(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 轮播图刷新: ${swiperSuccess ? '成功' : '失败'}`)

      const finalResult: QuickRefreshResult = { 
        success: successCount > 0, 
        loadedCount: successCount 
      }
      return finalResult

    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.NEWS_MANAGER}[快速刷新] 异常: ${err.message}`)
      const result: QuickRefreshResult = { success: false, loadedCount: 0 }
      return result
    }
  }

  /**
   * 两阶段刷新 - 第二阶段：后台完整加载所有分栏数据
   * 
   * 在后台逐个加载各栏目的全部数据，并提供进度回调实时更新 UI
   * 
   * @param onProgress - 进度回调函数，参数为 { category: 栏目名, current: 当前进度, total: 总数 }
   * @returns Promise<{ success: boolean, updatedCount: number }> - 加载结果和成功更新的栏目数
   * 
   * @remarks
   * 刷新策略：
   * - 后台逐个加载已开发栏目的全部数据
   * - 每个栏目完成后立即回调，通知 UI 更新
   * - 单个栏目失败不影响其他栏目
   * - 按日期倒序排序后存储
   * 
   * 适用场景：
   * - 快速刷新完成后的后台任务
   * - 确保数据完整性和最新性
   * 
   * @example
   * ```typescript
   * newsManager.fullRefreshCategories((progress) => {
   *   console.log(`${progress.category}: ${progress.current}/${progress.total}`)
   * }).then(result => {
   *   console.log(`完整刷新完成，更新了 ${result.updatedCount} 个栏目`)
   * })
   * ```
   */
  async fullRefreshCategories(
    onProgress?: (progress: RefreshProgress) => void
  ): Promise<FullRefreshResult> {
    logger.info(`${LOG_TAG.NEWS_MANAGER}[完整刷新] 开始第二阶段：后台加载全部分栏数据`)

    if (!(await ServerHealthAPI.isServerReady())) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}[完整刷新] 服务端未就绪`)
      const result: FullRefreshResult = { success: false, updatedCount: 0 }
      return result
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.NEWS_MANAGER}[完整刷新] 数据库未初始化`)
      const result: FullRefreshResult = { success: false, updatedCount: 0 }
      return result
    }

    try {
      const startTime = Date.now()
      const developedCategories = NEWS_CATEGORIES.filter(cat => cat.isDeveloped)
      const totalCategories = developedCategories.length
      let updatedCount = 0

      // 逐个加载栏目（避免并发过多导致服务器压力）
      for (let i = 0; i < developedCategories.length; i++) {
        const category = developedCategories[i]
        const current = i + 1

        try {
          logger.info(`${LOG_TAG.NEWS_MANAGER}[完整刷新] [${current}/${totalCategories}] 加载【${category.displayName}】全部数据`)

          // 获取该分类的所有数据
          const allNews = await NewsListAPI.getAllNewsByCategory(category.apiCategory)

          if (allNews && allNews.length > 0) {
            // 按日期倒序排序
            const sortedNews = allNews.sort((a, b) => b.date.localeCompare(a.date))
            
            // 直接覆盖存储（已经是最新完整数据）
            await this.appKVDb.put(category.dbKey, JSON.stringify(sortedNews))
            
            updatedCount++
            logger.info(`${LOG_TAG.NEWS_MANAGER}[完整刷新] ✓ [${current}/${totalCategories}] 【${category.displayName}】完成: ${sortedNews.length}条`)

            // 回调进度更新
            if (onProgress) {
              const progress: RefreshProgress = {
                category: category.displayName,
                current: current,
                total: totalCategories
              }
              onProgress(progress)
            }
          } else {
            logger.warn(`${LOG_TAG.NEWS_MANAGER}[完整刷新] [${current}/${totalCategories}] 【${category.displayName}】无数据`)
          }

        } catch (error) {
          logger.error(`${LOG_TAG.NEWS_MANAGER}[完整刷新] [${current}/${totalCategories}] 【${category.displayName}】失败: ${JSON.stringify(error)}`)
        }
      }

      const endTime = Date.now()
      const duration = endTime - startTime

      logger.info(`${LOG_TAG.NEWS_MANAGER}[完整刷新] ✓ 第二阶段完成: ${updatedCount}/${totalCategories} 个栏目成功, 耗时${duration}ms`)

      const finalResult: FullRefreshResult = {
        success: updatedCount > 0,
        updatedCount: updatedCount
      }
      return finalResult

    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.NEWS_MANAGER}[完整刷新] 异常: ${err.message}`)
      const result: FullRefreshResult = { success: false, updatedCount: 0 }
      return result
    }
  }
}

export const newsManager = new NewsManager()