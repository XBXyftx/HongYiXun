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

import { kvDatabase, KV_DB_KEYS, NewsArticle, logger, LOG_TAG, APP_STORAGE_KEYS, FavoriteUpdateTrigger } from "common"
import { AppStorageV2 } from "@kit.ArkUI"
import { distributedKVStore } from "@kit.ArkData"

/**
 * 收藏项接口
 */
export interface FavoriteItem {
  article: NewsArticle
  timestamp: number
  dateStr: string
}

/**
 * 收藏管理器
 */
class FavoriteManager {
  private appKVDb: distributedKVStore.SingleKVStore | null = null

  /**
   * 初始化数据库
   */
  async init(): Promise<void> {
    this.appKVDb = await kvDatabase.getKVStoreById('app_kv_db')
  }

  /**
   * 触发收藏更新通知
   */
  private notifyFavoriteUpdate(): void {
    const trigger = AppStorageV2.connect(FavoriteUpdateTrigger, APP_STORAGE_KEYS.FAVORITE_UPDATE_TRIGGER, () => new FavoriteUpdateTrigger())
    if (trigger) {
      trigger.trigger++
      logger.info(`${LOG_TAG.FAVORITE_MANAGER}触发收藏更新通知: ${trigger.trigger}`)
    }
  }

  /**
   * 添加收藏
   */
  async addFavorite(article: NewsArticle): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      let favoriteList: FavoriteItem[] = await this.getFavoriteList()

      // 检查是否已收藏
      const existIndex = favoriteList.findIndex(item => item.article.id === article.id)
      if (existIndex !== -1) {
        logger.info(`${LOG_TAG.FAVORITE_MANAGER}文章已在收藏列表中: ${article.title}`)
        return false
      }

      // 添加新收藏
      const favoriteItem: FavoriteItem = {
        article: article,
        timestamp: Date.now(),
        dateStr: new Date().toLocaleDateString()
      }

      favoriteList.unshift(favoriteItem)

      // 限制最多保存 200 条
      if (favoriteList.length > 200) {
        favoriteList = favoriteList.slice(0, 200)
      }

      await this.appKVDb.put(KV_DB_KEYS.FAVORITE_LIST, JSON.stringify(favoriteList))
      logger.info(`${LOG_TAG.FAVORITE_MANAGER}添加收藏成功: ${article.title}`)
      
      this.notifyFavoriteUpdate()
      return true
    } catch (error) {
      logger.error(`${LOG_TAG.FAVORITE_MANAGER}添加收藏失败: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 删除收藏
   */
  async removeFavorite(articleId: string): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      let favoriteList: FavoriteItem[] = await this.getFavoriteList()
      const newList = favoriteList.filter(item => item.article.id !== articleId)

      if (newList.length === favoriteList.length) {
        logger.warn(`${LOG_TAG.FAVORITE_MANAGER}未找到要删除的收藏: ${articleId}`)
        return false
      }

      await this.appKVDb.put(KV_DB_KEYS.FAVORITE_LIST, JSON.stringify(newList))
      logger.info(`${LOG_TAG.FAVORITE_MANAGER}删除收藏成功: ${articleId}`)
      
      this.notifyFavoriteUpdate()
      return true
    } catch (error) {
      logger.error(`${LOG_TAG.FAVORITE_MANAGER}删除收藏失败: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 检查是否已收藏
   */
  async isFavorite(articleId: string): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      const favoriteList: FavoriteItem[] = await this.getFavoriteList()
      return favoriteList.some(item => item.article.id === articleId)
    } catch (error) {
      logger.error(`${LOG_TAG.FAVORITE_MANAGER}检查收藏状态失败: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 获取收藏列表
   */
  async getFavoriteList(): Promise<FavoriteItem[]> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      const data: distributedKVStore.Value = await this.appKVDb!.get(KV_DB_KEYS.FAVORITE_LIST)
      if (data) {
        const list = JSON.parse(data as string) as FavoriteItem[]
        logger.info(`${LOG_TAG.FAVORITE_MANAGER}获取收藏列表成功: ${list.length}条`)
        return list
      }
      return []
    } catch (error) {
      logger.error(`${LOG_TAG.FAVORITE_MANAGER}获取收藏列表失败: ${JSON.stringify(error)}`)
      return []
    }
  }

  /**
   * 清空所有收藏
   */
  async clearAllFavorites(): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      await this.appKVDb.put(KV_DB_KEYS.FAVORITE_LIST, JSON.stringify([]))
      logger.info(`${LOG_TAG.FAVORITE_MANAGER}清空收藏成功`)
      
      this.notifyFavoriteUpdate()
      return true
    } catch (error) {
      logger.error(`${LOG_TAG.FAVORITE_MANAGER}清空收藏失败: ${JSON.stringify(error)}`)
      return false
    }
  }
}

export const favoriteManager = new FavoriteManager()
