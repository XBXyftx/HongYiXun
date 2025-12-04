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

import { kvDatabase, KV_DB_KEYS, NewsArticle, logger, LOG_TAG, APP_STORAGE_KEYS, LikeUpdateTrigger, LikeItem } from "common"
import { AppStorageV2 } from "@kit.ArkUI"
import { distributedKVStore } from "@kit.ArkData"

/**
 * 点赞管理器
 */
class LikeManager {
  private appKVDb: distributedKVStore.SingleKVStore | null = null

  async init(): Promise<void> {
    this.appKVDb = await kvDatabase.getKVStoreById('app_kv_db')
  }

  private notifyLikeUpdate(): void {
    const trigger = AppStorageV2.connect(LikeUpdateTrigger, APP_STORAGE_KEYS.LIKE_UPDATE_TRIGGER,
      () => new LikeUpdateTrigger())
    if (trigger) {
      trigger.trigger++
      logger.info(`${LOG_TAG.LIKE_MANAGER}触发点赞更新通知: ${trigger.trigger}`)
    }
  }

  async addLike(article: NewsArticle): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      let likeList: LikeItem[] = await this.getLikeList()

      const existIndex = likeList.findIndex((item: LikeItem): boolean => item.article.id === article.id)
      if (existIndex !== -1) {
        logger.info(`${LOG_TAG.LIKE_MANAGER}文章已在点赞列表中: ${article.title}`)
        return false
      }

      const likeItem: LikeItem = {
        article: article,
        timestamp: Date.now(),
        dateStr: new Date().toLocaleDateString()
      }

      likeList.unshift(likeItem)

      if (likeList.length > 200) {
        likeList = likeList.slice(0, 200)
      }

      if (this.appKVDb) {
        await this.appKVDb.put(KV_DB_KEYS.LIKE_LIST, JSON.stringify(likeList))
        logger.info(`${LOG_TAG.LIKE_MANAGER}添加点赞成功: ${article.title}`)
        this.notifyLikeUpdate()
        return true
      }
      return false
    } catch (error) {
      logger.error(`${LOG_TAG.LIKE_MANAGER}添加点赞失败: ${JSON.stringify(error)}`)
      return false
    }
  }

  async removeLike(articleId: string): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      let likeList: LikeItem[] = await this.getLikeList()
      const newList = likeList.filter((item: LikeItem): boolean => item.article.id !== articleId)

      if (newList.length === likeList.length) {
        return false
      }
      if (this.appKVDb) {
        await this.appKVDb.put(KV_DB_KEYS.LIKE_LIST, JSON.stringify(newList))
        logger.info(`${LOG_TAG.LIKE_MANAGER}取消点赞成功: ${articleId}`)
        this.notifyLikeUpdate()
        return true
      }
      return false
    } catch (error) {
      logger.error(`${LOG_TAG.LIKE_MANAGER}取消点赞失败: ${JSON.stringify(error)}`)
      return false
    }
  }

  async isLiked(articleId: string): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      const likeList: LikeItem[] = await this.getLikeList()
      return likeList.some((item: LikeItem): boolean => item.article.id === articleId)
    } catch (error) {
      return false
    }
  }

  async getLikeList(): Promise<LikeItem[]> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      let data = await this.appKVDb!.get(KV_DB_KEYS.LIKE_LIST)
      if (data) {
        const list = JSON.parse(data as string) as LikeItem[]
        logger.info(`${LOG_TAG.LIKE_MANAGER}获取点赞列表成功: ${list.length}条`)
        return list
      }
      return []
    } catch (error) {
      return []
    }
  }

  async clearAllLikes(): Promise<boolean> {
    if (!this.appKVDb) {
      await this.init()
    }

    try {
      if (this.appKVDb) {
        await this.appKVDb.put(KV_DB_KEYS.LIKE_LIST, JSON.stringify([]))
        logger.info(`${LOG_TAG.LIKE_MANAGER}清空点赞成功`)
        this.notifyLikeUpdate()
        return true
      }
      return false
    } catch (error) {
      return false
    }
  }
}

export const likeManager = new LikeManager()
