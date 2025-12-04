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

import { APP_KV_DB, KV_DB_KEYS, logger, LOG_TAG, NewsArticle, kvDatabase, APP_STORAGE_KEYS, HistoryUpdateTrigger, HistoryItem, DailyReadingStats } from "common"
import { distributedKVStore } from "@kit.ArkData"
import { BusinessError } from "@kit.BasicServicesKit"
import { AppStorageV2 } from "@kit.ArkUI"

/**
 * 历史记录管理器
 * 
 * 负责管理用户的浏览历史记录
 */
export class HistoryManager {
  private appKVDb: distributedKVStore.SingleKVStore | null = null
  private readonly MAX_HISTORY_COUNT = 100 // 最多保存100条历史记录

  /**
   * 初始化数据库
   */
  async init(): Promise<boolean> {
    try {
      this.appKVDb = await kvDatabase.getKVStoreById(APP_KV_DB)
      if (this.appKVDb) {
        logger.info(`${LOG_TAG.HISTORY_MANAGER}数据库初始化成功`)
        return true
      }
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库初始化失败`)
      return false
    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库初始化异常: ${err.message}`)
      return false
    }
  }

  /**
   * 添加浏览历史记录
   * 
   * @param article - 新闻文章
   * @returns 是否添加成功
   */
  async addHistory(article: NewsArticle): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库未初始化，无法添加历史记录`)
      return false
    }

    try {
      // 获取现有历史记录
      const historyList = await this.getHistoryList()
      
      // 检查是否已存在该文章（根据 id 去重）
      const existingIndex = historyList.findIndex((item: HistoryItem): boolean => item.article.id === article.id)
      
      // 创建新的历史记录项
      const now = new Date()
      const newHistoryItem: HistoryItem = {
        article: article,
        timestamp: now.getTime(),
        dateStr: this.formatDate(now)
      }

      // 如果已存在，移除旧记录
      if (existingIndex !== -1) {
        historyList.splice(existingIndex, 1)
        logger.debug(`${LOG_TAG.HISTORY_MANAGER}移除重复历史记录: ${article.title}`)
      }

      // 将新记录添加到开头（最新的在前）
      historyList.unshift(newHistoryItem)

      // 限制历史记录数量
      if (historyList.length > this.MAX_HISTORY_COUNT) {
        historyList.splice(this.MAX_HISTORY_COUNT)
        logger.debug(`${LOG_TAG.HISTORY_MANAGER}历史记录超过限制，保留最新 ${this.MAX_HISTORY_COUNT} 条`)
      }

      // 保存到数据库
      await this.appKVDb.put(KV_DB_KEYS.READING_HISTORY, JSON.stringify(historyList))
      logger.info(`${LOG_TAG.HISTORY_MANAGER}添加历史记录成功: ${article.title}`)
      
      // 更新每日阅读统计
      await this.updateDailyStats(article.id, newHistoryItem.dateStr)
      
      // 触发更新通知
      this.notifyHistoryUpdate()
      
      return true

    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.HISTORY_MANAGER}添加历史记录失败: ${err.message}`)
      return false
    }
  }

  /**
   * 获取历史记录列表
   * 
   * @returns 历史记录数组
   */
  async getHistoryList(): Promise<HistoryItem[]> {
    if (!this.appKVDb) {
      await this.init()
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库未初始化`)
      return []
    }

    try {
      const data = await this.appKVDb.get(KV_DB_KEYS.READING_HISTORY) as string
      const historyList = JSON.parse(data) as HistoryItem[]
      logger.info(`${LOG_TAG.HISTORY_MANAGER}获取历史记录成功: ${historyList.length} 条`)
      return historyList
    } catch (error) {
      logger.info(`${LOG_TAG.HISTORY_MANAGER}历史记录为空或读取失败`)
      return []
    }
  }

  /**
   * 删除单条历史记录
   * 
   * @param articleId - 文章 ID
   * @returns 是否删除成功
   */
  async deleteHistory(articleId: string): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库未初始化`)
      return false
    }

    try {
      const historyList = await this.getHistoryList()
      const filteredList = historyList.filter((item: HistoryItem): boolean => item.article.id !== articleId)
      
      if (filteredList.length === historyList.length) {
        logger.warn(`${LOG_TAG.HISTORY_MANAGER}未找到要删除的历史记录: ${articleId}`)
        return false
      }

      await this.appKVDb.put(KV_DB_KEYS.READING_HISTORY, JSON.stringify(filteredList))
      logger.info(`${LOG_TAG.HISTORY_MANAGER}删除历史记录成功: ${articleId}`)
      
      // 触发更新通知
      this.notifyHistoryUpdate()
      
      return true

    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.HISTORY_MANAGER}删除历史记录失败: ${err.message}`)
      return false
    }
  }

  /**
   * 清空所有历史记录
   * 
   * @returns 是否清空成功
   */
  async clearAllHistory(): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库未初始化`)
      return false
    }

    try {
      await this.appKVDb.put(KV_DB_KEYS.READING_HISTORY, JSON.stringify([]))
      logger.info(`${LOG_TAG.HISTORY_MANAGER}清空历史记录成功`)
      
      // 触发更新通知
      this.notifyHistoryUpdate()
      
      return true
    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.HISTORY_MANAGER}清空历史记录失败: ${err.message}`)
      return false
    }
  }

  /**
   * 格式化日期为字符串
   * 
   * @param date - 日期对象
   * @returns 格式化后的日期字符串
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  /**
   * 触发历史记录更新通知
   * 
   * 通过递增全局触发器的值来通知所有监听组件刷新数据
   * 
   * @private
   */
  private notifyHistoryUpdate(): void {
    try {
      const trigger = AppStorageV2.connect(
        HistoryUpdateTrigger,
        APP_STORAGE_KEYS.HISTORY_UPDATE_TRIGGER,
        () => new HistoryUpdateTrigger()
      )
      
      if (trigger) {
        trigger.trigger++
        logger.debug(`${LOG_TAG.HISTORY_MANAGER}触发历史记录更新通知: ${trigger.trigger}`)
      }
    } catch (error) {
      logger.warn(`${LOG_TAG.HISTORY_MANAGER}触发更新通知失败: ${JSON.stringify(error)}`)
    }
  }

  /**
   * 获取按日期分组的历史记录
   * 
   * @returns 按日期分组的历史记录 Map
   */
  async getGroupedHistory(): Promise<Map<string, HistoryItem[]>> {
    const historyList = await this.getHistoryList()
    const groupedMap = new Map<string, HistoryItem[]>()

    historyList.forEach(item => {
      const dateKey = item.dateStr
      if (!groupedMap.has(dateKey)) {
        groupedMap.set(dateKey, [])
      }
      groupedMap.get(dateKey)!.push(item)
    })

    logger.info(`${LOG_TAG.HISTORY_MANAGER}历史记录分组完成: ${groupedMap.size} 个日期`)
    return groupedMap
  }

  // ==================== 每日阅读统计相关方法 ====================

  /**
   * 更新每日阅读统计
   * 
   * @param articleId - 文章 ID
   * @param dateStr - 日期字符串 (YYYY-MM-DD)
   */
  async updateDailyStats(articleId: string, dateStr: string): Promise<void> {
    if (!this.appKVDb) {
      await this.init()
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库未初始化，无法更新每日统计`)
      return
    }

    try {
      const statsMap = await this.getDailyStatsMap()
      
      if (!statsMap.has(dateStr)) {
        statsMap.set(dateStr, {
          dateStr: dateStr,
          count: 0,
          articleIds: []
        })
      }

      const dayStats = statsMap.get(dateStr)!
      
      // 检查当天是否已经阅读过该文章（去重）
      if (!dayStats.articleIds.includes(articleId)) {
        dayStats.articleIds.push(articleId)
        dayStats.count = dayStats.articleIds.length
        statsMap.set(dateStr, dayStats)
        
        // 保存到数据库
        const statsArray = Array.from(statsMap.values())
        await this.appKVDb.put(KV_DB_KEYS.DAILY_READING_STATS, JSON.stringify(statsArray))
        logger.debug(`${LOG_TAG.HISTORY_MANAGER}更新每日统计: ${dateStr}, 数量: ${dayStats.count}`)
      }
    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.HISTORY_MANAGER}更新每日统计失败: ${err.message}`)
    }
  }

  /**
   * 获取每日阅读统计 Map
   * 
   * @returns 日期到统计数据的 Map
   */
  async getDailyStatsMap(): Promise<Map<string, DailyReadingStats>> {
    if (!this.appKVDb) {
      await this.init()
    }

    const statsMap = new Map<string, DailyReadingStats>()

    if (!this.appKVDb) {
      return statsMap
    }

    try {
      const data = await this.appKVDb.get(KV_DB_KEYS.DAILY_READING_STATS) as string
      const statsArray = JSON.parse(data) as DailyReadingStats[]
      statsArray.forEach(stats => {
        statsMap.set(stats.dateStr, stats)
      })
    } catch (error) {
      logger.info(`${LOG_TAG.HISTORY_MANAGER}每日统计数据为空或读取失败`)
    }

    return statsMap
  }

  /**
   * 获取指定日期范围内的每日阅读统计
   * 
   * @param days - 天数范围
   * @returns 每日统计数组
   */
  async getDailyStatsInRange(days: number): Promise<DailyReadingStats[]> {
    const statsMap = await this.getDailyStatsMap()
    const result: DailyReadingStats[] = []
    const today = new Date()

    for (let i = 0; i < days; i++) {
      const date = new Date(today)
      date.setDate(today.getDate() - i)
      const dateStr = this.formatDate(date)
      
      if (statsMap.has(dateStr)) {
        result.push(statsMap.get(dateStr)!)
      } else {
        result.push({
          dateStr: dateStr,
          count: 0,
          articleIds: []
        })
      }
    }

    return result.reverse() // 按时间正序排列
  }

  /**
   * 获取指定日期的历史记录
   * 
   * @param dateStr - 日期字符串 (YYYY-MM-DD)
   * @returns 该日期的历史记录列表
   */
  async getHistoryByDate(dateStr: string): Promise<HistoryItem[]> {
    const historyList = await this.getHistoryList()
    return historyList.filter(item => item.dateStr === dateStr)
  }

  /**
   * 清空所有每日统计数据
   */
  async clearAllDailyStats(): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    if (!this.appKVDb) {
      logger.error(`${LOG_TAG.HISTORY_MANAGER}数据库未初始化`)
      return false
    }

    try {
      await this.appKVDb.put(KV_DB_KEYS.DAILY_READING_STATS, JSON.stringify([]))
      logger.info(`${LOG_TAG.HISTORY_MANAGER}清空每日统计数据成功`)
      return true
    } catch (error) {
      let err = error as BusinessError
      logger.error(`${LOG_TAG.HISTORY_MANAGER}清空每日统计数据失败: ${err.message}`)
      return false
    }
  }

  /**
   * 清空所有数据（历史记录 + 每日统计）
   */
  async clearAllData(): Promise<boolean> {
    const historyCleared = await this.clearAllHistory()
    const statsCleared = await this.clearAllDailyStats()
    return historyCleared && statsCleared
  }
}

/**
 * 历史记录管理器单例
 */
export const historyManager = new HistoryManager()
